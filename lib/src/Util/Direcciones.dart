import 'package:geolocator/geolocator.dart';

class Direcciones {
  Position lugar;
  String direccion;

  Direcciones({
    this.lugar,
    this.direccion = '',
  });

  Future<void> positionToAddress() async {
    List<Placemark> listaLugares = await Geolocator().placemarkFromCoordinates(
      this.lugar.latitude,
      this.lugar.longitude,
      localeIdentifier: 'es_MX',
    );

    if (listaLugares.first.thoroughfare == '' &&
        listaLugares.first.subThoroughfare == '') {
      this.direccion =
          listaLugares.first.subLocality + ', ' + listaLugares.first.locality;
    } else {
      this.direccion = listaLugares.first.thoroughfare +
          ' ' +
          listaLugares.first.subThoroughfare;
    }
  }

  @override
  String toString() {
    return 'Lugar: ${this.lugar}, ' + 'Direccion: ${this.direccion}';
  }
}
