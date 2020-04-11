import 'package:flutter/material.dart';
import 'package:prueba_maps/src/pages/Login.dart';
import 'package:prueba_maps/src/pages/MapaArtely.dart';
import 'package:prueba_maps/src/pages/Registro.dart';
import 'package:prueba_maps/src/pages/Cuidadores.dart';
import 'package:prueba_maps/src/pages/Protegidos.dart';
import 'package:prueba_maps/src/pages/Viajes.dart';

Map<String, WidgetBuilder> getApplicationRoutes() {
  return <String, WidgetBuilder>{
    '/': (BuildContext context) => Login(),
    'registro': (BuildContext context) => PantallaRegistro(),
    'mapa': (BuildContext context) => MapaArtely(),
    'cuidadores': (BuildContext context) => PantallaCuidadores(),
    'protegidos': (BuildContext context) => PantallaProtegidos(),
    'viajes': (BuildContext context) => PantallaViajes(),
  };
}
