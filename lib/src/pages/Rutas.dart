import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';

class PantallaRutas extends StatefulWidget {
  @override
  _PantallaRutasState createState() => _PantallaRutasState();
}

class _PantallaRutasState extends State<PantallaRutas> {
  Future<QuerySnapshot> _getRutas;
  PreferenciasUsuario _preferenciasUsuario;

  @override
  void initState() {
    super.initState();
    _preferenciasUsuario = new PreferenciasUsuario();
    _getRutas = refreshRutas();
  }

  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mis rutas'),
        ),
        body: RefreshIndicator(
          child: listaRutas(),
          onRefresh: () => _getRutas = refreshRutas(),
        ),
      ),
    );
  }

  Widget listaRutas() {
    return FutureBuilder(
      future: _getRutas,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          QuerySnapshot query = snapshot.data;
          if (query.documents.length > 0) {
            return ListView.builder(
              itemCount: query.documents.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: Text('Ruta ${index + 1}'),
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

  Future<QuerySnapshot> refreshRutas() async {
    setState(() {});
    return await Firestore.instance
        .collection('Artely_BD')
        .document(_preferenciasUsuario.userID)
        .collection('Rutas')
        .getDocuments();
  }
}
