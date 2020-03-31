import 'package:flutter/material.dart';
import 'package:prueba_maps/src/Routes/RoutesApp.dart';
import 'package:prueba_maps/src/pages/Login.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Artely',
      routes: getApplicationRoutes(),
      initialRoute: 'mapa',
      onGenerateRoute: (RouteSettings settings) {
        print('La ruta ${settings.name} no fue encontrada.');
        return MaterialPageRoute(
          builder: (BuildContext context) => Login(),
        );
      },
    );
  }
}
