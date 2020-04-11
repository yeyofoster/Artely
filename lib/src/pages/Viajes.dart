import 'package:flutter/material.dart';

class PantallaViajes extends StatefulWidget {
  @override
  _PantallaViajesState createState() => _PantallaViajesState();
}

class _PantallaViajesState extends State<PantallaViajes> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mis viajes'),
        ),
        body: Container(),
      ),
    );
  }
}
