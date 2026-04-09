import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import '../../core/theme/app_theme.dart';
import '../complaint/complaint_screen.dart';
import '../check_in/check_in_screen.dart';

class ActiveTripScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;
  const ActiveTripScreen({super.key, required this.tripData});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _circleManager;
  CircleAnnotation? _busAnnotation;

  StreamSubscription<cf.DocumentSnapshot>? _busSubscription;
  String _busRegistration = 'Your Bus';
  Position? _initialPos;

  @override
  void initState() {
    super.initState();
    _listenToBus();
  }

  void _listenToBus() {
    final busId = widget.tripData['busId'] as String?;
    if (busId == null) return;

    _busSubscription = cf.FirebaseFirestore.instance
        .collection('buses')
        .doc(busId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final geo = data['currentLocation'] as cf.GeoPoint?;
      if (mounted) setState(() => _busRegistration = data['registrationNumber'] ?? busId);

      if (geo != null) {
        final pos = Position(geo.longitude, geo.latitude);
        _initialPos ??= pos;
        final point = Point(coordinates: pos);

        if (_circleManager != null) {
          if (_busAnnotation == null) {
            _busAnnotation = await _circleManager!.create(CircleAnnotationOptions(
              geometry: point,
              circleRadius: 14.0,
              circleColor: Colors.purpleAccent.value,
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
      }
    });
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;
    _circleManager = await map.annotations.createCircleAnnotationManager();
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default to Colombo if no position yet
    final center = _initialPos ?? Position(79.8612, 6.9271);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Live Journey', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white70),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ComplaintScreen(
                  tripId: widget.tripData['tripId'] ?? 'unknown',
                  busId: widget.tripData['busId'] ?? 'unknown',
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: Column(
            children: [
              // Journey Status Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassCard(),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.commute, color: Colors.greenAccent),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_busRegistration, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const Text('On-boarded successfully', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              // Live Mapbox Map
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5)
                    ],
                  ),
                  child: MapWidget(
                    key: const ValueKey('activeTripMap'),
                    onMapCreated: _onMapCreated,
                    cameraOptions: CameraOptions(
                      center: Point(coordinates: center),
                      zoom: 15.0,
                    ),
                    styleUri: MapboxStyles.DARK,
                  ),
                ),
              ),

              // Bottom Instructional Card
              Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.glassCard(),
                child: Column(
                  children: [
                    const Text(
                      'READY TO DROP?',
                      style: TextStyle(color: AppTheme.purpleLight, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please scan the Conductor\'s QR code one last time before you leave the bus to finalize your fare.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInScreen())),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('OPEN SCANNER'),
                      style: AppTheme.primaryButton(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
