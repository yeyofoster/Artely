import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:prueba_maps/src/Class/Routes.dart';

class Viaje {
  Position pactual;
  Position pdestino;
  double distanciaLlegada;
  String origen;
  String destino;
  String minutos;
  String horaInicio;
  String horaLlegada;
  bool aprendizaje;
  int tipo;

  Viaje(
      {this.tipo = 0,
      this.pactual,
      this.pdestino,
      this.origen = '',
      this.destino = '',
      this.distanciaLlegada = 0,
      this.minutos = '',
      this.aprendizaje = false,
      this.horaInicio = '',
      this.horaLlegada = ''});

  Future<void> updateViaje(
      Set<Marker> marcadores, int tipoViaje, Routes datosRuta,
      {bool aprender}) async {
    this.minutos = datosRuta.legs.first.duration.text
        .substring(0, datosRuta.legs.first.duration.text.length - 4);

    this.horaInicio = DateFormat.Hm().format(DateTime.now());
    this.horaLlegada = DateFormat.Hm().format(
      DateTime.now().add(
        Duration(
          minutes: int.parse(this.minutos),
        ),
      ),
    );

    if (aprender != null) {
      this.aprendizaje = aprender;
    }

    this.pactual = Position(
      latitude: marcadores.elementAt(0).position.latitude,
      longitude: marcadores.elementAt(0).position.longitude,
    );

    this.pdestino = Position(
      latitude: marcadores.elementAt(1).position.latitude,
      longitude: marcadores.elementAt(1).position.longitude,
    );

    distanciaLlegada = await Geolocator().distanceBetween(
      pactual.latitude,
      pactual.longitude,
      pdestino.longitude,
      pdestino.longitude,
    );

    List<Placemark> listaOrigen = await Geolocator().placemarkFromCoordinates(
      marcadores.elementAt(0).position.latitude,
      marcadores.elementAt(0).position.longitude,
      localeIdentifier: 'es_MX',
    );

    List<Placemark> listaDestino = await Geolocator().placemarkFromCoordinates(
      marcadores.elementAt(1).position.latitude,
      marcadores.elementAt(1).position.longitude,
      localeIdentifier: 'es_MX',
    );

    if (listaOrigen.first.thoroughfare == '' &&
        listaOrigen.first.subThoroughfare == '') {
      this.origen =
          listaOrigen.first.subLocality + ', ' + listaOrigen.first.locality;
    } else {
      this.origen = listaOrigen.first.thoroughfare +
          ' ' +
          listaOrigen.first.subThoroughfare;
    }

    if (listaDestino.first.thoroughfare == '' &&
        listaDestino.first.subThoroughfare == '') {
      this.destino =
          listaDestino.first.subLocality + ', ' + listaDestino.first.locality;
    } else {
      this.destino = listaDestino.first.thoroughfare +
          ' ' +
          listaDestino.first.subThoroughfare;
    }
    this.tipo = tipoViaje;
  }

  Future<void> updateDistancia() async {
    print('Actualizando distancia: ${this.distanciaLlegada}');
    distanciaLlegada = await Geolocator().distanceBetween(
      pactual.latitude,
      pactual.longitude,
      pdestino.latitude,
      pdestino.longitude,
    );
    print('Nueva distancia: ${this.distanciaLlegada}');
  }

  @override
  String toString() {
    return 'Tipo: ${this.tipo}, ' +
        'Minutos: ${this.minutos}, ' +
        'Punto Origen: ${this.pactual.toString()}, ' +
        'Punto Destino: ${this.pdestino.toString()}, ' +
        'Origen: ${this.origen}, ' +
        'Destino: ${this.destino}, ' +
        'Distancia Llegada: ${this.distanciaLlegada}, ' +
        'Aprendizaje de ruta: ${this.aprendizaje}, ' +
        'Inicio: ${this.horaInicio}, ' +
        'Llegada: ${this.horaLlegada}';
  }
}
