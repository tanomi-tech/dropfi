import 'dart:convert';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropfi/services/log_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:share_handler/share_handler.dart';

typedef BonsoirListenerCallback = void Function(BonsoirDiscoveryEvent) Function(
    BonsoirDiscovery);

class NetworkService with LogService {
  static String get mdnsServiceName => '_dropfi._tcp';

  Future<ShareHandlerPlatform?> setupShareHandler(cb) async {
    if (!(Platform.isIOS || Platform.isAndroid)) {
      return null;
    }
    final handler = ShareHandlerPlatform.instance;
    handler.sharedMediaStream.listen(cb);
    return handler;
  }

  Future<void> sendTo(String target, int port, String content) async {
    final sock = await Socket.connect(target, port);
    sock.add(utf8.encode('$content\n'));
    sock.close();
  }

  BonsoirDiscovery discoveryInstance = BonsoirDiscovery(type: mdnsServiceName);

  Future<BonsoirDiscovery> startDiscovery(BonsoirListenerCallback cb) async {
    await discoveryInstance.ready;
    discoveryInstance.eventStream!.listen(cb(discoveryInstance));
    discoveryInstance.start();
    return discoveryInstance;
  }

  BonsoirBroadcast? broadcastInstance;

  Future<BonsoirBroadcast> startBroadcast() async {
    if (broadcastInstance != null) {
      await broadcastInstance!.stop();
    }
    String ip = await getIPAddress();
    String nickname = "My Device";
    broadcastInstance = BonsoirBroadcast(
      service: BonsoirService(
          name: 'DropFi Service',
          type: mdnsServiceName,
          port: 54321,
          attributes: {
            "ip": ip,
            "nickname": nickname,
          }),
    );
    await broadcastInstance?.ready;
    await broadcastInstance?.start();
    return broadcastInstance!;
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

  Map<String, Map<String, dynamic>> transferGroup = {};
  Future<void> addServiceToTransferGroup(BonsoirService bonsoirService) async {
    dynamic target = bonsoirService.toJson(prefix: '');
    target['address'] = "${target['host']}:${target['port']}";
    if (target['host'] == null || target['port'] is! int) {
      log.e(
          'Could not add target to transfer group. No hostname and/or port provided.');
      return;
    }
    transferGroup[target['host']] = target;
  }

  void dispose() {
    if (broadcastInstance != null) {
      broadcastInstance!.stop();
    }
    discoveryInstance.stop();
  }
}
