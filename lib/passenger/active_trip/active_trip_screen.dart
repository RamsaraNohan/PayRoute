import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final Completer<GoogleMapController> _mapController = Completer();
  StreamSubscription<cf.DocumentSnapshot>? _busSubscription;
  final Map<MarkerId, Marker> _markers = {};
  LatLng? _busPos;
  String _busRegistration = 'Your Bus';

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
      _busRegistration = data['registrationNumber'] ?? busId;

      if (geo != null) {
        final pos = LatLng(geo.latitude, geo.longitude);
        _busPos = pos;
        
        final marker = Marker(
          markerId: MarkerId(busId),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(title: _busRegistration),
        );

        if (mounted) {
          setState(() {
            _markers[MarkerId(busId)] = marker;
          });
          
          final c = await _mapController.future;
          c.animateCamera(CameraUpdate.newLatLng(pos));
        }
      }
    });
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

              // Live Google Map
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
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _busPos ?? const LatLng(6.9271, 79.8612),
                      zoom: 15,
                    ),
                    markers: Set<Marker>.of(_markers.values),
                    onMapCreated: (c) => _mapController.complete(c),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
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
