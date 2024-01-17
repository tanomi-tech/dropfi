import 'dart:async';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:dropfi/services/network_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:network_tools_flutter/network_tools_flutter.dart';

class NetDevices extends StatefulWidget {
  const NetDevices({super.key, required this.title, required this.shareHandlerData});
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
              log.i(
                  'Service found: ${event.service?.toJson(prefix: '')['name']}');
              event.service!.resolve(disc.serviceResolver);
            } else if (event.type ==
                BonsoirDiscoveryEventType.discoveryServiceResolved) {
              dynamic serviceInfo = event.service?.toJson(prefix: '');
              log.i('Service resolved: ${serviceInfo['host']}');

              if (serviceInfo['attributes']?['ip'] == myDeviceIP) {
                return;
              }

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

      //   List<String> subnetRangePieces = myDeviceIP.split('.');
      //   subnetRangePieces.removeLast();
      //   String subnetRange = subnetRangePieces.join('.');

      //   HostScannerFlutter.getAllPingableDevices(subnetRange)
      //       .listen((ActiveHost host) async {
      //     LanHost hostInfo = LanHost(
      //       address: host.address,
      //       deviceName: await host.deviceName,
      //       host: host,
      //     );
      //     if (hostInfo.address == myDeviceIP) {
      //       return;
      //     }

      //     setState(() {
      //       deviceMap[hostInfo.address] = hostInfo;
      //       loading = false;
      //     });
      //   }).onError((e) {
      //     log.e('Error $e');
      //   });
    }).catchError((err) {
      log.e('Error $err');
    });
  }

  Future<void> setupTcpSocketListener(String deviceName) async {
    final sock = await ServerSocket.bind(InternetAddress.anyIPv4, 54321);
    log.i('Datagram socket ready to receive on $deviceName\n'
        '${sock.address.address}:${sock.port}');
    sock.listen((client) {
      client.listen((data) async {
        String message = String.fromCharCodes(data).trim();
        log.i(
            '[${client.remoteAddress.address}:${client.remotePort}] $message');
        Clipboard.setData(ClipboardData(text: message)).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  // ignore: prefer_interpolation_to_compose_strings
                  'Clipboard update received from ' +
                      (deviceMap[client.remoteAddress.address]?.deviceName ??
                          client.remoteAddress.address))));
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
   return CupertinoListSection.insetGrouped(
      header: Text(
        widget.title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w300
        )
      ),
      footer: Text(
        'Found ${networkService.transferGroup.entries.length} device${networkService.transferGroup.entries.length > 1 ? 's' : ''} on your local network',
        style: const TextStyle(
          fontSize: 12
        ),
    ),
      children: [
        ...(
          loading 
          ? const [CupertinoActivityIndicator()]
          : networkService.transferGroup.entries.map((entry) {
            Map<String, dynamic> value = entry.value;
            return CupertinoListTile(
              title: Text(
                '${value['attributes']?['nickname'] ?? value['host']?.split('.local')?.join('') ?? 'Generic Device'} [${value['address']}]',
              ),
              leading: const Icon(CupertinoIcons.wifi, size: 20, color: CupertinoColors.white),
              onTap: () => Platform.isIOS || Platform.isAndroid == true 
                ? networkService.sendTo(
                    value['host'], value['port'],
                    widget.shareHandlerData
                  )
                : Clipboard.getData('text/plain')
                    .then((data) => networkService.sendTo(
                        value['host'], value['port'], data?.text ?? ''))
                    .catchError((err) => log.e(err)),
            );
          })),
      ]
    );
  }

  @override
  void dispose() {
    super.dispose();
    networkService.dispose();
  }
}
