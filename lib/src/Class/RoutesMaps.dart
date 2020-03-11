import 'Routes.dart';

class RoutesMaps {
  List<GeocodedWaypoints> geocodedWaypoints;
  List<Routes> routes;
  String status;

  RoutesMaps({this.geocodedWaypoints, this.routes, this.status});

  RoutesMaps.fromJson(Map<String, dynamic> json) {
    if (json['geocoded_waypoints'] != null) {
      geocodedWaypoints = new List<GeocodedWaypoints>();
      json['geocoded_waypoints'].forEach((v) {
        geocodedWaypoints.add(new GeocodedWaypoints.fromJson(v));
      });
    }
    if (json['routes'] != null) {
      routes = new List<Routes>();
      json['routes'].forEach((v) {
        routes.add(new Routes.fromJson(v));
      });
    }
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.geocodedWaypoints != null) {
      data['geocoded_waypoints'] =
          this.geocodedWaypoints.map((v) => v.toJson()).toList();
    }
    if (this.routes != null) {
      data['routes'] = this.routes.map((v) => v.toJson()).toList();
    }
    data['status'] = this.status;
    return data;
  }
}

class GeocodedWaypoints {
  String geocoderStatus;
  String placeId;
  List<String> types;

  GeocodedWaypoints({this.geocoderStatus, this.placeId, this.types});

  GeocodedWaypoints.fromJson(Map<String, dynamic> json) {
    geocoderStatus = json['geocoder_status'];
    placeId = json['place_id'];
    types = json['types'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['geocoder_status'] = this.geocoderStatus;
    data['place_id'] = this.placeId;
    data['types'] = this.types;
    return data;
  }
}