import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong/latlong.dart' as latlong;
import 'package:flutter/services.dart';

const MAP2RADIUS = 0.4;

class GeofenceMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double radius;
  final Function onReady;
  final Function onChange;
  final Function onError;

  GeofenceMap({
    this.latitude,
    this.longitude,
    this.radius,
    this.onReady,
    this.onChange,
    this.onError,
  });

  @override
  _GeofenceMapState createState() => _GeofenceMapState();
}

class _GeofenceMapState extends State<GeofenceMap> {
  bool _locationReady = false;
  bool _mapReady = false;
  double _zoom;
  LatLng _location;
  double _radius;
  BitmapDescriptor _icon;
  GoogleMapController _mapController;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _locationReady ? Future.value(true) : _initLocation(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // initialization failed
          if (!snapshot.data) {
            return SizedBox.shrink();
          }

          final Set<Marker> _markers = {
            Marker(
              markerId: MarkerId('marker'),
              position: _location,
              icon: _icon,
            )
          };

          final Set<Circle> _circles = {
            Circle(
              circleId: CircleId('geofence'),
              center: _location,
              radius: _radius,
              fillColor: Theme.of(context).highlightColor.withOpacity(0.5),
              strokeWidth: 5,
              strokeColor: Theme.of(context).accentColor,
            )
          };

          return LayoutBuilder(builder: (context, constraints) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 50),
              height: constraints.maxWidth - 100,
              child: GoogleMap(
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                  new Factory<OneSequenceGestureRecognizer>(
                    () => new EagerGestureRecognizer(),
                  ),
                ].toSet(),
                circles: _circles,
                markers: _markers,
                mapToolbarEnabled: false,
                onCameraMove: (loc) async {
                  if (!_mapReady) {
                    return;
                  }
                  if (loc.zoom != _zoom) {
                    _zoom = loc.zoom;
                    LatLngBounds mapBounds =
                        await _mapController.getVisibleRegion();
                    double mapWidth = await Geolocator().distanceBetween(
                      mapBounds.northeast.latitude,
                      mapBounds.northeast.longitude,
                      mapBounds.northeast.latitude,
                      mapBounds.southwest.longitude,
                    );
                    _radius = mapWidth * MAP2RADIUS;
                  }
                  _location = loc.target;
                  setState(() {});
                },
                onTap: (val) async {
                  await _mapController
                      .animateCamera(CameraUpdate.newLatLng(val));
                  _location = val;
                },
                onMapCreated: (controller) async {
                  _mapController = controller;
                  // calculate boudaries from center and radius plus padding
                  var center = latlong.LatLng(
                    _location.latitude,
                    _location.longitude,
                  );
                  final distance = const latlong.Distance();
                  final center2corner = _radius / MAP2RADIUS * 0.707106781;
                  var northeast = distance.offset(center, center2corner, 45);
                  var southwest = distance.offset(center, center2corner, 225);
                  // want for map to finish initializing
                  await _mapController.getVisibleRegion();
                  await _mapController.animateCamera(
                    CameraUpdate.newLatLngBounds(
                      LatLngBounds(
                        northeast: LatLng(
                          northeast.latitude,
                          northeast.longitude,
                        ),
                        southwest: LatLng(
                          southwest.latitude,
                          southwest.longitude,
                        ),
                      ),
                      0,
                    ),
                  );
                  _mapReady = true;
                  if (widget.onReady != null) {
                    await widget.onReady(
                      _location.latitude,
                      _location.longitude,
                      _radius,
                    );
                  }
                },
                onCameraIdle: () {
                  setState(() {});
                  if (widget.onChange != null) {
                    return widget.onChange(
                        _location.latitude, _location.longitude, _radius);
                  } else {
                    return Future.value();
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: _location,
                  zoom: 15.0,
                ),
              ),
            );
          });
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              'Error Initializing Map: ${snapshot.error.toString()}',
              style: TextStyle(
                color: Theme.of(context).errorColor,
              ),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  Future<bool> _initLocation() async {
    if (widget.latitude != null && widget.longitude != null) {
      _location = LatLng(
        widget.latitude,
        widget.longitude,
      );
    } else {
      try {
        final location = await Geolocator().getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          locationPermissionLevel: GeolocationPermission.locationAlways,
        );
        _location = LatLng(
          location.latitude,
          location.longitude,
        );
      } on PlatformException catch (error) {
        await widget.onError(error.message);
        return Future.value(false);
      }
    }
    _radius = widget.radius ?? 200.00;
    final config =
        createLocalImageConfiguration(context, size: const Size(32, 44));
    _icon = await BitmapDescriptor.fromAssetImage(
      config,
      Platform.isAndroid
          ? 'assets/images/map-pin@1x.png'
          : 'assets/images/map-pin@3x.png',
    );
    _locationReady = true;
    return true;
  }

  Future<void> setLocation(LatLng location, bool reBuild) {
    setState(() {
      _location = location;
    });
    if (widget.onChange != null) {
      return widget.onChange(_location.latitude, _location.longitude, _radius);
    } else {
      return Future.value();
    }
  }
}
