import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prueba_maps/src/Class/RutasGuardadas.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';

class PantallaRutas extends StatefulWidget {
  @override
  _PantallaRutasState createState() => _PantallaRutasState();
}

class _PantallaRutasState extends State<PantallaRutas> {
  Future<List<RutasGuardadas>> _getRutas;
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
          List<RutasGuardadas> rutas = snapshot.data;
          if (rutas.length > 0) {
            return ListView.builder(
              itemCount: rutas.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  elevation: 3.0,
                  child: ListTile(
                      title: Text(
                        "Ruta ${index + 1}",
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                          fontSize: 18.0,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(rutas.elementAt(index).origen.direccion),
                            Padding(
                              padding: const EdgeInsets.only(left: 80.0),
                              child: Transform.rotate(
                                angle: pi / 2,
                                child: Icon(Icons.compare_arrows),
                              ),
                            ),
                            Text(rutas.elementAt(index).destino.direccion),
                          ],
                        ),
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: rutas.elementAt(index).tipo == 1
                              ? Icon(
                                  Icons.directions_car,
                                  size: 28.0,
                                  color: Colors.cyan,
                                )
                              : Icon(
                                  Icons.directions_walk,
                                  size: 28.0,
                                  color: Colors.cyan,
                                ),
                        ),
                      ),
                      trailing: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: IconButton(
                          icon: Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () {},
                        ),
                      ),
                      contentPadding: EdgeInsets.only(
                        top: 0.0,
                        bottom: 7.5,
                        left: 10.0,
                        right: 15.0,
                      ),
                      onTap: () {}),
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
                  child: Text('Aún no tienes rutas guardadas'),
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

  Future<List<RutasGuardadas>> refreshRutas() async {
    setState(() {});
    QuerySnapshot res = await Firestore.instance
        .collection('Artely_BD')
        .document(_preferenciasUsuario.userID)
        .collection('Rutas')
        .getDocuments();
    List<DocumentSnapshot> documentos = res.documents;
    List<RutasGuardadas> rutas = [];
    for (var doc in documentos) {
      RutasGuardadas ruta = RutasGuardadas.fromJson(doc.data);
      await ruta.origen.positionToAddress();
      await ruta.destino.positionToAddress();
      rutas.add(ruta);
    }
    return rutas;
  }
}
