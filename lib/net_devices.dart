import 'package:bonsoir/bonsoir.dart';
import 'package:dropfi/services/utils_service.dart';
import 'package:dropfi/services/network_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:network_tools_flutter/network_tools_flutter.dart';

class NetDevices extends StatefulWidget {
  const NetDevices(
      {super.key, required this.title, required this.shareHandlerData});
  final String title;
  final String shareHandlerData;

  @override
  State<NetDevices> createState() => _NetDevicesState();
}

class LanHost {
  String address;
  String deviceName;
  ActiveHost host;
  bool runningDropFiService = false;

  LanHost(
      {required this.address, required this.deviceName, required this.host});
}

class _NetDevicesState extends State<NetDevices> {
  bool loading = true;
  String? networkName = '';
  String? myDeviceIp;
  Map<String, LanHost> deviceMap = {};
  Logger log = Logger();
  NetInterface? prevNetInterface;

  NetworkService networkService = NetworkService();

  @override
  void initState() {
    super.initState();

    networkService.startBroadcast();
    networkService.getIPAddress().then((String myDeviceIP) {
      networkService.startDiscovery((disc) => (event) {
            // `eventStream` is not null as the discovery instance is "ready" !
            if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
              // log.i(
              //     'Service found: ${event.service?.toJson(prefix: '')['name']}');
              event.service!.resolve(disc.serviceResolver);
            } else if (event.type ==
                BonsoirDiscoveryEventType.discoveryServiceResolved) {
              dynamic serviceInfo = event.service?.toJson(prefix: '');
              if (serviceInfo['attributes']?['ip'] == myDeviceIP) {
                return;
              }
              log.i(
                  'Service resolved: ${serviceInfo['host']} [${serviceInfo['attributes']?['ip'] ?? '<no IP address>'}]');

              networkService
                  .addServiceToTransferGroup(event.service!)
                  .then((_) => setState(() {
                        log.i(
                            'Added service to transfer group @ ${serviceInfo['host']}');
                        loading = false;
                      }));
            } else if (event.type ==
                BonsoirDiscoveryEventType.discoveryServiceLost) {
              log.i('Service lost:');
              log.i(event.service?.toJson(prefix: ''));
            }
          });
    }).catchError((err) {
      log.e('Error $err');
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
        header: Text(widget.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w300)),
        footer: Text(
          'Found ${networkService.transferGroup.entries.length} device${networkService.transferGroup.entries.length > 1 ? 's' : ''} on your local network',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          ...(loading
              ? const [CupertinoActivityIndicator()]
              : networkService.transferGroup.entries.map((entry) {
                  Map<String, dynamic> value = entry.value;
                  return CupertinoListTile(
                    title: Text(
                      '${value['attributes']?['nickname'] ?? value['host']?.split('.local')?.join('') ?? 'Generic Device'} [${value['address']}]',
                    ),
                    leading: const Icon(CupertinoIcons.wifi,
                        size: 20, color: CupertinoColors.white),
                    onTap: () => !UtilsService.isDesktop
                        ? networkService.sendTo(value['attributes']?['ip'],
                            value['port'], widget.shareHandlerData)
                        : Clipboard.getData('text/plain')
                            .then((data) => networkService.sendTo(
                                value['attributes']?['ip'],
                                value['port'],
                                data?.text ?? ''))
                            .catchError((err) => log.e(err)),
                  );
                })),
        ]);
  }

  @override
  void dispose() {
    super.dispose();
    networkService.dispose();
  }
}
