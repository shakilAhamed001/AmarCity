import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/supabase_service.dart';
import '../complaint_tracking/complaint_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final String viewerRole;
  const MapScreen({Key? key, this.viewerRole = 'Citizen'}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;

  static const _dhakaCenter = LatLng(23.8103, 90.4125);

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('complaints')
          .select()
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _complaints = (data as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
    } catch (_) {}
  }

  Color _markerColor(String status) {
    switch (status) {
      case 'Resolved':    return Colors.green;
      case 'In progress': return Colors.orange;
      case 'Escalated':   return Colors.red;
      default:            return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = _complaints.map((c) {
      final lat = (c['latitude'] as num?)?.toDouble();
      final lng = (c['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final status = c['status'] as String? ?? 'New';
      final color = _markerColor(status);

      return Marker(
        point: LatLng(lat, lng),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ComplaintDetailScreen(
              complaint: c,
              viewerRole: widget.viewerRole,
            ),
          )),
          child: Tooltip(
            message: '${c['title'] ?? 'Complaint'}\n${c['category'] ?? ''} • $status',
            child: Icon(Icons.location_pin, color: color, size: 36),
          ),
        ),
      );
    }).whereType<Marker>().toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        title: const Text('Complaint Map',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComplaints,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _dhakaCenter,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.amarcity.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 12,
            left: 12,
            child: _buildLegend(),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _buildCountBadge(markers.length),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToMyLocation,
        backgroundColor: const Color(0xFF1E40AF),
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendItem(Colors.blue, 'New'),
          const SizedBox(height: 4),
          _legendItem(Colors.orange, 'In Progress'),
          const SizedBox(height: 4),
          _legendItem(Colors.green, 'Resolved'),
          const SizedBox(height: 4),
          _legendItem(Colors.red, 'Escalated'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF374151))),
      ],
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
      ),
      child: Text('$count complaints',
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
