import 'package:prueba_maps/src/Util/Direcciones.dart';

class ViajeProtegido {
  Direcciones origen = Direcciones();
  Direcciones destino = Direcciones();
  Direcciones actual = Direcciones();
  String nombreProtegido;
  String encodedPolyline;
  String horaInicio;
  String horaLlegada;
  bool enViaje = true;
  int tipo;

  ViajeProtegido(
      {this.tipo = 0,
      this.origen,
      this.destino,
      this.actual,
      this.nombreProtegido = '',
      this.encodedPolyline = '',
      this.enViaje,
      this.horaInicio = '',
      this.horaLlegada = ''});

  @override
  String toString() {
    return 'Nombre: ${this.nombreProtegido}\n' +
        'Tipo: ${this.tipo}\n' +
        'En viaje: ${this.enViaje}\n' +
        'Origen: ${this.origen}\n' +
        'Destino: ${this.destino}\n' +
        'Actual: ${this.actual}\n' +
        'Inicio: ${this.horaInicio}\n' +
        'Llegada: ${this.horaLlegada}\n' +
        'Encoded_polyline: ${this.encodedPolyline}\n';
  }
}
