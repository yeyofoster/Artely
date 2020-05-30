//import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';

class PushNotificationsFirebase {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  PreferenciasUsuario preferencias = new PreferenciasUsuario();
  final _messagesController =
      StreamController<Map<dynamic, dynamic>>.broadcast();
  Stream<Map<dynamic, dynamic>> get mensajes => _messagesController.stream;

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
        Map<dynamic, dynamic> datos = {};
        if (Platform.isAndroid) {
          datos = info['data'];
          print(datos);
          _messagesController.sink.add(datos);
        }
      },
      onResume: (info) async {
        print('============= onResume =============');
        Map<dynamic, dynamic> datos = {};
        if (Platform.isAndroid) {
          datos = info['data'];
          print(datos);
          _messagesController.sink.add(datos);
        }
      },
      onLaunch: (info) async {
        print('============= onLaunch =============');
        Map<dynamic, dynamic> datos = {};
        if (Platform.isAndroid) {
          datos = info['data'];
          print(datos);
          _messagesController.sink.add(datos);
        }
      },
    );
  }

  dispose() {
    _messagesController?.close();
  }
}
