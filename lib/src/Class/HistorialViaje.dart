import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:prueba_maps/src/Util/Direcciones.dart';

class HistorialViaje {
  int tipo;
  Direcciones origen = Direcciones();
  Direcciones destino = Direcciones();
  String inicio;
  String llegada;

  HistorialViaje(
      {this.tipo, this.origen, this.destino, this.inicio, this.llegada});

  HistorialViaje.fromJson(Map<String, dynamic> json) {
    tipo = json['Tipo'];
    origen.lugar = new Position(
      latitude: json['Origen'].latitude,
      longitude: json['Origen'].longitude,
    );
    destino.lugar = new Position(
      latitude: json['Origen'].latitude,
      longitude: json['Origen'].longitude,
    );
    inicio = new DateFormat.yMMMMEEEEd('es_MX').add_jm().format(
        DateTime.fromMillisecondsSinceEpoch(json['Inicio'].seconds * 1000,
            isUtc: true));
    llegada = new DateFormat.yMMMMEEEEd('es_MX').add_jm().format(
        DateTime.fromMillisecondsSinceEpoch(json['Llegada'].seconds * 1000,
            isUtc: true));
  }

  @override
  String toString() {
    return 'Origen: [${origen.toString()}] ' +
        'Destino: [${destino.toString()}] ' +
        'Inicio: ${inicio.toString()} ' +
        'Llegada: ${llegada.toString()} ' +
        'Tipo: $tipo';
  }
}
