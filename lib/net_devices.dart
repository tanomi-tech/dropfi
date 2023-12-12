import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_tools_flutter/network_tools_flutter.dart';

class NetDevices extends StatefulWidget {
  const NetDevices({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
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

class _NetDevicesState extends State<NetDevices> {
  bool loading = true;
  String? networkName = '';
  String? myDeviceIp;
  Map<String, LanHost> deviceMap = {};
  Logger log = Logger();

  @override
  void initState() {
    super.initState();
    NetInterface.localInterface().then((val) {
      final NetInterface? netInt = val;
      if (netInt == null) {
        log.e('no network interface found');
        return;
      }

      myDeviceIp = netInt.ipAddress;
      HostScannerFlutter.getAllPingableDevices(netInt.networkId)
          .listen((ActiveHost host) async {
        LanHost hostInfo = LanHost(
          address: host.address,
          deviceName: await host.deviceName,
          host: host,
        );
        if (hostInfo.address == myDeviceIp) {
          return;
        }
        setState(() {
          deviceMap[hostInfo.address] = hostInfo;
          loading = false;
        });
      }).onError((e) {
        log.e('Error $e');
      });
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

  Future<String> getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceName = 'Unnamed Device';

    switch (Platform.operatingSystem) {
      case 'android':
        {
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          deviceName = androidInfo.model;
        }
        break;
      case 'ios':
        {
          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          deviceName = iosInfo.name;
        }
        break;
      case 'linux':
        {
          LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
          deviceName = linuxInfo.name;
        }
        break;
      case 'macos':
        {
          MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
          deviceName = macInfo.computerName;
        }
        break;
      case 'windows':
        {
          WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
          deviceName = windowsInfo.computerName;
        }
        break;
    }

    return deviceName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String deviceName = await getDeviceName();
          await setupTcpSocketListener(deviceName);
        },
        tooltip: 'Listen for clipboard events',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
  }
}
