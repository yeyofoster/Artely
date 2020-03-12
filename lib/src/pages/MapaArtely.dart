import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

class MapaArtely extends StatefulWidget {
  @override
  _MapaArtelyState createState() => _MapaArtelyState();
}

class _MapaArtelyState extends State<MapaArtely> {
  //Inician variables
  final _estilo1 = TextStyle(
    fontSize: 20.0,
  );

  final _estilo2 = TextStyle(
    fontSize: 17.0,
  );

  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController _mapController;

  CameraPosition _mexicoposition = CameraPosition(
    target: LatLng(23.6345005, -102.5527878),
    zoom: 5.0,
  );

  PermissionHandler _permissionHandler = PermissionHandler();
  Set<Marker> marcadores = Set();
  Set<Results> lugares = Set();
  Set<Rutas.Routes> rutas = Set();
  Set<Polyline> polylinesRutas = {};

  final backgroundtext = 'Buscar';
  //Terminan variables

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
  }

  @override
  Widget build(BuildContext context) {
    //Variables de ancho y largo de la pantalla del dispositivo
    final _maxwidth = MediaQuery.of(context).size.width;
    final _maxheight = MediaQuery.of(context).size.height;

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
            Positioned(
              width: _maxwidth * 0.93,
              top: _maxheight * 0.05,
              left: _maxwidth * 0.03,
              child: Container(
                //color: Colors.blue,
                child: Column(
                  children: <Widget>[
                    _searchBarMaps(),
                    SizedBox(
                      height: 5.0,
                    ),
                    _listaResult(),
                  ],
                ),
              ),
            ),
            Positioned(
              top: _maxheight * 0.85,
              left: _maxwidth * 0.07,
              child: _botonRuta(),
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
        showDialog(
          context: this.context,
          builder: (_) => _mostrarAlerta(),
        );
        sleep(Duration(seconds: 2));
        _verificarPermisos();
      }
    }
  }

  AlertDialog _mostrarAlerta() {
    return AlertDialog(
        title: Text(
          'Permisos',
          style: _estilo1,
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        backgroundColor: Colors.blue[50],
        content: Container(
          height: 100.0,
          child: Column(
            children: <Widget>[
              Text(
                'Se necesitan permisos',
                style: _estilo2,
              ),
              SizedBox(
                height: 10.0,
              ),
              Icon(
                Icons.location_disabled,
                size: 70.0,
              ),
            ],
          ),
        ));
  }

  //Metodo para verificar permisos de geolocalización
  void _verificarPermisos() async {
    final status = await _permissionHandler
        .checkPermissionStatus(PermissionGroup.locationWhenInUse);
    if (status == PermissionStatus.denied) {
      _solicitarPermisos();
    }
  }

  //Método que permite ubicar el dispositivo.
  void _ubicarme() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    _mover(position);

    setState(() {
      String pos = 'Lat: ' +
          position.latitude.toString() +
          'Lng: ' +
          position.longitude.toString();

      marcadores.add(
        Marker(
          markerId: MarkerId('Mi ubicacion'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: InfoWindow(title: 'Mi ubicacion', snippet: pos),
        ),
      );
    });
  }

  //Método que detiene la detección de la ubicación del dispositivo.
  void _detener() {
    setState(() {
      marcadores.clear();
      polylinesRutas.clear();
    });
  }

  //Método encargado de crear el mapa. Lo retorna como widget.
  GoogleMap _creaMapa() {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _mexicoposition,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomGesturesEnabled: true,
      markers: Set.from(marcadores), //Crea la lista de marcadores para el mapa
      polylines: polylinesRutas,
      mapToolbarEnabled:
          false, //Quita los botones de naavegación cuando se presiona un marcador.
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
        _mapController = controller;
      },
    );
  }

  //Método que mueve la camara del mapa con un zoom dado.
  void _mover(Position position) {
    final ubicacion = CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude), 16.0);
    _mapController.animateCamera(ubicacion);
  }

  //Método que mueve la camara del mapa con un zoom dado.
  void _moverConZoom(Position position, double zoom) {
    setState(() {
      final ubicacion = CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude), zoom);
      _mapController.animateCamera(ubicacion);
    });
  }

  void _moverRuta(LatLngBounds bounds, double zoom) {
    setState(() {
      final ubicacion = CameraUpdate.newLatLngBounds(bounds, zoom);
      _mapController.animateCamera(ubicacion);
    });
  }

  //Método que regresa el widget de la barra de busqueda
  Widget _searchBarMaps() {
    return TextField(
      onSubmitted: _buscarLugar,
      onChanged: _prediccionLugar,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        hintText: backgroundtext,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 20.0,
        ),
        fillColor: Colors.grey[100],
        filled: true,
        suffixIcon: Icon(
          Icons.search,
          color: Colors.blue,
          size: 30.0,
        ),
      ),
    );
  }

  //Método que busca el lugar ingresado en la barra de busqueda.
  Future<void> _buscarLugar(String value) async {
    BusquedaMaps busqueda = BusquedaMaps();
    busqueda.search = value;
    http.Response res = await http.get(busqueda.urlBusqueda);
    debugPrint(res.body);
    PlacesMaps placesMaps = PlacesMaps.fromJson(jsonDecode(res.body));
    setState(() {
      lugares = Set.from(placesMaps.results);
    });
  }

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
                bottom: Radius.circular(25.0),
              ),
            ),
            width: MediaQuery.of(context).size.width * 0.93,
            height: MediaQuery.of(context).size.height * 0.35,
            child: ListView.builder(
              itemCount: lugares.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                    title: Text(lugares.elementAt(index).name),
                    subtitle: Text(lugares.elementAt(index).formattedAddress),
                    leading: SizedBox(
                        width: 30.0,
                        height: 30.0,
                        child: Image.network(lugares.elementAt(index).icon)),
                    contentPadding: EdgeInsets.only(
                      top: 0.0,
                      bottom: 7.5,
                      left: 10.0,
                      right: 15.0,
                    ),
                    onTap: () {
                      print(index);
                      _addMarcador(index);
                    });
              },
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
    return FutureBuilder(
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (marcadores.length >= 2) {
          return FlatButton(
            color: Colors.red,
            highlightColor: Colors.blue,
            padding: EdgeInsets.only(
              left: 0.0,
              top: 13.0,
              bottom: 13.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            textTheme: ButtonTextTheme.primary,
            onPressed: () {
              generarRuta();
            },
            child: Row(
              children: <Widget>[
                Icon(Icons.play_circle_filled),
                SizedBox(
                  width: 5.0,
                ),
                Text('Ruta'),
              ],
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }

  Future<void> generarRuta() async {
    BusquedaRoutes busqueda = BusquedaRoutes();
    int colorswitch = 0;
    int cuentaSteps = 0;
    int indexPunto = 1;
    String encodedRuta = '';
    Set<MaterialColor> colores = {Colors.red, Colors.blue};
    String origen =
        '${marcadores.elementAt(0).position.latitude},${marcadores.elementAt(0).position.longitude}';
    String destino =
        '${marcadores.elementAt(1).position.latitude},${marcadores.elementAt(1).position.longitude}';
    print('Origen = $origen');
    print('Destino = $destino');
    busqueda.origen = origen;
    busqueda.destino = destino;
    http.Response res = await http.get(busqueda.urlRoutes);
    //debugPrint(res.body);
    RoutesMaps response = RoutesMaps.fromJson(jsonDecode(res.body));
    response.routes.forEach(
      (routes) {
        routes.legs.forEach(
          (legs) {
            legs.steps.forEach(
              (steps) {
                encodedRuta = encodedRuta + '${steps.polyline.points}  ';
                List<LatLng> coordenadasPolilyne =
                    decodeEncodedPolyline(steps.polyline.points);
                cuentaSteps++;
                PolylineId idRuta = PolylineId('Step $cuentaSteps');
                print('Step $cuentaSteps' +
                    '  Puntos: ${coordenadasPolilyne.length}');
                coordenadasPolilyne.forEach(
                  (punto) async {
                    double distancia = await Geolocator().distanceBetween(
                        coordenadasPolilyne.elementAt(indexPunto - 1).latitude,
                        coordenadasPolilyne.elementAt(indexPunto - 1).longitude,
                        coordenadasPolilyne.elementAt(indexPunto).latitude,
                        coordenadasPolilyne.elementAt(indexPunto).longitude);
                    print(punto.toString() +
                        '\tDistancia al siguiente punto: $distancia');
                    indexPunto++;
                  },
                );
                setState(() {
                  colorswitch++;
                  if (colorswitch / 1 > 1) {
                    colorswitch = 0;
                  }
                  Polyline temppoly = Polyline(
                    polylineId: idRuta,
                    color: colores.elementAt(colorswitch),
                    width: 5,
                    points: coordenadasPolilyne,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                  );
                  polylinesRutas.add(temppoly);
                });
              },
            );
          },
        );
        LatLng suroeste =
            LatLng(routes.bounds.southwest.lat, routes.bounds.southwest.lng);
        LatLng noreste =
            LatLng(routes.bounds.northeast.lat, routes.bounds.northeast.lng);
        LatLngBounds limites =
            LatLngBounds(southwest: suroeste, northeast: noreste);
        _moverRuta(limites, 35.0);
        print(encodedRuta);
      },
      /*
      (index) {
        List<LatLng> coordenadasPolilyne =
            decodeEncodedPolyline(index.overviewPolyline.points);
        LatLng suroeste =
            LatLng(index.bounds.southwest.lat, index.bounds.southwest.lng);
        LatLng noreste =
            LatLng(index.bounds.northeast.lat, index.bounds.northeast.lng);
        LatLngBounds limites =
            LatLngBounds(southwest: suroeste, northeast: noreste);
        PolylineId idRuta = PolylineId(index.summary);
        agregaPolyline(coordenadasPolilyne, limites, idRuta);
      },
      */
    );
  }

  void agregaPolyline(List<LatLng> coordenadasPolilyne, LatLngBounds limites,
      PolylineId idRuta) {
    setState(() {
      Polyline temppoly = Polyline(
        polylineId: idRuta,
        color: Colors.blue,
        points: coordenadasPolilyne,
      );
      polylinesRutas.add(temppoly);
      _moverRuta(limites, 35.0);
    });
    print('Num. Rutas = ${polylinesRutas.length}');
    /*
    coordenadasPolilyne.forEach((punto) {
      print(punto);
    });
    */
  }
}
