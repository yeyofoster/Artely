import 'package:flutter/material.dart';

class PantallaRutas extends StatefulWidget {
  @override
  _PantallaRutasState createState() => _PantallaRutasState();
}

class _PantallaRutasState extends State<PantallaRutas> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mis rutas'),
        ),
        body: Container(),
      ),
    );
  }
}
