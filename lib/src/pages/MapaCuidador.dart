import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:prueba_maps/src/Class/ArtelyColors.dart';
import 'package:prueba_maps/src/Class/ViajeProtegido.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';
import 'package:prueba_maps/src/Util/Direcciones.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaCuidador extends StatefulWidget {
  MapaCuidador({Key key}) : super(key: key);

  @override
  _MapaCuidadorState createState() => _MapaCuidadorState();
}

class _MapaCuidadorState extends State<MapaCuidador> {
  List<String> protegidosEnViaje = [];
  List<ViajeProtegido> listaDatosViaje = [];
  PreferenciasUsuario preferencias = new PreferenciasUsuario();
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController _mapController;
  CameraPosition _initialPosition;

  Future cargaPantalla;
  Set<Polyline> polylinesRutas = {};
  Set<Marker> marcadores = Set();

  @override
  void initState() {
    super.initState();
    protegidosEnViaje = preferencias.protegidosEnViaje ?? [];
    for (var prot in protegidosEnViaje) {
      print(prot);
    }

    cargaPantalla = obtenerDatosViajes();
  }

  @override
  Widget build(BuildContext context) {
    double maxWidth = MediaQuery.of(context).size.width;
    double maxHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        body: FutureBuilder(
          future: cargaPantalla,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Stack(
                children: <Widget>[
                  Positioned(
                    width: maxWidth,
                    height: maxHeight,
                    child: _creaMapa(),
                  ),
                  Positioned(
                    top: maxHeight * 0.85,
                    left: maxWidth * 0.05,
                    child: botonVerViaje(),
                  ),
                ],
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }

  GoogleMap _creaMapa() {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _initialPosition,
      // myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: false,
      trafficEnabled: true,
      zoomGesturesEnabled: true,
      markers: Set.from(marcadores), //Crea la lista de marcadores para el mapa
      polylines: polylinesRutas,
      mapToolbarEnabled:
          false, //Quita los botones de navegación cuando se presiona un marcador.
      onTap: (puntoLatLng) {},
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
        _mapController = controller;

        actualizaDatosMapa(
            listaDatosViaje.first.origen,
            listaDatosViaje.first.destino,
            listaDatosViaje.first.encodedPolyline);
      },
    );
  }

  //Método que obtiene todos los datos de los viajes en curso.
  Future<void> obtenerDatosViajes() async {
    print('Seguir viaje');
    CollectionReference bd = Firestore.instance.collection('Artely_BD');
    DocumentSnapshot docProtegido;
    try {
      for (String docRef in protegidosEnViaje) {
        docProtegido = await bd.document(docRef).get();
        String nombre =
            docProtegido.data['Nombre'] + ' ' + docProtegido.data['PApellido'];

        bool viaje = docProtegido.data['En_viaje'];

        Position orig = Position(
            latitude: docProtegido.data['Viaje']['POrigen'].latitude,
            longitude: docProtegido.data['Viaje']['POrigen'].longitude);

        Position dest = Position(
            latitude: docProtegido.data['Viaje']['PDestino'].latitude,
            longitude: docProtegido.data['Viaje']['PDestino'].longitude);

        Position actu = Position(
            latitude: docProtegido.data['Viaje']['PActual'].latitude,
            longitude: docProtegido.data['Viaje']['PActual'].longitude);

        int tipo = docProtegido.data['Viaje']['Tipo_Viaje'];
        String encoded = docProtegido.data['Viaje']['Encoded_Polyline'];

        ViajeProtegido temp = ViajeProtegido(
          origen: Direcciones(lugar: orig),
          actual: Direcciones(lugar: actu),
          destino: Direcciones(lugar: dest),
          enViaje: viaje,
          encodedPolyline: encoded,
          nombreProtegido: nombre,
          tipo: tipo,
        );

        await temp.origen.positionToAddress();
        await temp.destino.positionToAddress();
        await temp.actual.positionToAddress();
        listaDatosViaje.add(temp);
      }

      setState(() {
        _initialPosition = CameraPosition(
          target: LatLng(
            listaDatosViaje.first.origen.lugar.latitude,
            listaDatosViaje.first.origen.lugar.longitude,
          ),
          zoom: 16.0,
        );
      });
      // print(datosViaje.toString());
    } catch (error) {
      print('Error al obtener los datos del viaje. $error');
    }
  }

  //Método encargado e actualizar los datos del mapa(marcadores, polylines, etc) si se selecciona un viaje a seguir.
  void actualizaDatosMapa(
      Direcciones origen, Direcciones destino, String encodedPolyline) {
    marcadores.clear();
    polylinesRutas.clear();
    marcadores.add(
      Marker(
        markerId: MarkerId('Origen'),
        position: LatLng(origen.lugar.latitude, origen.lugar.longitude),
        infoWindow: InfoWindow(title: 'Origen', snippet: origen.direccion),
      ),
    );

    marcadores.add(
      Marker(
        markerId: MarkerId('Destino'),
        position: LatLng(destino.lugar.latitude, destino.lugar.longitude),
        infoWindow: InfoWindow(title: 'Destino', snippet: destino.direccion),
      ),
    );
    _moverRuta(0, 35.0);
  }

  //Método que muestra en el mapa los marcadores con el zoom necesario.
  Future<void> _moverRuta(int protegidoSeleccionado, double zoom) async {
    double south = min(
        listaDatosViaje.elementAt(protegidoSeleccionado).origen.lugar.latitude,
        listaDatosViaje
            .elementAt(protegidoSeleccionado)
            .destino
            .lugar
            .latitude);
    double west = min(
        listaDatosViaje.elementAt(protegidoSeleccionado).origen.lugar.longitude,
        listaDatosViaje.first.destino.lugar.longitude);
    double north = max(
        listaDatosViaje.elementAt(protegidoSeleccionado).origen.lugar.latitude,
        listaDatosViaje
            .elementAt(protegidoSeleccionado)
            .destino
            .lugar
            .latitude);
    double east = max(
        listaDatosViaje.elementAt(protegidoSeleccionado).origen.lugar.longitude,
        listaDatosViaje
            .elementAt(protegidoSeleccionado)
            .destino
            .lugar
            .longitude);

    LatLng southwest = LatLng(south, west);
    LatLng northeast = LatLng(north, east);

    LatLngBounds limites =
        LatLngBounds(southwest: southwest, northeast: northeast);

    CameraUpdate ubicacion = CameraUpdate.newLatLngBounds(limites, zoom);
    await _mapController.getVisibleRegion();
    setState(() {
      _mapController.animateCamera(ubicacion);
    });
  }

  //Método que regresa el widget dependiendo de la cantidad de protegidos en viaje.
  Widget botonVerViaje() {
    String nombreEnViaje = listaDatosViaje.first.nombreProtegido;
    int protegidoSeleccionado = 0;
    if (listaDatosViaje.length > 1) {
      return Row(
        children: <Widget>[
          Container(
            height: 40.0,
            child: FlatButton.icon(
              onPressed: () {
                double south = min(
                    listaDatosViaje
                        .elementAt(protegidoSeleccionado)
                        .origen
                        .lugar
                        .latitude,
                    listaDatosViaje
                        .elementAt(protegidoSeleccionado)
                        .destino
                        .lugar
                        .latitude);
                double west = min(
                    listaDatosViaje
                        .elementAt(protegidoSeleccionado)
                        .origen
                        .lugar
                        .longitude,
                    listaDatosViaje.first.destino.lugar.longitude);
                double north = max(
                    listaDatosViaje
                        .elementAt(protegidoSeleccionado)
                        .origen
                        .lugar
                        .latitude,
                    listaDatosViaje
                        .elementAt(protegidoSeleccionado)
                        .destino
                        .lugar
                        .latitude);
                double east = max(
                    listaDatosViaje
                        .elementAt(protegidoSeleccionado)
                        .origen
                        .lugar
                        .longitude,
                    listaDatosViaje
                        .elementAt(protegidoSeleccionado)
                        .destino
                        .lugar
                        .longitude);

                LatLng southwest = LatLng(south, west);
                LatLng northeast = LatLng(north, east);

                LatLngBounds limites =
                    LatLngBounds(southwest: southwest, northeast: northeast);
                print(limites);
                _moverRuta(protegidoSeleccionado, 35.0);
              },
              color: ArtelyColors.mediumSeaGreen.withOpacity(0.85),
              icon: Icon(
                Icons.person_pin_circle,
              ),
              label: Text(
                'Viaje de $nombreEnViaje',
                style: TextStyle(
                  fontSize: 18.0,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  bottomLeft: Radius.circular(15.0),
                ),
              ),
            ),
          ),
          Container(
            height: 40.0,
            width: 50.0,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              border: Border.all(color: Colors.black45),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(15.0),
                bottomRight: Radius.circular(15.0),
              ),
            ),
            child: PopupMenuButton(
              color: Colors.white,
              padding: EdgeInsets.all(2.0),
              icon: Icon(
                Icons.arrow_drop_up,
                color: Colors.cyan,
                size: 35.0,
              ),
              onSelected: (seleccionado) {
                protegidoSeleccionado = seleccionado;
                actualizaDatosMapa(
                    listaDatosViaje.elementAt(protegidoSeleccionado).origen,
                    listaDatosViaje.elementAt(protegidoSeleccionado).destino,
                    listaDatosViaje
                        .elementAt(protegidoSeleccionado)
                        .encodedPolyline);
                _moverRuta(protegidoSeleccionado, 35.0);
              },
              itemBuilder: (BuildContext context) {
                List<PopupMenuEntry> opciones = <PopupMenuEntry>[];
                int contador = 0;
                for (ViajeProtegido viaje in listaDatosViaje) {
                  opciones.add(
                    PopupMenuItem(
                      child: Text('Viaje de ${viaje.nombreProtegido}'),
                      value: contador,
                    ),
                  );
                  contador++;
                }
                return opciones;
              },
            ),
          )
        ],
      );
    } else {
      return Container(
        height: 40.0,
        child: FlatButton.icon(
          onPressed: () {
            _moverRuta(0, 35.0);
          },
          color: ArtelyColors.mediumSeaGreen.withOpacity(0.85),
          icon: Icon(
            Icons.person_pin_circle,
          ),
          label: Text(
            'Viaje de $nombreEnViaje',
            style: TextStyle(
              fontSize: 18.0,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
      );
    }
  }
}
