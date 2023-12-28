import 'dart:convert';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:share_handler/share_handler.dart';

typedef BonsoirListenerCallback = void Function(BonsoirDiscoveryEvent) Function(
    BonsoirDiscovery);

mixin class NetworkService {
  static String get mdnsServiceName => '_dropfi-service._tcp';

  Future<ShareHandlerPlatform?> setupShareHandler(cb) async {
    if (!(Platform.isIOS || Platform.isAndroid)) {
      return null;
    }
    final handler = ShareHandlerPlatform.instance;
    handler.sharedMediaStream.listen(cb);
    return handler;
  }

  Future<void> send(String content) async {
    final sock = await Socket.connect(InternetAddress.anyIPv4, 54321);
    sock.add(utf8.encode(content));
    sock.close();
  }

  BonsoirDiscovery discoveryInstance = BonsoirDiscovery(type: mdnsServiceName);

  Future<BonsoirDiscovery> startDiscovery(BonsoirListenerCallback cb) async {
    await discoveryInstance.ready;
    discoveryInstance.eventStream!.listen(cb(discoveryInstance));
    discoveryInstance.start();
    return discoveryInstance;
  }

  NetworkInfo networkInfo = NetworkInfo();

  Future<String> getIPAddress() async {
    ConnectivityResult connectivityResult =
        await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw ErrorDescription('Not connected to network');
    }

    String? ipAddress = await networkInfo.getWifiIP();
    if (ipAddress == null) {
      throw ErrorDescription('Could not parse IP address');
    }

    return ipAddress;
  }

  void disposeDiscoveryInstance() {
    discoveryInstance.stop();
  }
}
