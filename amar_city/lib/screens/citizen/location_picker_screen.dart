import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  final String initialLocation;
  const LocationPickerScreen({Key? key, this.initialLocation = ''})
      : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _pickedLatLng = const LatLng(23.8103, 90.4125);
  bool _hasPicked = false;
  bool _locating = true;
  final _searchController = TextEditingController();
  final _mapController = MapController();

  static const _quickAreas = [
    ('Mirpur, Dhaka', LatLng(23.8223, 90.3654)),
    ('Dhanmondi, Dhaka', LatLng(23.7461, 90.3742)),
    ('Gulshan, Dhaka', LatLng(23.7925, 90.4078)),
    ('Uttara, Dhaka', LatLng(23.8759, 90.3795)),
    ('Motijheel, Dhaka', LatLng(23.7337, 90.4176)),
    ('Mohammadpur, Dhaka', LatLng(23.7644, 90.3584)),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation.isNotEmpty) {
      _searchController.text = widget.initialLocation;
    }
    _goToCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (mounted) setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10)));
      if (!mounted) return;
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _pickedLatLng = latlng;
        _locating = false;
      });
      _mapController.move(latlng, 15);
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onMapTap(TapPosition _, LatLng latlng) {
    setState(() {
      _pickedLatLng = latlng;
      _hasPicked = true;
      _searchController.text =
          '${latlng.latitude.toStringAsFixed(5)}, ${latlng.longitude.toStringAsFixed(5)}';
    });
  }

  void _selectQuickArea(String name, LatLng latlng) {
    setState(() {
      _pickedLatLng = latlng;
      _hasPicked = true;
      _searchController.text = name;
    });
    _mapController.move(latlng, 15);
  }

  void _confirm() {
    final text = _searchController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or type a location')),
      );
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        title: const Text('Pick Location',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text('Confirm',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Type location or tap on map...',
                hintStyle:
                    const TextStyle(color: Color(0xFFB4B4B4), fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF1E40AF), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Color(0xFF9CA3AF), size: 18),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _hasPicked = false;
                        }),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF1E40AF), width: 1.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Quick area chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickAreas.map((area) {
                  final isSelected = _searchController.text == area.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _selectQuickArea(area.$1, area.$2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1E40AF)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1E40AF)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          area.$1.split(',').first,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _pickedLatLng,
                    initialZoom: 13,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.amarcity.app',
                    ),
                    if (_hasPicked)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pickedLatLng,
                            width: 48,
                            height: 48,
                            child: const Icon(Icons.location_pin,
                                color: Color(0xFFDC2626), size: 48),
                          ),
                        ],
                      ),
                    if (!_hasPicked && !_locating)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pickedLatLng,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF3B82F6)
                                          .withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2)
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_locating)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 8),
                            Text('আপনার অবস্থান খুঁজছে...',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 80,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: _goToCurrentLocation,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location,
                        color: Color(0xFF1E40AF)),
                  ),
                ),
                if (!_hasPicked && !_locating)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '📍 Tap on map to pin location',
                          style:
                              TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom confirm bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 20),
                label: Text(
                  _searchController.text.isNotEmpty
                      ? 'Use: ${_searchController.text}'
                      : 'Confirm Location',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
