import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:prueba_maps/src/Class/ArtelyColors.dart';
import 'package:prueba_maps/src/Class/Polylines.dart';
import 'package:prueba_maps/src/Class/ViajeProtegido.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';
import 'package:prueba_maps/src/Util/Direcciones.dart';

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
  Timer tracking;
  Set<Polyline> polylinesRutas = {};
  Set<Marker> marcadores = Set();
  String nombreEnViaje = '';
  int protegidoSeleccionado = 0;

  @override
  void initState() {
    super.initState();
    protegidosEnViaje = preferencias.protegidosEnViaje ?? [];
    cargaPantalla = obtenerDatosViajes();
  }

  @override
  void dispose() {
    print('Deteniendo todo');
    tracking?.cancel();
    super.dispose();
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
      trafficEnabled: false,
      zoomGesturesEnabled: true,
      markers: Set.from(marcadores), //Crea la lista de marcadores para el mapa
      polylines: polylinesRutas,
      mapToolbarEnabled:
          false, //Quita los botones de navegación cuando se presiona un marcador.
      onTap: (puntoLatLng) {},
      onMapCreated: (GoogleMapController controller) async {
        _controller.complete(controller);
        _mapController = controller;

        await actualizaDatosMapa(
            listaDatosViaje.first.origen,
            listaDatosViaje.first.actual,
            listaDatosViaje.first.destino,
            listaDatosViaje.first.encodedPolyline,
            listaDatosViaje.first.tipo);
        //Mostramos toda la ruta en el mapa.
        _moverRuta(0, 36.0);

        tracking = Timer.periodic(
          Duration(seconds: 2),
          (Timer t) => sigueViaje(protegidosEnViaje.first, 0),
        );
      },
    );
  }

  //Método que obtiene todos los datos de los viajes en curso.
  Future<void> obtenerDatosViajes() async {
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
            listaDatosViaje.first.actual.lugar.latitude,
            listaDatosViaje.first.actual.lugar.longitude,
          ),
          zoom: 16.0,
        );

        if (_initialPosition == null) {
          _initialPosition = CameraPosition(
            target: LatLng(19.4284706, -99.1276627),
            zoom: 16.0,
          );
        }
      });
      // print(datosViaje.toString());
    } catch (error) {
      print('Error al obtener los datos del viaje. $error');
    }
  }

  //Método encargado e actualizar los datos del mapa(marcadores, polylines, etc) si se selecciona un viaje a seguir.
  Future<void> actualizaDatosMapa(Direcciones origen, Direcciones actual,
      Direcciones destino, String encodedPolyline, int tipoViaje) async {
    //Limpíamos las listas de marcadores y de polylineas.
    marcadores.clear();
    polylinesRutas.clear();

    double tamanoIcon = MediaQuery.of(context).size.width * 0.35;

    Uint8List iconBytes;
    if (tipoViaje == 1) {
      iconBytes =
          await getBytesFromAsset('assets/img/car_pin.png', tamanoIcon.round());
    } else {
      iconBytes = await getBytesFromAsset(
          'assets/img/walk_pin.png', tamanoIcon.round());
    }

    //Obtenemos los puntos de la polylinea.
    List<String> encodedLegs = encodedPolyline.split('  ');
    List<LatLng> puntosRuta = [];
    for (String encodedLeg in encodedLegs) {
      List<LatLng> temp = decodeEncodedPolyline(encodedLeg);
      puntosRuta.addAll(temp);
    }

    //Agregamos los puntos a la polylinea.
    PolylineId idPolyline = PolylineId('Viaje');
    Polyline polylineViaje = Polyline(
      polylineId: idPolyline,
      color: Colors.cyan,
      width: 5,
      points: puntosRuta,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      onTap: () {},
    );
    polylinesRutas.add(polylineViaje);

    //Agregamos los marcadores de origen, destino y actual.
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

    marcadores.add(
      Marker(
        markerId: MarkerId('Actual'),
        position: LatLng(actual.lugar.latitude, actual.lugar.longitude),
        infoWindow:
            InfoWindow(title: 'Posición actual', snippet: actual.direccion),
        icon: BitmapDescriptor.fromBytes(iconBytes),
      ),
    );
  }

  //Método que muestra en el mapa los marcadores con el zoom necesario.
  Future<void> _moverRuta(int protegidoSeleccionado, double zoom) async {
    List<LatLng> listaPuntos = polylinesRutas.first.points;
    double south = 90.0;
    double west = 180.0;
    double north = -90.0;
    double east = -180.0;

    for (int i = 1; i < listaPuntos.length; i++) {
      double tempSouth = min(listaPuntos.elementAt(i - 1).latitude,
          listaPuntos.elementAt(i).latitude);

      double tempWest = min(listaPuntos.elementAt(i - 1).longitude,
          listaPuntos.elementAt(i).longitude);

      double tempNorth = max(listaPuntos.elementAt(i - 1).latitude,
          listaPuntos.elementAt(i).latitude);

      double tempEast = max(listaPuntos.elementAt(i - 1).longitude,
          listaPuntos.elementAt(i).longitude);

      if (south > tempSouth) {
        south = tempSouth;
      }
      if (west > tempWest) {
        west = tempWest;
      }
      if (north < tempNorth) {
        north = tempNorth;
      }
      if (east < tempEast) {
        east = tempEast;
      }
    }

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

  //Obtiene los bytes y el tamaño de la imagen a mostrar como pin.
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
  }

  //Método que regresa el widget dependiendo de la cantidad de protegidos en viaje.
  Widget botonVerViaje() {
    nombreEnViaje =
        listaDatosViaje.elementAt(protegidoSeleccionado).nombreProtegido;
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
                _moverRuta(protegidoSeleccionado, 36.0);
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
              onSelected: (seleccionado) async {
                protegidoSeleccionado = seleccionado;
                nombreEnViaje = listaDatosViaje
                    .elementAt(protegidoSeleccionado)
                    .nombreProtegido;

                await actualizaDatosMapa(
                    listaDatosViaje.elementAt(protegidoSeleccionado).origen,
                    listaDatosViaje.elementAt(protegidoSeleccionado).actual,
                    listaDatosViaje.elementAt(protegidoSeleccionado).destino,
                    listaDatosViaje
                        .elementAt(protegidoSeleccionado)
                        .encodedPolyline,
                    listaDatosViaje.elementAt(protegidoSeleccionado).tipo);

                await sigueViaje(
                    protegidosEnViaje.elementAt(protegidoSeleccionado),
                    protegidoSeleccionado);

                _moverRuta(protegidoSeleccionado, 36.0);

                tracking?.cancel();
                tracking = Timer.periodic(
                  Duration(seconds: 2),
                  (Timer t) => sigueViaje(
                      protegidosEnViaje.elementAt(protegidoSeleccionado),
                      protegidoSeleccionado),
                );
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
            _moverRuta(0, 36.0);
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

  Future<void> sigueViaje(String idDoc, int protegidoSeleccionado) async {
    // print('Haciendo tracking del documento $idDoc');
    DocumentSnapshot docProtegido =
        await Firestore.instance.collection('Artely_BD').document(idDoc).get();
    setState(() {
      // print('Actualizando punto actual');
      // print(
      //     'Anterior: ${listaDatosViaje.elementAt(protegidoSeleccionado).actual.toString()}\n');
      listaDatosViaje.elementAt(protegidoSeleccionado).actual.lugar = Position(
          latitude: docProtegido.data['Viaje']['PActual'].latitude,
          longitude: docProtegido.data['Viaje']['PActual'].longitude);
      listaDatosViaje
          .elementAt(protegidoSeleccionado)
          .actual
          .positionToAddress();
      // print(
      //     'Nuevo: ${listaDatosViaje.elementAt(protegidoSeleccionado).actual.toString()}\n\n');
    });

    //Seleccionamos el pin a agregar
    double tamanoIcon = MediaQuery.of(context).size.width * 0.35;

    Uint8List iconBytes;
    if (listaDatosViaje.elementAt(protegidoSeleccionado).tipo == 1) {
      iconBytes =
          await getBytesFromAsset('assets/img/car_pin.png', tamanoIcon.round());
    } else {
      iconBytes = await getBytesFromAsset(
          'assets/img/walk_pin.png', tamanoIcon.round());
    }

    //Eliminamos el viejo marcador
    marcadores.removeWhere(
      (marker) => marker.markerId == MarkerId('Actual'),
    );

    //Agregamos el nuevo marcador
    marcadores.add(
      Marker(
        markerId: MarkerId('Actual'),
        position: LatLng(
            listaDatosViaje
                .elementAt(protegidoSeleccionado)
                .actual
                .lugar
                .latitude,
            listaDatosViaje
                .elementAt(protegidoSeleccionado)
                .actual
                .lugar
                .longitude),
        infoWindow: InfoWindow(
            title: 'Posición actual',
            snippet: listaDatosViaje
                .elementAt(protegidoSeleccionado)
                .actual
                .direccion),
        icon: BitmapDescriptor.fromBytes(iconBytes),
      ),
    );
  }
}
