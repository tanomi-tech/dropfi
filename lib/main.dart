import 'dart:convert';
import 'dart:io';
import 'package:dropfi/services/log_service.dart';
import 'package:dropfi/services/network_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:network_tools_flutter/network_tools_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_handler/share_handler.dart';

import 'net_devices.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // It's necessary to pass correct path to be able to use this library.
  final appDocDirectory = await getApplicationDocumentsDirectory();
  await configureNetworkTools(appDocDirectory.path, enableDebugging: false);
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
          brightness: Brightness.dark),
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

class _MyHomePageState extends State<MyHomePage> with LogService {
  SharedMedia? media;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  send(String content) async {
    final sock = await Socket.connect(InternetAddress.anyIPv4, 54321);
    sock.add(utf8.encode(content));
    sock.close();
  }

  final networkService = NetworkService();

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    await networkService.setupShareHandler((SharedMedia media) {
      if (!mounted) return;
      setState(() {
        this.media = media;
      });
    });

    if (Platform.isIOS || Platform.isAndroid) {
      final handler = ShareHandlerPlatform.instance;
      media = await handler.getInitialSharedMedia();

      if (!mounted) return;
    }

    setState(() {
      // _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    SizedBox spacer = const SizedBox(height: 20);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color.fromARGB(255, 90, 11, 129),
        trailing: const Icon(CupertinoIcons.info_circle_fill, size: 24, color: CupertinoColors.white),
        leading: Text(
          widget.title,
          style: GoogleFonts.montserratAlternates(
            textStyle: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            fontWeight: FontWeight.w800,
            fontSize: 26
            )
          ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                spacer,
                spacer,
                const Text(
                  'Share with devices \non your local network',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: CupertinoColors.white
                  ),
                ),
                spacer,
                const Text(
                  'Choose a device to share selected content',
                  style: TextStyle(color: CupertinoColors.systemGrey2)
                ),
                spacer,
                const Divider(color: CupertinoColors.systemGrey2),
                spacer,
                const Text(
                  'Content to Share:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.only(top: 8.0),
                  decoration: const BoxDecoration(
                    color: CupertinoColors.darkBackgroundGray,
                    borderRadius: BorderRadius.all(Radius.circular(10))
                  ),
                  child: media?.content == null 
                  ? const Text(
                      'Shared content will be populated here', 
                      textAlign: TextAlign.center, 
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey2
                      )
                    )
                  : RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        color: CupertinoColors.white
                      ),
                      children: [
                        WidgetSpan(
                          child: RegExp('^(https:|http:|www\.)\S*').hasMatch(media?.content as String)
                          ? const Icon(CupertinoIcons.link, size: 18, color: CupertinoColors.white) 
                          : const Icon(CupertinoIcons.text_alignleft, size: 18, color: CupertinoColors.white) 
                        ),
                        TextSpan(
                          text: '  ${media?.content}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ],
                    ),
                  )
                )
              ]
            ),
          ),
          NetDevices(title: 'Nearby Devices:', shareHandlerData: media?.content != null ? '${media?.content}\n' : ''),
        ]
      )
    );
  }
}
