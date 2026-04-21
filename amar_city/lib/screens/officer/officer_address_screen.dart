import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'officer_edit_profile_screen.dart';

class OfficerAddressScreen extends StatefulWidget {
  const OfficerAddressScreen({Key? key}) : super(key: key);

  @override
  State<OfficerAddressScreen> createState() => _OfficerAddressScreenState();
}

class _OfficerAddressScreenState extends State<OfficerAddressScreen> {
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
          .select(
              'house_number, street_name, ward_number, city, state, postal_code, country')
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('My Address',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E40AF)),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const OfficerAddressEditScreen()));
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
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
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
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                _buildRow(Icons.home_outlined, 'House / Apartment',
                    _address['house_number'] ?? '-'),
                _buildRow(Icons.signpost_outlined, 'Street Name',
                    _address['street_name'] ?? '-'),
                _buildRow(Icons.grid_3x3_outlined, 'Ward Number',
                    _address['ward_number'] ?? '-'),
                _buildRow(Icons.location_city_outlined, 'City',
                    _address['city'] ?? '-'),
                _buildRow(Icons.map_outlined, 'State / Province',
                    _address['state'] ?? '-'),
                _buildRow(Icons.markunread_mailbox_outlined, 'Postal / ZIP',
                    _address['postal_code'] ?? '-'),
                _buildRow(Icons.flag_outlined, 'Country',
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
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const OfficerAddressEditScreen()));
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

  Widget _buildRow(IconData icon, String label, String value) {
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
                        fontSize: 14, fontWeight: FontWeight.w500)),
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
          const Text('Tap the button below to add your address',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const OfficerAddressEditScreen()));
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

// ── Address Edit Screen ──────────────────────────────────────────────────────

class OfficerAddressEditScreen extends StatefulWidget {
  const OfficerAddressEditScreen({Key? key}) : super(key: key);

  @override
  State<OfficerAddressEditScreen> createState() =>
      _OfficerAddressEditScreenState();
}

class _OfficerAddressEditScreenState extends State<OfficerAddressEditScreen> {
  late TextEditingController _houseController;
  late TextEditingController _streetController;
  late TextEditingController _wardController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalController;
  late TextEditingController _countryController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _houseController = TextEditingController();
    _streetController = TextEditingController();
    _wardController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postalController = TextEditingController();
    _countryController = TextEditingController(text: 'Bangladesh');
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    try {
      final data = await supabase
          .from('profiles')
          .select(
              'house_number, street_name, ward_number, city, state, postal_code, country')
          .eq('id', AuthService.currentUser!.id)
          .single();
      setState(() {
        _houseController.text = data['house_number'] ?? '';
        _streetController.text = data['street_name'] ?? '';
        _wardController.text = data['ward_number'] ?? '';
        _cityController.text = data['city'] ?? '';
        _stateController.text = data['state'] ?? '';
        _postalController.text = data['postal_code'] ?? '';
        _countryController.text = data['country'] ?? 'Bangladesh';
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _houseController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await supabase.from('profiles').update({
        'house_number': _houseController.text.trim(),
        'street_name': _streetController.text.trim(),
        'ward_number': _wardController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'postal_code': _postalController.text.trim(),
        'country': _countryController.text.trim(),
      }).eq('id', AuthService.currentUser!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address saved successfully')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Edit Address',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: Color(0xFF1E40AF),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField('HOUSE / APARTMENT NUMBER', _houseController,
                Icons.home_outlined, 'e.g. House 12, Apt 3B'),
            const SizedBox(height: 16),
            _buildField('STREET NAME', _streetController,
                Icons.signpost_outlined, 'e.g. Mirpur Road'),
            const SizedBox(height: 16),
            _buildField('WARD NUMBER', _wardController,
                Icons.grid_3x3_outlined, 'e.g. Ward 12',
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _buildField('CITY', _cityController,
                      Icons.location_city_outlined, 'e.g. Dhaka')),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildField('STATE / PROVINCE', _stateController,
                      Icons.map_outlined, 'e.g. Dhaka Division')),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _buildField(
                      'POSTAL / ZIP CODE', _postalController,
                      Icons.markunread_mailbox_outlined, 'e.g. 1216',
                      keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildField('COUNTRY', _countryController,
                      Icons.flag_outlined, 'e.g. Bangladesh')),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Address',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      IconData icon, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFF999999), fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF1E40AF), size: 18),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFF1E40AF), width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
