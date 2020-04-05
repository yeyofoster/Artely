//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';

class PushNotificationsFirebase {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  PreferenciasUsuario preferencias = new PreferenciasUsuario();

  initNotifications(String idDoc) {
    _firebaseMessaging.requestNotificationPermissions();

    _firebaseMessaging.getToken().then(
      (token) {
        print('========TOKEN========');
        print('Token $token documento $idDoc');
        
        Firestore.instance
            .collection('Artely_BD')
            .document(preferencias.userID)
            .updateData(
          {
            'Token': List.from({token}),
          },
        );
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
