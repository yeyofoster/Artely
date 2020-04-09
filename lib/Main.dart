import 'package:flutter/material.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';
import 'package:prueba_maps/src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final PreferenciasUsuario preferencias = new PreferenciasUsuario();
  await preferencias.initPreferences();

  runApp(MyApp());
}

