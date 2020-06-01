import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:prueba_maps/src/Class/ArtelyColors.dart';

//Librerias Propias
import 'package:prueba_maps/src/Class/BusquedaMaps.dart';
import 'package:prueba_maps/src/Class/BusquedaRoutes.dart';
import 'package:prueba_maps/src/Class/Polylines.dart';
import 'package:prueba_maps/src/Class/PlacesMaps.dart';
import 'package:prueba_maps/src/Class/Results.dart';
import 'package:prueba_maps/src/Class/Routes.dart' as Rutas;
import 'package:prueba_maps/src/Class/RoutesMaps.dart';
import 'package:prueba_maps/src/Class/RutasGuardadas.dart';
import 'package:prueba_maps/src/Class/Viaje.dart';
import 'package:prueba_maps/src/Pages/MapaCuidador.dart';
import 'package:prueba_maps/src/Pages/Rutas.dart';
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
  Widget botonRuta;
  Widget barraSuperior;
  StreamSubscription<Position> positionStream;
  String encodedRuta = '';
  int tipo;
  bool enViaje = false;
  PreferenciasUsuario preferencias = new PreferenciasUsuario();
  List<String> protegidosEnViaje = [];
  Future pantallaPermisos;
  Viaje datosViaje = Viaje();
  //Terminan variables

  @override
  void initState() {
    super.initState();
    _inicializaWidgets();
    pantallaPermisos = _verificarPermisos();
    // preferencias.protegidosEnViaje = [];
    protegidosEnViaje = preferencias.protegidosEnViaje ?? [];

    final notificaciones = PushNotificationsFirebase();
    notificaciones.initNotifications(preferencias.userID);

    notificaciones.mensajes.listen(
      (datos) {
        setState(() {
          // print(datos['click_action'].runtimeType);
          if (datos['tipo_notificacion'] == 'inicio_viaje') {
            print('Agregando a lista de protegidos en viaje');
            protegidosEnViaje.add(datos['id_Protegido']);
            preferencias.protegidosEnViaje = protegidosEnViaje;
          } else if (datos['tipo_notificacion'] == 'finalizo_viaje') {
            print('Eliminando de la lista de protegidos en viaje');
            protegidosEnViaje.removeWhere(
              (idProtegido) => idProtegido == datos['id_Protegido'],
            );
            preferencias.protegidosEnViaje = protegidosEnViaje;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //Variables de ancho y largo de la pantalla del dispositivo
    final double _maxwidth = MediaQuery.of(context).size.width;
    final double _maxheight = MediaQuery.of(context).size.height;

    return FutureBuilder(
      future: pantallaPermisos,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        print('Estado: ${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data.runtimeType == PermissionStatus) {
            if (_initialPosition == null) {
              pantallaPermisos = _verificarPermisos();
            } else {
              return widgetPrincipal(_maxwidth, _maxheight);
            }
          } else {
            Map<PermissionGroup, PermissionStatus> res = snapshot.data;
            print(res[PermissionGroup.locationWhenInUse]);
            if (res[PermissionGroup.locationWhenInUse] ==
                PermissionStatus.granted) {
              pantallaPermisos = _verificarPermisos();
            } else {
              return widgetPermisos(_maxwidth);
            }
          }
          return Scaffold();
        } else {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  //Metodo para verificar permisos de geolocalización
  Future _verificarPermisos() async {
    try {
      PermissionStatus status = await _permissionHandler
          .checkPermissionStatus(PermissionGroup.locationWhenInUse);
      if (status == PermissionStatus.denied) {
        return await _permissionHandler
            .requestPermissions([PermissionGroup.locationWhenInUse]);
      } else if (status == PermissionStatus.granted) {
        print('Permisos otorgados');
        Position pos = await Geolocator()
            .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
            .catchError((onError) {
          print('Error: $onError');
        });
        print(pos);
        setState(() {
          _initialPosition = CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 16.0,
          );
        });
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

    List<Placemark> listaUbicacion =
        await Geolocator().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
      localeIdentifier: 'es_MX',
    );
    String pos;

    if (listaUbicacion.first.thoroughfare == '' &&
        listaUbicacion.first.subThoroughfare == '') {
      pos = listaUbicacion.first.subLocality +
          ', ' +
          listaUbicacion.first.locality;
    } else {
      pos = listaUbicacion.first.thoroughfare +
          ' ' +
          listaUbicacion.first.subThoroughfare;
    }

    _moverConZoom(position, 16.0);
    setState(() {
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
    _moverConZoom(position, enViaje ? 17.0 : 16.0);
  }

  //Método que detiene la detección de la ubicación del dispositivo.
  void _detener() {
    setState(() {
      marcadores.clear();
      polylinesRutas.clear();
      botonRuta = SizedBox();
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
        if (polylinesRutas.isEmpty && marcadores.length < 2) {
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
            botonRuta = SizedBox();
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
        botonRuta = SizedBox();
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
        botonRuta = Container(
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
      child: botonRuta,
    );
  }

  //Genera y modifica los botones para iniciar una ruta aprendida.
  Future<void> generarRutaAprendida(RutasGuardadas ruta) async {
    polylinesRutas.clear();
    marcadores.clear();

    List<LatLng> puntosPolyline = decodeEncodedPolyline(ruta.encodedPolyline);
    PolylineId idPolyline = PolylineId('Ruta guardada');

    Position miUbicacion = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.low);

    double actualPuntoA = await Geolocator().distanceBetween(
      miUbicacion.latitude,
      miUbicacion.longitude,
      ruta.origen.lugar.latitude,
      ruta.origen.lugar.longitude,
    );

    double actualPuntoB = await Geolocator().distanceBetween(
      miUbicacion.latitude,
      miUbicacion.longitude,
      ruta.destino.lugar.latitude,
      ruta.destino.lugar.longitude,
    );

    print(actualPuntoA);
    print(actualPuntoB);

    setState(() {
      //Agregamos marcador A (origen)
      marcadores.add(
        Marker(
          markerId: MarkerId('Punto A'),
          position:
              LatLng(ruta.origen.lugar.latitude, ruta.origen.lugar.longitude),
          infoWindow:
              InfoWindow(title: 'Punto A', snippet: ruta.origen.direccion),
        ),
      );

      //Agregamos marcador B (destino)
      marcadores.add(
        Marker(
          markerId: MarkerId('Punto B'),
          position:
              LatLng(ruta.destino.lugar.latitude, ruta.destino.lugar.longitude),
          infoWindow:
              InfoWindow(title: 'Punto B', snippet: ruta.destino.direccion),
        ),
      );

      //Configuramos el tipo de viaje
      tipo = ruta.tipo;

      //Configuramos el encodedPolyline
      encodedRuta = ruta.encodedPolyline;

      //Agregamos la polyline.
      Polyline temppoly = Polyline(
        polylineId: idPolyline,
        color: Colors.cyan,
        width: 5,
        points: puntosPolyline,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        onTap: () {},
      );
      polylinesRutas.add(temppoly);

      //Obtenemos loss limites para mostrar en el mapa.
      double south =
          min(ruta.origen.lugar.latitude, ruta.destino.lugar.latitude);
      double west =
          min(ruta.origen.lugar.longitude, ruta.destino.lugar.longitude);
      double north =
          max(ruta.origen.lugar.latitude, ruta.destino.lugar.latitude);
      double east =
          max(ruta.origen.lugar.longitude, ruta.destino.lugar.longitude);

      LatLng southwest = LatLng(south, west);
      LatLng northeast = LatLng(north, east);

      LatLngBounds limites =
          LatLngBounds(southwest: southwest, northeast: northeast);
      _moverRuta(limites, 35.0);

      //Cambiamos el boton para inciar el viaje.
      botonRuta = Container(
        key: ValueKey('Ruta Guardada'),
        child: Container(
          height: 40.0,
          child: FlatButton.icon(
            onPressed: actualPuntoA > 20.0 || actualPuntoB > 20.0
                ? null
                : iniciarViaje,
            color: Colors.cyan[600],
            icon: Icon(
              Icons.play_arrow,
            ),
            label: Text(
              '¡Vamos!',
              style: TextStyle(
                fontSize: 18.0,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      );
    });
  }

  void generarRuta(String modo) async {
    BusquedaRoutes busqueda = BusquedaRoutes();
    int rutaSeleccionada = 0;

    String origen =
        '${marcadores.elementAt(0).position.latitude},${marcadores.elementAt(0).position.longitude}';
    String destino =
        '${marcadores.elementAt(1).position.latitude},${marcadores.elementAt(1).position.longitude}';

    busqueda.origen = origen;
    busqueda.destino = destino;
    busqueda.modo = modo;
    http.Response res = await http.get(busqueda.urlRoutes);
    // debugPrint(res.body);
    RoutesMaps response = RoutesMaps.fromJson(jsonDecode(res.body));

    setState(() {
      botonRuta = Container(
        key: ValueKey('Selecciona ruta'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 40.0,
              child: FlatButton.icon(
                onPressed: () {
                  print('Ruta seleccionada = $rutaSeleccionada');
                  if (rutaSeleccionada == 0) {
                    seleccionaRuta(rutaSeleccionada, response.routes);
                  }
                  if (rutaSeleccionada == 10) {
                    iniciarAprendizajeRuta();
                    //
                  } else {
                    datosViaje.updateViaje(marcadores, tipo,
                        response.routes.elementAt(rutaSeleccionada));
                    iniciarViaje();
                  }
                },
                color: Colors.cyan[600],
                icon: Icon(
                  Icons.play_arrow,
                ),
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
                    color: Colors.cyan,
                    size: 35.0,
                  ),
                  onSelected: (seleccionado) {
                    if (seleccionado == 10) {
                      //Código de aprendizaje de ruta
                      print('Aprendizaje ruta');
                      setState(() {
                        rutaSeleccionada = seleccionado;
                        datosViaje.updateViaje(
                            marcadores, tipo, response.routes.last,
                            aprender: true);
                        print(datosViaje.toString());
                        polylinesRutas.clear();
                      });
                      print(rutaSeleccionada);
                    } else {
                      setState(() {
                        rutaSeleccionada = seleccionado;
                        datosViaje.updateViaje(marcadores, tipo,
                            response.routes.elementAt(rutaSeleccionada));
                        print(datosViaje.toString());
                      });
                      print(rutaSeleccionada);
                      seleccionaRuta(rutaSeleccionada, response.routes);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    int numRuta = 0;
                    List<PopupMenuEntry> opciones = <PopupMenuEntry>[];
                    response.routes.forEach(
                      (ruta) {
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
                            value: numRuta - 1,
                          ),
                        );
                        if (numRuta < response.routes.length) {
                          opciones.add(PopupMenuDivider());
                        }
                      },
                    );
                    opciones.add(PopupMenuDivider());
                    opciones.add(
                      PopupMenuItem(
                        value: 10,
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            'Aprender nueva ruta ${tipo == 1 ? 'en auto' : 'a pie'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                    );
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
        PolylineId idRuta = PolylineId('Ruta ${rutaSeleccionada + 1}');
        setState(() {
          Polyline temppoly = Polyline(
              polylineId: idRuta,
              color: coloresRuta.elementAt(rutaSeleccionada),
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
    print('Inicializando widgets');
    setState(() {
      botonRuta = SizedBox();
      barraSuperior = cargaBarraSuperior();
    });
  }

  //Método que inicia un viaje del que se aprenderá la ruta.
  void iniciarAprendizajeRuta() {
    setState(() async {
      botonRuta = SizedBox();
      enViaje = true;

      Geolocator geolocator = Geolocator();
      LocationOptions locationOptions = LocationOptions(
        accuracy: LocationAccuracy.best,
        timeInterval: 5000,
      );
      List<LatLng> coordenadasPolilyne = [];

      Position inicio = await Geolocator()
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

      coordenadasPolilyne.add(LatLng(inicio.latitude, inicio.longitude));

      PolylineId idRuta =
          PolylineId('Ruta ${datosViaje.origen + ' - ' + datosViaje.destino}');

      Polyline temppoly = Polyline(
        polylineId: idRuta,
        color: Colors.cyan,
        width: 5,
        points: coordenadasPolilyne,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      );
      polylinesRutas.add(temppoly);

      try {
        Position anterior = Position(
          latitude: inicio.latitude,
          longitude: inicio.longitude,
        );
        double distancia = 0.0;

        positionStream = geolocator.getPositionStream(locationOptions).listen(
          (Position actual) async {
            if (actual == null) {
              print('Error al obtener la ubicación');
            } else {
              datosViaje.pactual = actual;
              datosViaje.updateDistancia();

              distancia = await Geolocator().distanceBetween(anterior.latitude,
                  anterior.longitude, actual.latitude, actual.longitude);
              // print('Distancia: $distancia metros');

              if (distancia > 10.0) {
                // print('Agregando nuevo punto a la lista.');
                coordenadasPolilyne
                    .add(LatLng(actual.latitude, actual.longitude));

                Polyline temppoly = Polyline(
                  polylineId: idRuta,
                  color: Colors.cyan,
                  width: 5,
                  points: coordenadasPolilyne,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                );
                polylinesRutas.clear();
                polylinesRutas.add(temppoly);

                anterior = actual;
              }
              _moverConZoom(actual, 17.0);
            }
          },
        );
      } catch (error) {
        print('Error en aprendizaje de ruta: $error');
      }
    });
  }

  //Método que inicia el viaje.
  void iniciarViaje() {
    setState(() async {
      botonRuta =
          SizedBox(); //Se actualiza el widget para quitar el botón de selección de ruta.

      //Solicitamos la ubicación actual del dispositivo.
      Position inicio = await Geolocator()
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

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

      enViaje =
          true; //Pasamos a true el valor de 'enViaje' para mandarlo a Firestore y modificar la interfáz de viaje.

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
          accuracy: LocationAccuracy.low,
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

              datosViaje.pactual = position;
              datosViaje.updateDistancia();

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
        onPressed: () {
          botonRuta = Container();
          polylinesRutas.clear();
          marcadores.clear();
          cargarBarraBusqueda();
        },
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
          _detener();
          _ubicarme();
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
          _detener();
          _ubicarme();
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
        onPressed: () async {
          RutasGuardadas ruta = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaRutas(),
            ),
          );
          if (ruta != null) {
            generarRutaAprendida(ruta);
          } else {
            _detener();
            _ubicarme();
          }
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
          _detener();
          _ubicarme();
          Navigator.of(context).pushNamed('config');
        },
      ),
    );
  }

  //Método que regresa todos los componentes de la pagina principal MapaArtely.
  Widget widgetPrincipal(double maxwidth, double maxheight) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () {
          if (!enViaje && polylinesRutas.isEmpty) {
            VentanaEmergente cerrarApp = VentanaEmergente(
              height: maxheight * 0.3,
              titulo: 'Cerrando',
              closeButton: false,
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
          } else {
            _detener();
            _ubicarme();
          }
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
                top: maxheight > 700
                    ? (enViaje ? maxheight * 0.76 : maxheight * 0.86)
                    : (enViaje ? maxheight * 0.7 : maxheight * 0.8),
                right: maxwidth * 0.02,
                child: MaterialButton(
                  child: Icon(Icons.my_location,
                      color: Colors.white.withOpacity(0.9)),
                  color: Colors.black45,
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(14.0),
                  elevation: 5.0,
                  onPressed: _ubicarme,
                ),
              ),
              Positioned(
                width: maxwidth * 0.93,
                top: maxheight * 0.05,
                left: maxwidth * 0.03,
                child: enViaje
                    ? Container()
                    : Column(
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
                  child: botonRuta,
                ),
              ),
              Positioned(
                right: 0.0,
                top: enViaje ? maxheight * 0.72 : maxheight * 0.76,
                child: AnimatedSwitcher(
                  duration: Duration(
                    milliseconds: 600,
                  ),
                  child: protegidosEnViaje.length > 0
                      ? MaterialButton(
                          height: maxheight * 0.07,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20.0),
                              bottomLeft: Radius.circular(20.0),
                            ),
                          ),
                          color: ArtelyColors.mediumSeaGreen.withOpacity(0.75),
                          child: Row(
                            children: <Widget>[
                              Text(
                                '${protegidosEnViaje.length}',
                                style: GoogleFonts.montserrat(fontSize: 24.0),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Icon(
                                  Icons.person_pin_circle,
                                  size: 26.0,
                                ),
                              ),
                            ],
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MapaCuidador(),
                              ),
                            );
                          },
                        )
                      : Container(),
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

  //Método que regresa el SlideUpPanel con los datos del viaje.
  Widget slideUpViaje(double maxheight, double maxwidth) {
    // print(datosViaje.origen);
    // print(datosViaje.destino);
    return SlidingUpPanel(
      color: Color.fromRGBO(255, 255, 255, 0.90),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(25.0),
        topRight: Radius.circular(25.0),
      ),
      maxHeight: maxheight > 700 ? maxheight * 0.26 : maxheight * 0.33,
      minHeight: maxheight > 700 ? maxheight * 0.1 : maxheight * 0.15,
      panel: slideUpPanel(maxwidth, maxheight),
    );
  }

  //Método que regresa el widget que se muestra cuando el SLideUpPanel está en panel.
  Widget slideUpPanel(double maxwidth, double maxheight) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
                padding: EdgeInsets.only(left: maxwidth * 0.01),
                child: (() {
                  if (datosViaje.tipo == 1) {
                    return Icon(
                      Icons.directions_car,
                      size: maxheight * 0.045,
                    );
                  } else if (datosViaje.tipo == 2) {
                    return Icon(
                      Icons.directions_walk,
                      size: maxheight * 0.045,
                    );
                  } else {
                    return Container();
                  }
                }())),
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
                  Text(
                    datosViaje.origen,
                    style: GoogleFonts.roboto(
                      fontSize: 16.0,
                      color: Colors.grey[600],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.grey[600],
                    size: 20.0,
                  ),
                  Text(
                    datosViaje.destino,
                    style: GoogleFonts.roboto(
                      fontSize: 16.0,
                      color: Colors.grey[600],
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
        ),
        Expanded(
          child: Container(
            // color: Colors.pink[200],
            alignment: Alignment.topCenter,
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Inicio: ${datosViaje.horaInicio}',
                  style: GoogleFonts.roboto(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Llegada estimada: ${datosViaje.horaLlegada}',
                  style: GoogleFonts.roboto(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(
                  height: maxheight * 0.01,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    MaterialButton(
                      color: Colors.blue[400],
                      minWidth: maxwidth * 0.3,
                      height: 40.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                      child: Text('¡Llegué!'),
                      onPressed: datosViaje.distanciaLlegada > 70.0
                          ? null
                          : _finalizarViaje,
                    ),
                    SizedBox(
                      width: maxwidth * 0.08,
                    ),
                    MaterialButton(
                      color: Colors.red[400],
                      minWidth: maxwidth * 0.3,
                      height: 40.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                      child: Text('Cancelar'),
                      onPressed: _detener,
                    ),
                  ],
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  void _finalizarViaje() {
    if (datosViaje.aprendizaje) {
      Polyline ruta = polylinesRutas.first;
      String encodedPoints = encodePolylineFromPoints(ruta.points, 5);

      Map<String, dynamic> datosRuta = {
        'Origen': new GeoPoint(marcadores.elementAt(0).position.latitude,
            marcadores.elementAt(0).position.longitude),
        'Destino': new GeoPoint(marcadores.elementAt(1).position.latitude,
            marcadores.elementAt(1).position.longitude),
        'Encoded_Polyline': encodedPoints,
        'Tiempo': datosViaje.minutos,
        'Tipo': tipo,
      };

      Firestore.instance
          .collection('Artely_BD')
          .document(preferencias.userID)
          .collection('Rutas')
          .document()
          .setData(datosRuta);

      _detener();
    } else {
      _detener();
    }
  }
}
