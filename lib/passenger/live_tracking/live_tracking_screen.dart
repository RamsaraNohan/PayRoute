import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/services/realtime_db_service.dart';
import '../../core/theme/app_theme.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String busId;
  const LiveTrackingScreen({super.key, required this.busId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final RealtimeDBService _dbService = RealtimeDBService();
  
  Map<MarkerId, Marker> markers = {};
  StreamSubscription<DatabaseEvent>? _busStream;
  LatLng? _currentBusPos;

  @override
  void initState() {
    super.initState();
    _startListeningToBus();
  }

  void _startListeningToBus() {
    _busStream = _dbService.streamBusLocations().listen((event) async {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (data.containsKey(widget.busId)) {
          final busData = Map<String, dynamic>.from(data[widget.busId]);
          final double lat = busData['lat'];
          final double lng = busData['lng'];
          
          final pos = LatLng(lat, lng);
          _currentBusPos = pos;
          
          final marker = Marker(
            markerId: MarkerId(widget.busId),
            position: pos,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: 'Your Bus'),
          );

          setState(() {
            markers[MarkerId(widget.busId)] = marker;
          });

          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(CameraUpdate.newLatLng(pos));
        }
      }
    });
  }

  @override
  void dispose() {
    _busStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const kInitialPosition = CameraPosition(
      target: LatLng(7.0840, 80.0098), // Default Gampaha approx
      zoom: 14.4746,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        backgroundColor: AppTheme.backgroundDark,
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _currentBusPos != null ? CameraPosition(target: _currentBusPos!, zoom: 16) : kInitialPosition,
        markers: Set<Marker>.of(markers.values),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}
