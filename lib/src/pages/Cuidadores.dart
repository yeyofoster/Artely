import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';

class PantallaCuidadores extends StatefulWidget {
  @override
  _PantallaCuidadoresState createState() => _PantallaCuidadoresState();
}

class _PantallaCuidadoresState extends State<PantallaCuidadores> {
  // CollectionReference db;
  // List<String> _cuidadoresReference;
  // List _cuidadoresData;
  PreferenciasUsuario _preferenciasUsuario;

  @override
  void initState() {
    super.initState();
    _preferenciasUsuario = new PreferenciasUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mis cuidadores'),
        ),
        body: FutureBuilder(
          future: obtenerCuidadores(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Center(
                child: Text('Hola Yeyo'),
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
        // ListView.builder(
        //     itemBuilder: (BuildContext context, int elemento) {

        //     }),
      ),
    );
  }

  Future obtenerCuidadores() {
    List<String> _referenciasCuidadores;

    Future<QuerySnapshot> consulta = Firestore.instance
        .collection('Artely_BD')
        .document(_preferenciasUsuario.userID)
        .collection('Cuidadores')
        .getDocuments()
        .then((referencias) {
      referencias.documents.forEach((documento) {
        _referenciasCuidadores.add(documento.data['Referencia']);
      });
      //print(_referenciasCuidadores.first);
      return null;
    });
    return consulta;
  }
}
