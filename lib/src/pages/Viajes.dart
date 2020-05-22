import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prueba_maps/src/Class/HistorialViaje.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';

class PantallaViajes extends StatefulWidget {
  @override
  _PantallaViajesState createState() => _PantallaViajesState();
}

class _PantallaViajesState extends State<PantallaViajes> {
  Future<List<HistorialViaje>> _getViajes;
  PreferenciasUsuario _preferenciasUsuario;

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
          title: Text('Mis viajes'),
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
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          List<HistorialViaje> viajes = snapshot.data;
          if (viajes.length > 0) {
            return ListView.builder(
              itemCount: viajes.length,
              itemBuilder: (BuildContext context, int index) {
                String fechaInicio = viajes.elementAt(index).inicio;
                String horaInicio = fechaInicio.substring(
                    fechaInicio.length - 5, fechaInicio.length);
                fechaInicio = fechaInicio.substring(0, fechaInicio.length - 5);

                String fechaLlegada = viajes.elementAt(index).llegada;
                String horaLlegada = fechaLlegada.substring(
                    fechaLlegada.length - 5, fechaLlegada.length);
                fechaLlegada =
                    fechaLlegada.substring(0, fechaLlegada.length - 5);

                return Card(
                  elevation: 3.0,
                  child: ListTile(
                      title: Text(
                        fechaInicio,
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
                            Text(
                                '${viajes.elementAt(index).origen.direccion} a las $horaInicio'),
                            Padding(
                              padding: const EdgeInsets.only(left: 100.0),
                              child: Icon(Icons.arrow_downward),
                            ),
                            Text(
                                '${viajes.elementAt(index).destino.direccion} a las $horaLlegada'),
                          ],
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: viajes.elementAt(index).tipo == 1
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
                  child: Text('Aún no has realizado ningún viaje'),
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

  Future<List<HistorialViaje>> refreshViajes() async {
    setState(() {});
    print('Ejecutando update');
    QuerySnapshot res = await Firestore.instance
        .collection('Artely_BD')
        .document(_preferenciasUsuario.userID)
        .collection('Viajes')
        .getDocuments();
    List<DocumentSnapshot> documentos = res.documents;
    List<HistorialViaje> listaViajes = [];
    for (var doc in documentos) {
      HistorialViaje viaje = HistorialViaje.fromJson(doc.data);
      await viaje.origen.positionToAddress();
      await viaje.destino.positionToAddress();
      listaViajes.add(viaje);
      // print(viaje.toString());
    }
    return listaViajes;
  }
}
