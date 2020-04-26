import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';

class PantallaViajes extends StatefulWidget {
  @override
  _PantallaViajesState createState() => _PantallaViajesState();
}

class _PantallaViajesState extends State<PantallaViajes> {
  Future<QuerySnapshot> _getViajes;
  PreferenciasUsuario _preferenciasUsuario;
  List viajes = [];

  @override
  void initState() {
    super.initState();
    _preferenciasUsuario = new PreferenciasUsuario();
    _getViajes = refreshViajes();
  }

  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mis rutas'),
        ),
        body: RefreshIndicator(
          child: listaViajes(),
          onRefresh: () => _getViajes = refreshViajes(),
        ),
      ),
    );
  }

  Widget listaViajes() {
    return FutureBuilder(
      future: _getViajes,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          QuerySnapshot query = snapshot.data;
          if (query.documents.length > 0) {
            return ListView.builder(
              itemCount: query.documents.length,
              itemBuilder: (BuildContext context, int index) {
                query.documents.forEach(
                  (doc) {
                    // viajes.add(doc.data['POrigen']);
                  },
                );
                return Card(
                  child: Text('Viaje ${index + 1}'),
                );
              },
            );
          } else {
            return ListView(
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.42,
                ),
                Center(
                  child: Text('Aún no hay nada'),
                ),
              ],
            );
          }
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Future<QuerySnapshot> refreshViajes() async {
    setState(() {});
    return await Firestore.instance
        .collection('Artely_BD')
        .document(_preferenciasUsuario.userID)
        .collection('Viajes')
        .getDocuments();
  }
}
