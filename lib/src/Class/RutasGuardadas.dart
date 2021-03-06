import 'package:geolocator/geolocator.dart';
import 'package:prueba_maps/src/Util/Direcciones.dart';

class RutasGuardadas {
  Direcciones origen = Direcciones();
  Direcciones destino = Direcciones();
  int tipo;
  int tiempo;
  String encodedPolyline;

  RutasGuardadas({
    this.origen,
    this.destino,
    this.tipo,
    this.tiempo,
    this.encodedPolyline,
  });

  RutasGuardadas.fromJson(Map<String, dynamic> json) {
    Position destinoPosition = new Position(
      latitude: json['Destino'].latitude,
      longitude: json['Destino'].longitude,
    );
    Position origenPosition = new Position(
      latitude: json['Origen'].latitude,
      longitude: json['Origen'].longitude,
    );
    destino.lugar = destinoPosition;
    origen.lugar = origenPosition;
    tipo = json['Tipo'];
    tiempo = json['Tiempo'];
    encodedPolyline = json['Encoded_Polyline'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Destino'] = this.destino;
    data['Origen'] = this.origen;
    data['Tipo'] = this.tipo;
    data['Tiempo'] = this.tiempo;
    data['Encoded_Polyline'] = this.encodedPolyline;
    return data;
  }

  @override
  String toString() {
    return 'Origen: [${this.origen.toString()}] ' +
        'Destino: [${this.destino.toString()}] ' +
        'Tipo: ${this.tipo} ' +
        'Tiempo: ${this.tiempo} ' +
        'Encoded polyline: ${this.encodedPolyline} ';
  }
}
