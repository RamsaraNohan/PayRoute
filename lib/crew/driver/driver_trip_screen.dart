import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import '../../../models/route_model.dart';

class DriverTripScreen extends StatefulWidget {
  final String busId;
  final String routeId;

  const DriverTripScreen({
    super.key,
    required this.busId,
    required this.routeId,
  });

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _circleManager;
  PolylineAnnotationManager? _polylineManager;

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
      final routeDoc = await cf.FirebaseFirestore.instance
          .collection('routes')
          .doc(widget.routeId)
          .get();
      if (routeDoc.exists) {
        _route = RouteModel.fromMap(routeDoc.data()!, routeDoc.id);
      }
    } catch (e) {
      debugPrint('Error loading route: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createMapAssets() async {
    if (_route == null || _mapboxMap == null) return;

    _circleManager ??= await _mapboxMap!.annotations.createCircleAnnotationManager();
    _polylineManager ??= await _mapboxMap!.annotations.createPolylineAnnotationManager();

    final List<Position> positions = _route!.stops
        .map((s) => Position(s.location.longitude, s.location.latitude))
        .toList();

    // Draw stop markers
    for (final stop in _route!.stops) {
      await _circleManager!.create(CircleAnnotationOptions(
        geometry: Point(coordinates: Position(stop.location.longitude, stop.location.latitude)),
        circleRadius: 10.0,
        circleColor: AppTheme.purpleLight.value,
        circleStrokeWidth: 2.0,
        circleStrokeColor: Colors.white.value,
      ));
    }

    // Draw route polyline
    if (positions.length >= 2) {
      await _polylineManager!.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: positions),
        lineColor: AppTheme.purpleLight.value,
        lineWidth: 5.0,
      ));
    }
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    await _createMapAssets();
  }

  void _toggleTrip() async {
    if (!_tripStarted) {
      await LocationService.startBusTracking(widget.busId);
      if (mounted) setState(() => _tripStarted = true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip & Location Broadcasting Started')));
    } else {
      LocationService.stopTracking();
      if (mounted) setState(() => _tripStarted = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip Ended')));
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
        ? Position(_route!.stops[0].location.longitude, _route!.stops[0].location.latitude)
        : Position(79.8612, 6.9271); // Colombo default

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('driverTripMap'),
            onMapCreated: _onMapCreated,
            cameraOptions: CameraOptions(
              center: Point(coordinates: initialPos),
              zoom: 14.0,
            ),
            styleUri: MapboxStyles.DARK,
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
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
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
                    shadowColor: (_tripStarted ? Colors.redAccent : AppTheme.purpleLight).withValues(alpha: 0.5),
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
}
