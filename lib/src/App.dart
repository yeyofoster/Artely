import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:prueba_maps/src/Routes/RoutesApp.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';
import 'package:prueba_maps/src/pages/Login.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String ruta = '/';
    PreferenciasUsuario preferencias = new PreferenciasUsuario();
    if (preferencias.userID != '') {
      ruta = 'mapa';
    }

    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('es', 'ES'), 
      ],
      debugShowCheckedModeBanner: false,
      title: 'Artely',
      routes: getApplicationRoutes(),
      initialRoute: ruta,
      onGenerateRoute: (RouteSettings settings) {
        print('La ruta ${settings.name} no fue encontrada.');
        return MaterialPageRoute(
          builder: (BuildContext context) => Login(),
        );
      },
    );
  }
}
