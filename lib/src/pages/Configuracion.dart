import 'package:flutter/material.dart';

class PantallaConfiguracion extends StatefulWidget {
  PantallaConfiguracion({Key key}) : super(key: key);

  @override
  _PantallaConfiguracionState createState() => _PantallaConfiguracionState();
}

class _PantallaConfiguracionState extends State<PantallaConfiguracion> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mi configuración'),
        ),
        body: Center(
          child: Text('Configuración'),
        ),
      ),
    );
  }
}
