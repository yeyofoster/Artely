import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

List<LatLng> decodeEncodedPolyline(String encoded) {
  List<LatLng> poly = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    LatLng p = new LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
    poly.add(p);
  }
  return poly;
}

String encodePolylineFromPoints(List<LatLng> coordinates, int precision) {
  if (coordinates.length == null) {
    return '';
  }

  int factor = pow(10, precision is int ? precision : 5);
  var output = _encode(coordinates.first.latitude, 0, factor) +
      _encode(coordinates.first.longitude, 0, factor);

  for (var i = 1; i < coordinates.length; i++) {
    var a = coordinates.elementAt(i), b = coordinates.elementAt(i - 1);
    output += _encode(a.latitude, b.latitude, factor);
    output += _encode(a.longitude, b.longitude, factor);
  }

  return output;
}

String _encode(double current, double previous, int factor) {
  final _current = (current * factor).round();
  final _previous = (previous * factor).round();

  var coordinate = _current - _previous;
  coordinate <<= 1;
  if (_current - _previous < 0) {
    coordinate = ~coordinate;
  }

  var output = '';
  while (coordinate >= 0x20) {
    output += String.fromCharCode((0x20 | (coordinate & 0x1f)) + 63);
    coordinate >>= 5;
  }
  output += String.fromCharCode(coordinate + 63);
  return output;
}
