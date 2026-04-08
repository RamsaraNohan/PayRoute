import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import '../../../models/route_model.dart';

class DriverTripScreen extends StatefulWidget {
  final String busId;
  final String routeId;

  const DriverTripScreen({
    super.key, 
    required this.busId, 
    required this.routeId
  });

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _tripStarted = false;
  bool _isLoading = true;
  RouteModel? _route;

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  Future<void> _loadRouteData() async {
    try {
      final routeDoc = await cf.FirebaseFirestore.instance.collection('routes').doc(widget.routeId).get();
      if (routeDoc.exists) {
        _route = RouteModel.fromMap(routeDoc.data()!, routeDoc.id);
        _createMapAssets();
      }
    } catch (e) {
      debugPrint('Error loading route: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _createMapAssets() {
    if (_route == null) return;

    // Create markers for each stop
    final Set<Marker> markers = {};
    final List<LatLng> polylinePoints = [];

    for (var stop in _route!.stops) {
      final pos = LatLng(stop.location.latitude, stop.location.longitude);
      polylinePoints.add(pos);
      
      markers.add(
        Marker(
          markerId: MarkerId(stop.stopId),
          position: pos,
          infoWindow: InfoWindow(title: stop.stopName, snippet: 'Stop #${stop.order}'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    }

    // Create polyline connecting stops
    final polyline = Polyline(
      polylineId: const PolylineId('route_path'),
      points: polylinePoints,
      color: AppTheme.purpleLight,
      width: 5,
    );

    setState(() {
      _markers = markers;
      _polylines = {polyline};
    });
  }

  void _toggleTrip() async {
    if (!_tripStarted) {
      // START TRIP
      await LocationService.startBusTracking(widget.busId);
      setState(() => _tripStarted = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip & Location Broadcasting Started')));
    } else {
      // END TRIP
      LocationService.stopTracking();
      setState(() => _tripStarted = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip Ended')));
    }
  }

  @override
  void dispose() {
    LocationService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final initialPos = _route != null && _route!.stops.isNotEmpty
        ? LatLng(_route!.stops[0].location.latitude, _route!.stops[0].location.longitude)
        : const LatLng(6.9271, 79.8612); // Colombo default

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initialPos, zoom: 14),
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            polylines: _polylines,
            style: _darkMapStyle, // Optional: Add a custom dark style later
          ),
          
          // Custom Overlay Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_route?.name ?? 'Assigned Route', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('Bus: ${widget.busId}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 24, left: 24, right: 24,
            child: Column(
              children: [
                if (_tripStarted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.radar, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text('LIVE BROADCASTING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _toggleTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tripStarted ? Colors.redAccent : AppTheme.purpleLight,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: (_tripStarted ? Colors.redAccent : AppTheme.purpleLight).withOpacity(0.5),
                  ),
                  child: Text(_tripStarted ? 'FINISH JOURNEY' : 'START JOURNEY'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // To implement dark map style: add the JSON here from Google Cloud Console
  final String? _darkMapStyle = null; 
}
