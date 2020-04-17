import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapaCuidador extends StatefulWidget {
  MapaCuidador({Key key}) : super(key: key);

  @override
  _MapaCuidadorState createState() => _MapaCuidadorState();
}

class _MapaCuidadorState extends State<MapaCuidador> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: GoogleMap(initialCameraPosition: null),
    );
  }
}
