import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../widgets/profile_avatar_widget.dart';

// EditProfileScreen — Citizen এর profile ও address edit করার screen
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Personal info controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  // Address field controllers
  late TextEditingController _houseController;
  late TextEditingController _streetController;
  late TextEditingController _wardController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalController;
  late TextEditingController _countryController;
  // Save loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Current user এর info দিয়ে controllers initialize করা হচ্ছে
    final user = AuthService.currentUser;
    _nameController = TextEditingController(
        text: user?.userMetadata?['full_name'] ?? '');
    // Email read-only — এখানে change করা যাবে না
    _emailController = TextEditingController(text: user?.email ?? '');
    // Address controllers শুরুতে empty — database থেকে load হবে
    _houseController = TextEditingController();
    _streetController = TextEditingController();
    _wardController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postalController = TextEditingController();
    // Default country Bangladesh
    _countryController = TextEditingController(text: 'Bangladesh');
    // Database থেকে saved address load করা হচ্ছে
    _loadAddress();
  }

  // Supabase profiles table থেকে address fields load করার function
  Future<void> _loadAddress() async {
    try {
      // শুধু address related fields আনা হচ্ছে — current user এর জন্য
      final data = await supabase
          .from('profiles')
          .select('house_number, street_name, ward_number, city, state, postal_code, country')
          .eq('id', AuthService.currentUser!.id)
          .single();
      // Database থেকে আনা data দিয়ে controllers update করা হচ্ছে
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
    // Memory leak এড়াতে সব controller dispose করা হচ্ছে
    _nameController.dispose();
    _emailController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _wardController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // Profile save করার function
  Future<void> _saveProfile() async {
    // নাম empty হলে save করা যাবে না
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Supabase auth metadata তে full_name update করা হচ্ছে
      await supabase.auth.updateUser(
        UserAttributes(data: {'full_name': _nameController.text.trim()}),
      );
      // profiles table এ নাম ও address update করা হচ্ছে
      await supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
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
          const SnackBar(content: Text('Profile updated successfully')),
        );
        // true return করে জানানো হচ্ছে যে profile update হয়েছে
        // Parent screen এ এই value দিয়ে UI refresh করা যাবে
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      // সব ক্ষেত্রে loading বন্ধ করা হচ্ছে
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Avatar এ নামের প্রথম অক্ষর দেখানোর জন্য
    final userName = _nameController.text;
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
        title: const Text('Edit Profile',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          // AppBar এ Save button — loading চলাকালীন disable
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
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
            const SizedBox(height: 8),
            // Profile picture — editable true, tap করলে photo change করা যাবে
            Center(
              child: ProfileAvatarWidget(
                userName: _nameController.text,
                radius: 50,
                editable: true,
              ),
            ),
            const SizedBox(height: 32),

            // Personal Info section
            _buildSectionTitle('PERSONAL INFO'),
            const SizedBox(height: 12),
            // Full name field — editable
            _buildField(
              label: 'FULL NAME',
              controller: _nameController,
              icon: Icons.person_outline,
              hint: 'Enter your full name',
            ),
            const SizedBox(height: 16),
            // Email field — read-only, change করা যাবে না
            _buildField(
              label: 'EMAIL ADDRESS',
              controller: _emailController,
              icon: Icons.email_outlined,
              hint: 'Email address',
              readOnly: true,
            ),
            const SizedBox(height: 4),
            // Email read-only এর কারণ জানানো হচ্ছে
            const Text('Email cannot be changed here.',
                style: TextStyle(fontSize: 11, color: Colors.grey)),

            const SizedBox(height: 28),

            // Address section
            _buildSectionTitle('ADDRESS'),
            const SizedBox(height: 12),
            _buildField(
              label: 'HOUSE / APARTMENT NUMBER',
              controller: _houseController,
              icon: Icons.home_outlined,
              hint: 'e.g. House 12, Apt 3B',
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'STREET NAME',
              controller: _streetController,
              icon: Icons.signpost_outlined,
              hint: 'e.g. Mirpur Road',
            ),
            const SizedBox(height: 16),
            // Ward number — numeric keyboard
            _buildField(
              label: 'WARD NUMBER',
              controller: _wardController,
              icon: Icons.grid_3x3_outlined,
              hint: 'e.g. Ward 12',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            // City ও State — পাশাপাশি দুটি field
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'CITY',
                    controller: _cityController,
                    icon: Icons.location_city_outlined,
                    hint: 'e.g. Dhaka',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    label: 'STATE / PROVINCE',
                    controller: _stateController,
                    icon: Icons.map_outlined,
                    hint: 'e.g. Dhaka Division',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Postal code ও Country — পাশাপাশি দুটি field
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'POSTAL / ZIP CODE',
                    controller: _postalController,
                    icon: Icons.markunread_mailbox_outlined,
                    hint: 'e.g. 1216',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    label: 'COUNTRY',
                    controller: _countryController,
                    icon: Icons.flag_outlined,
                    hint: 'e.g. Bangladesh',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            // Bottom Save Changes button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                // Loading হলে spinner, না হলে text
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Section title widget — নীল রঙে uppercase text
  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E40AF),
            letterSpacing: 0.5));
  }

  // Reusable form field widget — label, icon, hint ও optional readOnly সহ
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field label — uppercase ছোট text
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFF999999), fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF1E40AF), size: 18),
            filled: true,
            // Read-only field এর background আলাদা রঙ — edit করা যাবে না বোঝাতে
            fillColor:
                readOnly ? const Color(0xFFEEEEEE) : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            // Focus হলে নীল border দেখাবে
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
