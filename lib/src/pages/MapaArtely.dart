import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

//Librerias Propias
import 'package:prueba_maps/src/Class/BusquedaMaps.dart';
import 'package:prueba_maps/src/Class/BusquedaRoutes.dart';
import 'package:prueba_maps/src/Class/DecodePolyline.dart';
import 'package:prueba_maps/src/Class/PlacesMaps.dart';
import 'package:prueba_maps/src/Class/Results.dart';
import 'package:prueba_maps/src/Class/Routes.dart' as Rutas;
import 'package:prueba_maps/src/Class/RoutesMaps.dart';
import 'package:prueba_maps/src/Provider/Notificaciones_push.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';
import 'package:prueba_maps/src/Util/VentanaEmergente.dart';

class MapaArtely extends StatefulWidget {
  @override
  _MapaArtelyState createState() => _MapaArtelyState();
}

class _MapaArtelyState extends State<MapaArtely> {
  //Variables de Google Maps
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController _mapController;
  CameraPosition _mexicoPosition = CameraPosition(
    target: LatLng(23.6345005, -102.5527878),
    zoom: 5.0,
  );

  //Widgets y variables globales
  Set<MaterialColor> coloresRuta = {Colors.blue, Colors.red, Colors.green};
  PermissionHandler _permissionHandler = PermissionHandler();
  Set<Marker> marcadores = Set();
  Set<Results> lugares = Set();
  Set<Rutas.Routes> rutas = Set();
  Set<Polyline> polylinesRutas = {};
  Widget botonesWidget;
  Widget barraSuperior;
  StreamSubscription<Position> positionStream;
  String encodedRuta = '';
  int tipo;
  bool enViaje = false;
  PreferenciasUsuario preferencias = new PreferenciasUsuario();
  

  //Terminan variables

  @override
  void initState() {
    super.initState();
    _inicializaWidgets();
    _verificarPermisos();

    final notificaciones = PushNotificationsFirebase();
    notificaciones.initNotifications(preferencias.userID);
  }

  @override
  Widget build(BuildContext context) {
    //Variables de ancho y largo de la pantalla del dispositivo
    final double _maxwidth = MediaQuery.of(context).size.width;
    final double _maxheight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Positioned(
              width: _maxwidth,
              height: _maxheight,
              child: _creaMapa(),
            ),
            Positioned(
              width: _maxwidth,
              height: _maxheight * 0.10,
              top: _maxheight * 0.84,
              right: _maxwidth * 0.03,
              //child: Container(color: Colors.cyan,),
              child: _crearBotones(),
            ),
            // Positioned(
            //   width: _maxwidth * 0.3,
            //   height: _maxheight * 0.3,
            //   bottom: _maxheight * 0.5,
            //   left: _maxwidth * 0.5,
            //   child: Container(
            //     color: btnColorVamos,
            //     child: Center(
            //       child: Icon(
            //         Icons.center_focus_strong,
            //         color: Colors.blue,
            //       ),
            //     ),
            //   ),
            // ),
            Positioned(
              width: _maxwidth * 0.93,
              top: _maxheight * 0.05,
              left: _maxwidth * 0.03,
              child: Column(
                children: <Widget>[
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 400),
                    child: barraSuperior,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(5.0, 0.0),
                          end: Offset(0.0, 0.0),
                        ).animate(animation),
                        child: child,
                      );
                    },
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  _listaResult(),
                ],
              ),
            ),
            Positioned(
              top: _maxheight * 0.85,
              left: _maxwidth * 0.07,
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: botonesWidget,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Método que crea los botones flotantes y el textfield.
  Container _crearBotones() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          SizedBox(
            width: 10.0,
          ),
          FloatingActionButton(
            heroTag: "btn1",
            child: Icon(Icons.stop),
            backgroundColor: Colors.red[300],
            onPressed: _detener,
          ),
          SizedBox(
            width: 10.0,
          ),
          FloatingActionButton(
            heroTag: 'btn2',
            child: Icon(Icons.my_location),
            backgroundColor: Colors.black45,
            onPressed: _ubicarme,
          ),
        ],
      ),
    );
  }

  //Método que solicita permisos de ubicación.
  _solicitarPermisos() async {
    final resultado = await _permissionHandler
        .requestPermissions([PermissionGroup.locationWhenInUse]);
    if (resultado.containsKey(PermissionGroup.locationWhenInUse)) {
      if (resultado[PermissionGroup.locationWhenInUse] ==
          PermissionStatus.denied) {
        VentanaEmergente alerta = VentanaEmergente(
          titulo: 'Permisos denegados',
          colorTitulo: Colors.white,
          backgroundColorTitulo: Colors.red,
          height: 400,
          contenido: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Text(
                'Se necesitan los permisos de ubicación.',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              Icon(
                Icons.error,
                color: Colors.red,
                size: 75.0,
              ),
            ],
          ),
        );
        alerta.mostrarVentana(context);
        await Future.delayed(Duration(seconds: 3));
        alerta.cerrarVentana(context);
        _solicitarPermisos();
      }
    }
  }

  //Metodo para verificar permisos de geolocalización
  void _verificarPermisos() async {
    final status = await _permissionHandler
        .checkPermissionStatus(PermissionGroup.locationWhenInUse);
    if (status == PermissionStatus.denied) {
      _solicitarPermisos();
    }
  }

  //Método que permite ubicar el dispositivo y agrega un marcador en la posición actual.
  void _ubicarmeMarcador() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    _moverConZoom(position, 16.0);

    setState(() {
      String pos = 'Lat: ' +
          position.latitude.toString() +
          'Lng: ' +
          position.longitude.toString();
      print(pos);

      marcadores.add(
        Marker(
          markerId: MarkerId('Mi ubicacion'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: InfoWindow(title: 'Mi ubicacion', snippet: pos),
        ),
      );
    });
  }

  //Método que permite ubicar el dispositivo y agrega un marcador en la posición actual.
  void _ubicarme() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    _moverConZoom(position, 16.0);
  }

  //Método que detiene la detección de la ubicación del dispositivo.
  void _detener() {
    setState(() {
      marcadores.clear();
      polylinesRutas.clear();
      botonesWidget = SizedBox();
      barraSuperior = SizedBox();
      encodedRuta = '';
      lugares.clear();
      tipo = 0;
      if (enViaje) {
        enViaje = false;

        Firestore.instance
            .collection('Artely_BD')
            .document(preferencias.userID)
            .updateData(
          {
            'En_viaje': enViaje,
          },
        );
      }
      if (positionStream != null) {
        positionStream.pause();
        positionStream.cancel();
      }
    });
  }

  //Método encargado de crear el mapa. Lo retorna como widget.
  GoogleMap _creaMapa() {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _mexicoPosition,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomGesturesEnabled: true,
      markers: Set.from(marcadores), //Crea la lista de marcadores para el mapa
      polylines: polylinesRutas,
      mapToolbarEnabled:
          false, //Quita los botones de naavegación cuando se presiona un marcador.
      onMapCreated: (GoogleMapController controller) async {
        try {
          if (await _permissionHandler
                  .checkPermissionStatus(PermissionGroup.locationWhenInUse) ==
              PermissionStatus.granted) {
            Position p = await Geolocator()
                .getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
            _controller.complete(controller);
            _mapController = controller;
            _mapController.moveCamera(CameraUpdate.newLatLngZoom(
              LatLng(p.latitude, p.longitude),
              15.0,
            ));
          }
        } catch (e) {
          print('Error al ubicar el dispositivo. $e');
        }
      },
    );
  }

  //Método que mueve la camara del mapa con un zoom dado.
  void _moverConZoom(Position position, double zoom) {
    setState(() {
      final ubicacion = CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude), zoom);
      _mapController.animateCamera(ubicacion);
    });
  }

  //Método que se encarga de hacer la animación cuando el usuario está en viaje.
  void _moverRuta(LatLngBounds bounds, double zoom) {
    setState(() {
      final ubicacion = CameraUpdate.newLatLngBounds(bounds, zoom);
      _mapController.animateCamera(ubicacion);
    });
  }

  //Método que regresa el widget de la barra de busqueda
  void cargarBarraBusqueda() {
    _ubicarmeMarcador();
    setState(() {
      barraSuperior = WillPopScope(
        onWillPop: () {
          setState(() {
            cargaBarraSuperior();
            rutas.clear();
            polylinesRutas.clear();
            marcadores.clear();
            botonesWidget = SizedBox();
            _ubicarme();
          });
          return null;
        },
        child: TextField(
          autocorrect: true,
          autofocus: true,
          onSubmitted: _buscarLugar,
          onChanged: _prediccionLugar,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            hintText: 'Buscar',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 15.0,
              vertical: 18.0,
            ),
            fillColor: Colors.grey[100],
            filled: true,
            suffixIcon: Icon(
              Icons.search,
              color: Colors.cyan,
              size: 27.0,
            ),
          ),
        ),
      );
    });
  }

  //Método que busca el lugar ingresado en la barra de busqueda.
  Future _buscarLugar(String value) async {
    BusquedaMaps busqueda = BusquedaMaps();
    busqueda.search = value;
    http.Response res = await http.get(busqueda.urlBusqueda);
    //debugPrint(res.body);
    PlacesMaps placesMaps = PlacesMaps.fromJson(jsonDecode(res.body));
    setState(() {
      if (marcadores.length == 2 && polylinesRutas.isNotEmpty) {
        botonesWidget = SizedBox();
        polylinesRutas.clear();
        List oldMarkers = marcadores.toList();
        oldMarkers.removeLast();
        marcadores = oldMarkers.toSet();
      }
      lugares = Set.from(placesMaps.results);
    });
    return await Future.delayed(Duration(milliseconds: 300));
  }

  //Método encargado de obtener la lista de los lugares
  Widget _listaResult() {
    return FutureBuilder(
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (lugares.isNotEmpty) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              color: Color.fromRGBO(255, 255, 255, 0.9),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(10.0),
                bottom: Radius.circular(15.0),
              ),
            ),
            width: MediaQuery.of(context).size.width * 0.93,
            height: MediaQuery.of(context).size.height * 0.42,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: ListView.builder(
                itemCount: lugares.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () {
                      _addMarcador(index);
                      _botonRuta();
                    },
                    child: Card(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 8.0),
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child:
                                  Image.network(lugares.elementAt(index).icon),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5.0),
                                  child: Text(
                                    lugares.elementAt(index).name,
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text(
                                  lugares.elementAt(index).formattedAddress,
                                  style: TextStyle(color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          return Container();
          // return Container(
          //     decoration: BoxDecoration(
          //       border: Border.all(color: Colors.blue),
          //       color: Color.fromRGBO(255, 255, 255, 0.9),
          //       borderRadius: BorderRadius.vertical(
          //         top: Radius.circular(10.0),
          //         bottom: Radius.circular(25.0),
          //       ),
          //     ),
          //     width: MediaQuery.of(context).size.width * 0.93,
          //     height: MediaQuery.of(context).size.height * 0.30,
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: <Widget>[
          //         Text(
          //           'No se han encontrado resultados :(',
          //           style: TextStyle(
          //               fontSize: 18.0,
          //               color: Colors.blueGrey,
          //               fontWeight: FontWeight.w500),
          //         ),
          //         SizedBox(
          //           height: 10.0,
          //         ),
          //         Icon(
          //           Icons.cancel,
          //           color: Colors.red,
          //           size: 70.0,
          //         ),
          //       ],
          //     ));
        }
      },
    );
  }

  void _addMarcador(int i) {
    setState(() {
      //print(i);
      marcadores.add(
        Marker(
          markerId: MarkerId(lugares.elementAt(i).id),
          position: LatLng(lugares.elementAt(i).geometry.location.lat,
              lugares.elementAt(i).geometry.location.lng),
          infoWindow: InfoWindow(
            title: lugares.elementAt(i).name,
            snippet: lugares.elementAt(i).formattedAddress,
          ),
        ),
      );
      Position p = Position(
        latitude: lugares.elementAt(i).geometry.location.lat,
        longitude: lugares.elementAt(i).geometry.location.lng,
      );
      _moverConZoom(p, 17.0);
      lugares.clear();
    });
  }

  void _prediccionLugar(String value) {
    setState(() {
      lugares.clear();
    });
  }

  Widget _botonRuta() {
    if (marcadores.length >= 2) {
      setState(() {
        botonesWidget = Container(
          key: ValueKey('Seleccion tipo viaje'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FlatButton.icon(
                onPressed: () {
                  tipo = 1;
                  generarRuta('driving');
                },
                color: Colors.blue,
                icon: Icon(Icons.directions_car),
                label: Text('Auto'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15.0),
                    bottomLeft: Radius.circular(15.0),
                  ),
                ),
              ),
              FlatButton.icon(
                onPressed: () {
                  tipo = 2;
                  generarRuta('walking');
                },
                color: Colors.green,
                icon: Icon(Icons.directions_walk),
                label: Text('Pie'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15.0),
                    bottomRight: Radius.circular(15.0),
                  ),
                ),
              ),
            ],
          ),
        );
      });
    }
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: botonesWidget,
    );
  }

  void generarRuta(String modo) async {
    BusquedaRoutes busqueda = BusquedaRoutes();
    int rutaSeleccionada = 1;

    String origen =
        '${marcadores.elementAt(0).position.latitude},${marcadores.elementAt(0).position.longitude}';
    String destino =
        '${marcadores.elementAt(1).position.latitude},${marcadores.elementAt(1).position.longitude}';

    busqueda.origen = origen;
    busqueda.destino = destino;
    busqueda.modo = modo;
    http.Response res = await http.get(busqueda.urlRoutes);
    //debugPrint(res.body);
    RoutesMaps response = RoutesMaps.fromJson(jsonDecode(res.body));

    setState(() {
      botonesWidget = Container(
        key: ValueKey('Selecciona ruta'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 40.0,
              child: FlatButton.icon(
                onPressed: () {
                  print('Ruta seleccionada = $rutaSeleccionada');
                  if (rutaSeleccionada == 1) {
                    seleccionaRuta(rutaSeleccionada - 1, response.routes);
                  }
                  iniciarViaje();
                },
                color: coloresRuta.elementAt(rutaSeleccionada - 1),
                icon: Icon(Icons.play_arrow),
                label: Text(
                  '¡Vamos!',
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
                color: Colors.white,
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
                    color: coloresRuta.elementAt(rutaSeleccionada - 1),
                    size: 35.0,
                  ),
                  onSelected: (selecionado) {
                    setState(() {
                      rutaSeleccionada = selecionado;
                    });
                    print(rutaSeleccionada);
                    seleccionaRuta(rutaSeleccionada - 1, response.routes);
                  },
                  itemBuilder: (BuildContext context) {
                    int numRuta = 0;
                    List<PopupMenuEntry> opciones = <PopupMenuEntry>[];
                    response.routes.forEach((ruta) {
                      numRuta++;
                      opciones.add(
                        PopupMenuItem(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                'Ruta $numRuta',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: coloresRuta.elementAt(numRuta - 1),
                                ),
                                textAlign: TextAlign.start,
                              ),
                              Text(
                                'Tiempo aproximado: ${ruta.legs.elementAt(0).duration.text}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          value: numRuta,
                        ),
                      );
                      if (numRuta < response.routes.length) {
                        opciones.add(PopupMenuDivider());
                      }
                    });
                    return opciones;
                  }),
            ),
          ],
        ),
      );
    });

    response.routes.forEach(
      (routes) {
        List<LatLng> coordenadasPolilyne =
            decodeEncodedPolyline(routes.overviewPolyline.points);
        PolylineId idRuta = PolylineId('Ruta $rutaSeleccionada');
        setState(() {
          Polyline temppoly = Polyline(
              polylineId: idRuta,
              color: coloresRuta.elementAt(rutaSeleccionada - 1),
              width: 5,
              points: coordenadasPolilyne,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              onTap: () {
                print('Ha seleccionado la ruta: $idRuta');
              });
          polylinesRutas.add(temppoly);
          rutaSeleccionada++;
        });

        routes.legs.forEach(
          (legs) {
            legs.steps.forEach((steps) {
              encodedRuta = encodedRuta + '${steps.polyline.points}  ';
            });
          },
        );

        LatLng suroeste =
            LatLng(routes.bounds.southwest.lat, routes.bounds.southwest.lng);
        LatLng noreste =
            LatLng(routes.bounds.northeast.lat, routes.bounds.northeast.lng);
        LatLngBounds limites =
            LatLngBounds(southwest: suroeste, northeast: noreste);
        _moverRuta(limites, 35.0);
        // print(encodedRuta);
      },
    );
  }

  void cargaBarraSuperior() {
    setState(() {
      barraSuperior = Container(
        padding: EdgeInsets.symmetric(
          vertical: 4.0,
          horizontal: 0.0,
        ),
        key: ValueKey('Barra Superior'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: Colors.white70,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _botonBusqueda(),
            Flexible(
              child: FractionallySizedBox(
                widthFactor: 0.80,
              ),
            ),
            _botonRutas(),
            Flexible(
              child: FractionallySizedBox(
                widthFactor: 0.80,
              ),
            ),
            _botonCuidadores(),
            Flexible(
              child: FractionallySizedBox(
                widthFactor: 0.80,
              ),
            ),
            _botonViajes(),
            Flexible(
              child: FractionallySizedBox(
                widthFactor: 0.80,
              ),
            ),
            _botonExtra(),
          ],
        ),
      );
    });
  }

  void _inicializaWidgets() {
    setState(() {
      botonesWidget = SizedBox();
      cargaBarraSuperior();
    });
  }

  void iniciarViaje() {
    setState(() async {
      botonesWidget = SizedBox();
      enViaje = true;
      DocumentReference databaseReference = Firestore.instance
          .collection('Artely_BD')
          .document(preferencias.userID);
      DocumentReference actualizador = Firestore.instance
          .collection('Artely_BD')
          .document(preferencias.userID);

      Position inicio = await Geolocator()
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      _moverConZoom(inicio, 17.0);

      Map<String, dynamic> datosviaje = {
        "POrigen": new GeoPoint(inicio.latitude, inicio.longitude),
        "PDestino": new GeoPoint(marcadores.elementAt(1).position.latitude,
            marcadores.elementAt(1).position.longitude),
        "Encoded_Polyline": encodedRuta,
        "Tipo_Viaje": tipo,
        "PActual": new GeoPoint(inicio.latitude, inicio.longitude),
      };

      try {
        databaseReference.updateData(
          {
            'Viaje': datosviaje,
          },
        ).then((valor) {
          databaseReference.updateData(
            {
              'En_viaje': enViaje,
            },
          );
        });

        Geolocator geolocator = Geolocator();
        LocationOptions locationOptions = LocationOptions(
          accuracy: LocationAccuracy.best,
          timeInterval: 5000,
        );
        positionStream = geolocator.getPositionStream(locationOptions).listen(
          (Position position) {
            if (position == null) {
              print('Error al obtener la ubicación');
            } else {
              datosviaje['PActual'] =
                  new GeoPoint(position.latitude, position.longitude);
              print(datosviaje);

              print(
                  'Lat: ${position.latitude} Lng: ${position.longitude} Tiempo: ${position.timestamp}');

              actualizador.updateData(
                {
                  'Viaje': datosviaje,
                },
              );

              _moverConZoom(position, 17.0);
            }
          },
        );
      } catch (error) {
        print(error);
      }
    });
  }

  void seleccionaRuta(int rutaSeleccionada, List<Rutas.Routes> routes) {
    encodedRuta = '';
    polylinesRutas.clear();
    List<LatLng> coordenadasPolilyne = decodeEncodedPolyline(
        routes.elementAt(rutaSeleccionada).overviewPolyline.points);

    PolylineId idRuta = PolylineId('Ruta ${rutaSeleccionada + 1}');
    setState(() {
      Polyline temppoly = Polyline(
        polylineId: idRuta,
        color: coloresRuta.elementAt(rutaSeleccionada),
        width: 5,
        points: coordenadasPolilyne,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );
      polylinesRutas.add(temppoly);
    });
    routes.elementAt(rutaSeleccionada).legs.forEach((legs) {
      legs.steps.forEach((steps) {
        encodedRuta = encodedRuta + '${steps.polyline.points}  ';
      });
    });

    LatLng suroeste = LatLng(
        routes.elementAt(rutaSeleccionada).bounds.southwest.lat,
        routes.elementAt(rutaSeleccionada).bounds.southwest.lng);
    LatLng noreste = LatLng(
        routes.elementAt(rutaSeleccionada).bounds.northeast.lat,
        routes.elementAt(rutaSeleccionada).bounds.northeast.lng);
    LatLngBounds limites =
        LatLngBounds(southwest: suroeste, northeast: noreste);
    _moverRuta(limites, 35.0);
    // print(encodedRuta);
  }

  //Carga el botón de busqueda a la barra superior
  Widget _botonBusqueda() {
    return Tooltip(
      message: 'Buscar',
      child: MaterialButton(
        minWidth: 10.0,
        elevation: 5.0,
        color: Colors.white,
        shape: CircleBorder(),
        padding: EdgeInsets.all(10.0),
        child: Icon(
          Icons.search,
          color: Colors.cyan,
          size: 27.0,
        ),
        onPressed: cargarBarraBusqueda,
      ),
    );
  }

  //Carga el botón de cuidadores a la barra superior
  Widget _botonCuidadores() {
    return Tooltip(
      message: 'Mis Cuidadores',
      child: MaterialButton(
        elevation: 5.0,
        minWidth: 10.0,
        color: Colors.white,
        shape: CircleBorder(),
        padding: EdgeInsets.all(10.0),
        child: Icon(
          Icons.people,
          color: Colors.cyan,
          size: 27.0,
        ),
        onPressed: () {
          Navigator.of(context).pushNamed('cuidadores');
        },
      ),
    );
  }

  //Carga el botón de viajes a la barra superior
  Widget _botonViajes() {
    return Tooltip(
      message: 'Mis viajes',
      child: MaterialButton(
        elevation: 5.0,
        minWidth: 10.0,
        color: Colors.white,
        shape: CircleBorder(),
        padding: EdgeInsets.all(10.0),
        child: Icon(
          Icons.directions_car,
          color: Colors.cyan,
          size: 27.0,
        ),
        onPressed: () {
          Navigator.of(context).pushNamed('viajes');
        },
      ),
    );
  }

  //Carga el botón de protegiddos a la barra superior
  Widget _botonRutas() {
    return Tooltip(
      message: 'Mis rutas',
      child: MaterialButton(
        elevation: 5.0,
        minWidth: 10.0,
        color: Colors.white,
        shape: CircleBorder(),
        padding: EdgeInsets.all(10.0),
        child: Icon(
          Icons.place,
          color: Colors.cyan,
          size: 27.0,
        ),
        onPressed: () {
          Navigator.of(context).pushNamed('rutas');
        },
      ),
    );
  }

  //Carga el botón de extra a la barra superior
  Widget _botonExtra() {
    return Tooltip(
      message: 'Mis extra',
      child: MaterialButton(
        elevation: 5.0,
        minWidth: 10.0,
        color: Colors.white,
        shape: CircleBorder(),
        padding: EdgeInsets.all(10.0),
        child: Icon(
          Icons.settings,
          color: Colors.cyan,
          size: 27.0,
        ),
        onPressed: () {
          Navigator.of(context).pushNamed('rutas');
        },
      ),
    );
  }
}
