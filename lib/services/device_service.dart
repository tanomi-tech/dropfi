import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

mixin DeviceService {
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
}
