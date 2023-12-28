import 'dart:async';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:dropfi/services/device_service.dart';
import 'package:dropfi/services/network_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:network_tools_flutter/network_tools_flutter.dart';

class NetDevices extends StatefulWidget {
  const NetDevices({super.key, required this.title});
  final String title;

  @override
  State<NetDevices> createState() => _NetDevicesState();
}

class LanHost {
  String address;
  String deviceName;
  ActiveHost host;

  LanHost(
      {required this.address, required this.deviceName, required this.host});
}

class _NetDevicesState extends State<NetDevices> with DeviceService {
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
    // NetInterface.localInterface()
    networkService
        .getIPAddress()
        .then((String myDeviceIP) {
      // final NetInterface? netInt = val;
      // if (netInt == null || netInt == prevNetInterface) {
      //   log.e('no new network interface found');
      //   return;
      // }

      // prevNetInterface = netInt;

      // myDeviceIp = netInt.ipAddress;

      List<String> subnetRangePieces = myDeviceIP.split('.');
      subnetRangePieces.removeLast();
      String subnetRange = subnetRangePieces.join('.');

      HostScannerFlutter.getAllPingableDevices(subnetRange)
          .listen((ActiveHost host) async {
        LanHost hostInfo = LanHost(
          address: host.address,
          deviceName: await host.deviceName,
          host: host,
        );
        if (hostInfo.address == myDeviceIP) {
          return;
        }

        setState(() {
          deviceMap[hostInfo.address] = hostInfo;
          loading = false;
        });
      }).onError((e) {
        log.e('Error $e');
      });
    }).catchError((err) {
      log.e('Error $err');
    });

    networkService.startDiscovery((disc) => (event) {
          // `eventStream` is not null as the discovery instance is "ready" !
          if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
            log.i('Service found : ${event.service?.toJson()}');
            event.service!.resolve(disc.serviceResolver);
          } else if (event.type ==
              BonsoirDiscoveryEventType.discoveryServiceResolved) {
            log.i('Service resolved : ${event.service?.toJson()}');
          } else if (event.type ==
              BonsoirDiscoveryEventType.discoveryServiceLost) {
            log.i('Service lost : ${event.service?.toJson()}');
          }
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color.fromARGB(255, 90, 11, 129),
        middle: Text(widget.title,
            style: GoogleFonts.montserratAlternates(
                textStyle:
                    CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                fontWeight: FontWeight.w800,
                fontSize: 23)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Devices on current network:',
            ),
            ...(loading
                ? [const CircularProgressIndicator()]
                : deviceMap.entries.map((entry) {
                    LanHost device = entry.value;
                    return Text('${device.deviceName} (${device.address})');
                  }))
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     String deviceName = await getDeviceName();
      //     await setupTcpSocketListener(deviceName);
      //   },
      //   tooltip: 'Listen for clipboard events',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  void dispose() {
    super.dispose();
    networkService.disposeDiscoveryInstance();
  }
}
