import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:prueba_maps/src/Class/Viaje.dart';
import 'package:prueba_maps/src/Provider/Notificaciones_push.dart';
import 'package:prueba_maps/src/Shared%20preferences/Preferencias_usuario.dart';
import 'package:prueba_maps/src/Util/VentanaEmergente.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class MapaArtely extends StatefulWidget {
  @override
  _MapaArtelyState createState() => _MapaArtelyState();
}

class _MapaArtelyState extends State<MapaArtely> {
  //Variables de Google Maps
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController _mapController;
  CameraPosition _initialPosition;

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
  Future pantallaPermisos;
  Viaje datosViaje = Viaje();
  //Terminan variables

  @override
  void initState() {
    super.initState();
    _inicializaWidgets();
    ubicacionInicial();
    pantallaPermisos = _verificarPermisos();

    final notificaciones = PushNotificationsFirebase();
    notificaciones.initNotifications(preferencias.userID);
  }

  @override
  Widget build(BuildContext context) {
    //Variables de ancho y largo de la pantalla del dispositivo
    final double _maxwidth = MediaQuery.of(context).size.width;
    final double _maxheight = MediaQuery.of(context).size.height;

    return FutureBuilder(
      future: pantallaPermisos,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data.runtimeType == PermissionStatus) {
            if (_initialPosition == null) {
              ubicacionInicial();
              return Scaffold();
            } else {
              return widgetPrincipal(_maxwidth, _maxheight);
            }
          } else {
            // print('Permisos denegados: ${snapshot.data}');
            return widgetPermisos(_maxwidth);
          }
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
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

  //Metodo para verificar permisos de geolocalización
  Future _verificarPermisos() async {
    try {
      PermissionStatus status = await _permissionHandler
          .checkPermissionStatus(PermissionGroup.locationWhenInUse);
      if (status == PermissionStatus.denied) {
        setState(() {});
        return await _permissionHandler
            .requestPermissions([PermissionGroup.locationWhenInUse]);
      } else if (status == PermissionStatus.granted) {
        setState(() {});
        return status;
      }
    } catch (errorPermisos) {
      return errorPermisos;
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
      barraSuperior = cargaBarraSuperior();
      encodedRuta = '';
      datosViaje = Viaje();
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
      initialCameraPosition: _initialPosition,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: false,
      trafficEnabled: false,
      zoomGesturesEnabled: true,
      markers: Set.from(marcadores), //Crea la lista de marcadores para el mapa
      polylines: polylinesRutas,
      mapToolbarEnabled:
          false, //Quita los botones de naavegación cuando se presiona un marcador.
      onTap: (puntoLatLng) {
        FocusScope.of(context).unfocus();
        if (polylinesRutas.isEmpty) {
          setState(() {
            _detener();
          });
        }
      },
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
        _mapController = controller;
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
            barraSuperior = cargaBarraSuperior();
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
                  iniciarViaje(response.routes.elementAt(rutaSeleccionada - 1));
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

  Widget cargaBarraSuperior() {
    return Container(
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
          _botonConfiguracion(),
        ],
      ),
    );
  }

  void _inicializaWidgets() {
    setState(() {
      botonesWidget = SizedBox();
      barraSuperior = cargaBarraSuperior();
    });
  }

  void iniciarViaje(Rutas.Routes datosRuta) {
    setState(() async {
      botonesWidget =
          SizedBox(); //Se actualiza el widget para quitar el botón de selección de ruta.
      enViaje =
          true; //Pasamos a true el valor de 'enViaje' para mandarlo a Firestore y modificar la interfáz de viaje.

      /*
      Se crean 2 referencias del documento que vamos a actualizar.
      Una para obtener los valores y otra que actualiza los valores.
      */
      DocumentReference databaseReference = Firestore.instance
          .collection('Artely_BD')
          .document(preferencias.userID);
      DocumentReference actualizador = Firestore.instance
          .collection('Artely_BD')
          .document(preferencias.userID);

      //Solicitamos la ubicación actual del dispositivo.
      Position inicio = await Geolocator()
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      datosViaje.minutos = datosRuta.legs.first.duration.text
          .substring(0, datosRuta.legs.first.duration.text.length - 3);
      datosViaje.origen = datosRuta.legs.first.startAddress;
      datosViaje.destino = datosRuta.legs.first.endAddress;
      datosViaje.tipo = tipo;

      print(datosViaje.toString());
      _moverConZoom(inicio, 17.0);

      //Creamos el map con los valores de inicio del viaje.
      Map<String, dynamic> datosMapViaje = {
        "POrigen": new GeoPoint(inicio.latitude, inicio.longitude),
        "PDestino": new GeoPoint(marcadores.elementAt(1).position.latitude,
            marcadores.elementAt(1).position.longitude),
        "Encoded_Polyline": encodedRuta,
        "Tipo_Viaje": tipo,
        "PActual": new GeoPoint(inicio.latitude, inicio.longitude),
      };

      //Actualizamos el valor de los datos de viaje en el documento del protegido.
      try {
        databaseReference.updateData(
          {
            'Viaje': datosMapViaje,
          },
        ).then((valor) {
          databaseReference.updateData(
            {
              'En_viaje': enViaje,
            },
          );
        });

        /*
          Hacemos la instancia de una clase que se encargará de 
          obtener la ubicación del dispositivo cada 5 segundos.
        */
        Geolocator geolocator = Geolocator();
        LocationOptions locationOptions = LocationOptions(
          accuracy: LocationAccuracy.best,
          timeInterval: 5000,
        );

        /*
        Creamos un stream para obtener la ubicación del protegido cada 5 segundos.
        Si se pudo obtener la ubicación, actualizamos 'PActual' en el documento del protegido
        y movemos la cámara del mapa a la ubicación actual.
        */
        positionStream = geolocator.getPositionStream(locationOptions).listen(
          (Position position) {
            if (position == null) {
              print('Error al obtener la ubicación');
            } else {
              datosMapViaje['PActual'] =
                  new GeoPoint(position.latitude, position.longitude);

              print(
                  'Lat: ${position.latitude} Lng: ${position.longitude} Tiempo: ${position.timestamp}');

              actualizador.updateData(
                {
                  'Viaje': datosMapViaje,
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
        child: SvgPicture.asset(
          'assets/icon/route.svg',
          color: Colors.cyan,
          height: 27.0,
        ),
        onPressed: () {
          Navigator.of(context).pushNamed('rutas');
        },
      ),
    );
  }

  //Carga el botón de extra a la barra superior
  Widget _botonConfiguracion() {
    return Tooltip(
      message: 'Mi configuración',
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
          Navigator.of(context).pushNamed('config');
        },
      ),
    );
  }

  //Método que regresa el SlideUpPanel con los datos del viaje.
  Widget slideUpViaje(double maxheight, double maxwidth) {
    List<String> datosOrigen = datosViaje.origen.split(',');
    List<String> datosDestino = datosViaje.destino.split(',');
    return SlidingUpPanel(
      color: Color.fromRGBO(255, 255, 255, 0.90),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(25.0),
        topRight: Radius.circular(25.0),
      ),
      maxHeight: maxheight * 0.22,
      minHeight: maxheight * 0.1,
      collapsed: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: maxwidth * 0.04),
        decoration: BoxDecoration(
          // color: Colors.yellow[300],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
          ),
        ),
        child: slideUpCollapsed(maxwidth, maxheight, datosOrigen, datosDestino),
      ),
      panel: slideUpPanel(maxwidth, maxheight, datosOrigen, datosDestino),
    );
  }

  //Método que regresa todos los componentes de la pagina principal MapaArtely.
  Widget widgetPrincipal(double maxwidth, double maxheight) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () {
          if (!enViaje) {
            VentanaEmergente cerrarApp = VentanaEmergente(
              height: maxheight * 0.3,
              titulo: 'Cerrando',
              backgroundColorTitulo: Colors.cyan,
              contenido: Container(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Icon(
                        Icons.exit_to_app,
                        color: Colors.cyan,
                        size: 50.0,
                      ),
                    ),
                    Text(
                      '¿Estás seguro de cerrar la app?',
                      style: GoogleFonts.openSans(color: Colors.blueGrey),
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          MaterialButton(
                            color: Colors.blue[400],
                            minWidth: MediaQuery.of(context).size.width * 0.3,
                            child: Text('Continuar'),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          SizedBox(
                            width: 20.0,
                          ),
                          MaterialButton(
                            color: Colors.red[400],
                            minWidth: MediaQuery.of(context).size.width * 0.3,
                            child: Text('Cerrar'),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            onPressed: () {
                              SystemChannels.platform
                                  .invokeMethod('SystemNavigator.pop');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
            cerrarApp.mostrarVentana(context);
          } else {}
          return null;
        },
        child: Scaffold(
          body: Stack(
            children: <Widget>[
              Positioned(
                width: maxwidth,
                height: maxheight,
                child: _creaMapa(),
              ),
              Positioned(
                width: maxwidth,
                height: maxheight * 0.10,
                top: enViaje ? maxheight * 0.75 : maxheight * 0.84,
                right: maxwidth * 0.03,
                //child: Container(color: Colors.cyan,),
                child: _crearBotones(),
              ),
              Positioned(
                width: maxwidth * 0.93,
                top: maxheight * 0.05,
                left: maxwidth * 0.03,
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
                top: maxheight * 0.85,
                left: maxwidth * 0.07,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 500),
                  child: botonesWidget,
                ),
              ),
              AnimatedSwitcher(
                duration: Duration(
                  milliseconds: 700,
                ),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 500),
                  child:
                      enViaje ? slideUpViaje(maxheight, maxwidth) : Container(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Método que regresa la pantalla de motivo de permisos.
  Widget widgetPermisos(double maxwidth) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Para el funcionamiento adecuado Artely hace uso de tu ubicación',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(),
            ),
            SizedBox(
              height: 20.0,
            ),
            MaterialButton(
              child: Text('Solicitar permisos'),
              color: Colors.cyan[300],
              minWidth: maxwidth * 0.6,
              height: 50.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              onPressed: () {
                setState(() {
                  pantallaPermisos = _verificarPermisos();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  //Método que obtiene la ubicación actual del dispositivo y actualiza la posición inicial del mapa.
  Future<void> ubicacionInicial() async {
    try {
      Position pos = await Geolocator()
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      setState(() {
        _initialPosition = CameraPosition(
          target: LatLng(pos.latitude, pos.longitude),
          zoom: 16.0,
        );
      });
    } catch (e) {
      print('Error, no se pudo ubicar: $e');
    }
  }

  //Método que regresa el widget que se muestra cuando el SLideUpPanel está colapsado.
  Widget slideUpCollapsed(double maxwidth, double maxheight,
      List<String> datosOrigen, List<String> datosDestino) {
    return Row(
      children: <Widget>[
        Container(
          child: Icon(
            datosViaje.tipo == 1 ? Icons.directions_car : Icons.directions_walk,
            size: maxheight * 0.045,
          ),
        ),
        SizedBox(
          width: maxwidth * 0.03,
        ),
        Expanded(
          child: Wrap(
            direction: Axis.horizontal,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Container(
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(
                  bottom: 10.0,
                ),
                child: Text(
                  'Viaje en curso',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w700, fontSize: 18.0),
                ),
              ),
              Container(
                color: Colors.blue[100],
                child: Text(
                  datosOrigen.first,
                  style: GoogleFonts.roboto(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: Colors.grey[600],
                size: 20.0,
              ),
              Container(
                color: Colors.blue[100],
                child: Text(
                  datosDestino.first,
                  style: GoogleFonts.roboto(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: maxwidth * 0.03,
        ),
        Container(
          padding: EdgeInsets.all(8.0),
          child: Wrap(
            alignment: WrapAlignment.end,
            direction: Axis.vertical,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                'Tiempo',
                style: GoogleFonts.openSans(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                datosViaje.minutos,
                style: GoogleFonts.openSans(
                  fontSize: 18.0,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'min',
                style: GoogleFonts.openSans(
                  fontSize: 12.0,
                  color: Colors.grey[600],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  //Método que regresa el widget que se muestra cuando el SLideUpPanel está en panel.
  Widget slideUpPanel(double maxwidth, double maxheight,
      List<String> datosOrigen, List<String> datosDestino) {
    return Container(
      alignment: Alignment.center,
      child: Text('Datos viaje'),
    );
  }
}
