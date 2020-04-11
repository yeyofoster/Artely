import 'package:flutter/material.dart';

class PantallaProtegidos extends StatefulWidget {
  @override
  _PantallaProtegidosState createState() => _PantallaProtegidosState();
}

class _PantallaProtegidosState extends State<PantallaProtegidos> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mis protegidos'),
        ),
        body: Container(),
      ),
    );
  }
}
