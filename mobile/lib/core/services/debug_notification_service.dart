import 'package:firebase_auth/firebase_auth.dart';
import '../../features/notifications/models/app_notification.dart';
import 'notification_service.dart';
import '../../features/notifications/repositories/notification_repository.dart';

class DebugNotificationService {
  static Future<void> sendTestNotification() async {
    if (!NotificationService.useOneSignal) {
      print('DEBUG: Test Notification skipped because OneSignal is PAUSED');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('DEBUG: No user logged in');
      return;
    }

    print('DEBUG: Sending OneSignal Test to ${user.uid}');
    
    try {
      await NotificationRepository().sendNotification(
        recipientUid: user.uid,
        titleTa: 'பின்னணி அறிவிப்பு சோதனை',
        titleEn: 'Background Test Success!',
        bodyTa: 'பயன்பாடு மூடப்பட்டிருந்தாலும் இது செயல்படுகிறது.',
        bodyEn: 'This arrived while your app was minimized!',
        type: NotificationType.system,
      );
      print('DEBUG: Test command sent');
    } catch (e) {
      print('DEBUG: Failed to send test: $e');
    }
  }
}
