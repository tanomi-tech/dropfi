import 'package:flutter/material.dart';
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

class _NetDevicesState extends State<NetDevices> {
  bool loading = true;
  String? networkName = '';
  Set<ActiveHost> devices = {};

  @override
  void initState() {
    super.initState();
    NetInterface.localInterface().then((val) {
      final NetInterface? netInt = val;
      if (netInt == null) {
        print('no network interface');
        return;
      }
      HostScannerFlutter.getAllPingableDevices(netInt.networkId).listen((host) {
        setState(() {
          devices.add(host);
        });
      }).onError((e) {
        print('Error $e');
      });
    });

    MdnsScanner.searchMdnsDevices().then((devices) async {
      for (final ActiveHost activeHost in devices) {
        final MdnsInfo? mdnsInfo = await activeHost.mdnsInfo;
        print('''
            Address: ${activeHost.address}
            Port: ${mdnsInfo!.mdnsPort}
            ServiceType: ${mdnsInfo.mdnsServiceType}
            MdnsName: ${mdnsInfo.getOnlyTheStartOfMdnsName()}
          ''');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      // return const CircularProgressIndicator();
    }
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
            ...devices.map((d) => Text(d.address)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => print('PRESSED BUTTON!'),
        tooltip: 'Increment',
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
