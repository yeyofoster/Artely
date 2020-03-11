import 'package:flutter/material.dart';
import 'package:prueba_maps/src/pages/Login.dart';
import 'package:prueba_maps/src/pages/MapaArtely.dart';
import 'package:prueba_maps/src/pages/Registro.dart';

Map<String, WidgetBuilder> getApplicationRoutes() {
  return <String, WidgetBuilder>{
    '/': (BuildContext context) => Login(),
    'registro': (BuildContext context) => PantallaRegistro(),
    'mapa': (BuildContext context) => MapaArtely(),
  };
}
