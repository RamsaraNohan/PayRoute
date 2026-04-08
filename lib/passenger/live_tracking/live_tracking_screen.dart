import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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
  final RealtimeDBService _dbService = RealtimeDBService();

  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _circleManager;
  CircleAnnotation? _busAnnotation;
  StreamSubscription<DatabaseEvent>? _busStream;
  // Cache the last known position so we can draw the marker once the map is ready
  Position? _lastKnownPos;

  @override
  void initState() {
    super.initState();
    _startListeningToBus();
  }

  void _startListeningToBus() {
    _busStream = _dbService.streamBusLocations().listen((event) async {
      if (event.snapshot.value == null) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      if (!data.containsKey(widget.busId)) return;

      final busData = Map<String, dynamic>.from(data[widget.busId] as Map);
      final double lat = (busData['lat'] as num).toDouble();
      final double lng = (busData['lng'] as num).toDouble();
      final pos = Position(lng, lat);
      _lastKnownPos = pos;

      await _drawOrUpdateMarker(pos);
    });
  }

  Future<void> _drawOrUpdateMarker(Position pos) async {
    if (_circleManager == null) return;
    final point = Point(coordinates: pos);
    if (_busAnnotation == null) {
      _busAnnotation = await _circleManager!.create(CircleAnnotationOptions(
        geometry: point,
        circleRadius: 14.0,
        circleColor: Colors.blueAccent.value,
        circleStrokeWidth: 3.0,
        circleStrokeColor: Colors.white.value,
      ));
    } else {
      _busAnnotation = _busAnnotation!.copyWith(CircleAnnotationOptions(geometry: point));
      await _circleManager!.update(_busAnnotation!);
    }

    await _mapboxMap?.flyTo(
      CameraOptions(center: point, zoom: 16.0),
      MapAnimationOptions(duration: 600),
    );
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    _circleManager = await map.annotations.createCircleAnnotationManager();
    // Draw the cached position immediately if we already received one before the map was ready
    if (_lastKnownPos != null) {
      await _drawOrUpdateMarker(_lastKnownPos!);
    }
  }

  @override
  void dispose() {
    _busStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        backgroundColor: AppTheme.backgroundDark,
      ),
      body: MapWidget(
        key: const ValueKey('liveTrackingMap'),
        onMapCreated: _onMapCreated,
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(80.0098, 7.0840)),
          zoom: 14.0,
        ),
        styleUri: MapboxStyles.DARK,
      ),
    );
  }
}
