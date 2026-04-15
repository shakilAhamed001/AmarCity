import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'edit_profile_screen.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({Key? key}) : super(key: key);

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  Map<String, dynamic> _address = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('profiles')
          .select('house_number, street_name, ward_number, city, state, postal_code, country')
          .eq('id', AuthService.currentUser!.id)
          .single();
      setState(() {
        _address = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  bool get _hasAddress =>
      (_address['house_number'] ?? '').isNotEmpty ||
      (_address['street_name'] ?? '').isNotEmpty ||
      (_address['city'] ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('My Address',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E40AF)),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const EditProfileScreen()),
              );
              _loadAddress();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasAddress
              ? _buildAddressCard()
              : _buildEmptyState(),
    );
  }

  Widget _buildAddressCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E40AF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.home_outlined,
                          color: Color(0xFF1E40AF), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('Home Address',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937))),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 20),
                _buildAddressRow(
                    Icons.home_outlined,
                    'House / Apartment',
                    _address['house_number'] ?? '-'),
                _buildAddressRow(
                    Icons.signpost_outlined,
                    'Street Name',
                    _address['street_name'] ?? '-'),
                _buildAddressRow(
                    Icons.grid_3x3_outlined,
                    'Ward Number',
                    _address['ward_number'] ?? '-'),
                _buildAddressRow(
                    Icons.location_city_outlined,
                    'City',
                    _address['city'] ?? '-'),
                _buildAddressRow(
                    Icons.map_outlined,
                    'State / Province',
                    _address['state'] ?? '-'),
                _buildAddressRow(
                    Icons.markunread_mailbox_outlined,
                    'Postal / ZIP Code',
                    _address['postal_code'] ?? '-'),
                _buildAddressRow(
                    Icons.flag_outlined,
                    'Country',
                    _address['country'] ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const EditProfileScreen()),
                );
                _loadAddress();
              },
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text('Edit Address',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_outlined,
              size: 64, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          const Text('No address saved yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          const Text('Add your address from Edit Profile',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const EditProfileScreen()),
              );
              _loadAddress();
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Address',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
