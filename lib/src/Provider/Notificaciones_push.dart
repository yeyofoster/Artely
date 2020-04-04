//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationsFirebase {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  initNotifications(String idDoc) {
    _firebaseMessaging.requestNotificationPermissions();

    _firebaseMessaging.getToken().then(
      (token) {
        print('========TOKEN========');
        print('Token $token documento $idDoc');
      },
    );
    _firebaseMessaging.configure(
      onMessage: (info) async {
        print('============= onMessage =============');
        print(info);
      },
      onResume: (info) async {
        print('============= onResume =============');
        print(info);
      },
      onLaunch: (info) async {
        print('============= onLaunch =============');
        print(info);
      },
    );
  }
}
