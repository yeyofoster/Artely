import 'package:geolocator/geolocator.dart';
import 'package:prueba_maps/src/Util/Direcciones.dart';

class RutasGuardadas {
  Direcciones origen = Direcciones();
  Direcciones destino = Direcciones();
  int tipo;
  String encodedPolyline;

  RutasGuardadas({
    this.origen,
    this.destino,
    this.tipo,
    this.encodedPolyline,
  });

  RutasGuardadas.fromJson(Map<String, dynamic> json) {
    destino.lugar = new Position(
      latitude: json['Destino'].latitude,
      longitude: json['Destino'].longitude,
    );
    origen.lugar = new Position(
      latitude: json['Origen'].latitude,
      longitude: json['Origen'].longitude,
    );
    tipo = json['Tipo'];
    encodedPolyline = json['Encoded_Polyline'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Destino'] = this.destino;
    data['Origen'] = this.origen;
    data['Tipo'] = this.tipo;
    data['Encoded_Polyline'] = this.encodedPolyline;
    return data;
  }

  @override
  String toString() {
    return 'Origen: [${this.origen.toString()}] ' +
        'Destino: [${this.destino.toString()}] ' +
        'tipo: ${this.tipo} ' +
        'Encoded polyline: ${this.encodedPolyline} ';
  }
}
