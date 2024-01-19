import 'package:local_notifier/local_notifier.dart';

class NotificationService {
  LocalNotification? activeClipboardNoti;

  void notifyClipboard(String? senderDevice) {
    if (activeClipboardNoti != null) {
      return;
    }
    LocalNotification noti = LocalNotification(
        title: 'Clipboard Updated',
        body: senderDevice == 'a device'
            ? 'Clipboard updated from $senderDevice on your network'
            : 'Clipbard updated from device: $senderDevice');
    noti.onShow = () {
      activeClipboardNoti = noti;
    };
    noti.onClose = (closeReason) {
      activeClipboardNoti = null;
    };
    noti.show();
  }
}
