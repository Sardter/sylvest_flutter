import 'dart:convert';

import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class UserRegion {
  final Location location = Location();
  LocationData? data;
  UserRegion();

  Future _determinePosition() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    _locationData = await location.getLocation();
    return _locationData;
  }

  Future _getLocationFromIP() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));
      final data = json.decode(response.body);
      print("getting location from ip");
      print(response);
      return LocationData.fromMap(
          {'latitude': data['lat'], 'longitude': data['lon']});
    } catch (exception) {
      print(exception);
      return null;
    }
  }

  void getCurrentLocation() async {
    data = await _determinePosition();
    if (data == null) {
      data = await _getLocationFromIP();
    }
  }

  String? getLatLng() {
    if (data == null) return null;
    print('${data!.latitude!},${data!.longitude!}');
    return '${data!.latitude!},${data!.longitude!}';
  }

  String getLat() {
    return '${data!.latitude!}';
  }

  String getLng() {
    return '${data!.longitude!}';
  }
}
