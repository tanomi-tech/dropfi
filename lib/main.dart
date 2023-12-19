// import 'package:path_provider/path_provider.dart';
// import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:share_handler/share_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:network_tools_flutter/network_tools_flutter.dart';
// import 'net_devices.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // It's necessary to pass correct path to be able to use this library.
  // final appDocDirectory = await getApplicationDocumentsDirectory();
  // await configureNetworkTools(appDocDirectory.path, enableDebugging: true);
  runApp(const DropFi());
}

class DropFi extends StatelessWidget {
  const DropFi({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'DropFi',
      theme: CupertinoThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        brightness: Brightness.dark
      ),
      // home: const NetDevices(title: 'Network Devices'),
      home: MyHomePage(title: 'DropFi'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  SharedMedia? media;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  send(String content) async {
    final sock = await Socket.connect(InternetAddress.anyIPv4, 54321);
    sock.add(utf8.encode(content));
    sock.close();
  }

   // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final handler = ShareHandlerPlatform.instance;
    media = await handler.getInitialSharedMedia();

    handler.sharedMediaStream.listen((SharedMedia media) {
      if (!mounted) return;
      setState(() {
        this.media = media;
      });
    });
    if (!mounted) return;

    setState(() {
      // _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    SizedBox spacer = const SizedBox(height: 20);
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Color.fromARGB(255, 90, 11, 129),
        middle: Text(widget.title, style: GoogleFonts.montserratAlternates(
          textStyle: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          fontWeight: FontWeight.w800,
          fontSize: 23
        )),
      ),
      child: Center(
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
              'Instructions',
              style: TextStyle(decoration: TextDecoration.underline)
            ),
            spacer,
            const Text('Open Share > Select DropFi'),
            spacer,
            Text(media?.content != null ? 'Copied: ${media?.content}' : ''),
            CupertinoButton(child: const Text('Send to device'), onPressed: () => send(media?.content != null ? '${media?.content}\n' : '\n'))
          ],
        ),
      ),
    );
  }
}
