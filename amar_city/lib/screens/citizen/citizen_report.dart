// Flutter material design import
import 'package:flutter/material.dart';
// Image pick করার জন্য
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
// Database ও auth service
import '../../services/supabase_service.dart';

// CitizenReportScreen — নতুন complaint submit করার screen
class CitizenReportScreen extends StatefulWidget {
  const CitizenReportScreen({Key? key}) : super(key: key);

  @override
  State<CitizenReportScreen> createState() => _CitizenReportScreenState();
}

class _CitizenReportScreenState extends State<CitizenReportScreen> {
  // বর্তমানে selected category — শুরুতে ROAD
  String _selectedCategory = 'ROAD';
  // Form field controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController =
      TextEditingController(text: 'Dhaka');
  // Selected image files ও তাদের bytes
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _imageBytes = [];
  // Submit loading state
  bool _isLoading = false;

  // Available complaint categories
  final List<Map<String, dynamic>> _categories = [
    {'name': 'ROAD', 'label': 'Road', 'icon': Icons.warning_amber, 'color': Color(0xFFFCD34D)},
    {'name': 'LIGHTING', 'label': 'Lighting', 'icon': Icons.lightbulb_outline, 'color': Color(0xFFFCD34D)},
    {'name': 'GARBAGE', 'label': 'Garbage', 'icon': Icons.delete_outline, 'color': Color(0xFF6B7280)},
    {'name': 'DRAINAGE', 'label': 'Drainage', 'icon': Icons.water_drop_outlined, 'color': Color(0xFF3B82F6)},
    {'name': 'WATER', 'label': 'Water', 'icon': Icons.water_drop_outlined, 'color': Color(0xFF60A5FA)},
  ];

  @override
  void dispose() {
    // Memory leak এড়াতে controller dispose করা হচ্ছে
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Category অনুযায়ী কোন department এ complaint যাবে তা নির্ধারণ
  static const Map<String, String> _categoryDepartment = {
    'ROAD':     'Engineering Department',
    'LIGHTING': 'Engineering Department',
    'GARBAGE':  'Waste Management Department',
    'DRAINAGE': 'Waste Management Department',
    'WATER':    'Public Health & Sanitation Department',
    'OTHER':    'Engineering Department',
  };

  // Complaint submit করার function
  Future<void> _submitComplaint() async {
    // সব required field পূরণ হয়েছে কিনা check
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Supabase complaints table এ নতুন row insert করা হচ্ছে
      await supabase.from('complaints').insert({
        'citizen_id': AuthService.currentUser!.id,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'location': _locationController.text.trim(),
        'status': 'New', // নতুন complaint এর default status
        // Category অনুযায়ী department automatically set হচ্ছে
        'assigned_department': _categoryDepartment[_selectedCategory] ?? 'Engineering Department',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        // Submit হলে আগের screen এ ফিরে যাচ্ছে
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Photo source selection bottom sheet দেখানোর function
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Add Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                // Camera option
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E40AF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF1E40AF).withOpacity(0.2)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 36, color: Color(0xFF1E40AF)),
                          SizedBox(height: 8),
                          Text('Camera',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E40AF))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Gallery option
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF059669).withOpacity(0.2)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 36, color: Color(0xFF059669)),
                          SizedBox(height: 8),
                          Text('Gallery',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF059669))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Camera বা gallery থেকে image pick করার function
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      // Gallery থেকে multiple image select করা যাবে
      final images = await picker.pickMultiImage(
          maxWidth: 1000, maxHeight: 1000, imageQuality: 80);
      for (final img in images) {
        final bytes = await img.readAsBytes();
        setState(() {
          _selectedImages.add(img);
          _imageBytes.add(bytes);
        });
      }
    } else {
      // Camera থেকে একটি image তোলা হবে
      final image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1000,
          maxHeight: 1000,
          imageQuality: 80);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImages.add(image);
          _imageBytes.add(bytes);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Report an issue',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category selection
            _buildSectionTitle('ISSUE CATEGORY'),
            const SizedBox(height: 12),
            _buildCategorySelector(),
            const SizedBox(height: 24),
            // Issue title field
            _buildSectionTitle('ISSUE TITLE'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _titleController,
              hint: 'e.g. Large pothole causing accidents...',
            ),
            const SizedBox(height: 24),
            // Location field
            _buildSectionTitle('LOCATION'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _locationController,
              hint: 'e.g. Mirpur Road, Dhaka',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 24),
            // Description field — multiline
            _buildSectionTitle('DESCRIPTION'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descriptionController,
              hint: 'Describe the problem in detail...',
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            // Photo upload section
            _buildSectionTitle('PHOTO EVIDENCE'),
            const SizedBox(height: 12),
            _buildPhotoUploader(),
            const SizedBox(height: 32),
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                // Loading হলে spinner, না হলে text
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Submit complaint',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Section title widget — uppercase ধূসর text
  Widget _buildSectionTitle(String title) => Text(title,
      style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5));

  // Reusable text field widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    IconData icon = Icons.edit_outlined,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFB4B4B4), fontSize: 14),
        // Single line field এ icon দেখাবে, multiline এ না
        prefixIcon: maxLines == 1
            ? Icon(icon, color: const Color(0xFF1E40AF), size: 20)
            : null,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFF1E40AF), width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // Category selector — horizontally scrollable icon buttons
  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat['name'];
          final color = cat['color'] as Color;
          return GestureDetector(
            // tap করলে category select হবে
            onTap: () => setState(() => _selectedCategory = cat['name']),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      // selected হলে color background, না হলে white
                      color: isSelected
                          ? color.withOpacity(0.2)
                          : Theme.of(context).cardColor,
                      border: Border.all(
                          color: isSelected ? color : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat['icon'] as IconData,
                        color: color, size: 28),
                  ),
                  const SizedBox(height: 8),
                  // Category label
                  Text(cat['label'] as String,
                      style: TextStyle(
                          color: isSelected
                              ? color
                              : const Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Photo uploader widget — image না থাকলে placeholder, থাকলে grid দেখাবে
  Widget _buildPhotoUploader() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        // Image থাকলে বড়, না থাকলে ছোট height
        height: _selectedImages.isEmpty ? 140 : 200,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: _selectedImages.isEmpty
            // Image নেই — placeholder দেখাচ্ছে
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 40, color: Color(0xFF9CA3AF)),
                  SizedBox(height: 12),
                  Text('Tap to add photos',
                      style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Camera or Gallery',
                      style: TextStyle(
                          color: Color(0xFF9CA3AF), fontSize: 12)),
                ],
              )
            // Image আছে — grid এ দেখাচ্ছে
            : Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8),
                  // শেষে একটি '+' button থাকবে আরো image add করতে
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      // '+' button — আরো image add করতে
                      return GestureDetector(
                        onTap: _showImageSourceSheet,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Icon(Icons.add,
                              color: Color(0xFF9CA3AF)),
                        ),
                      );
                    }
                    // Image thumbnail — উপরে delete button সহ
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_imageBytes[index],
                              fit: BoxFit.cover),
                        ),
                        // Delete button — image remove করতে
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedImages.removeAt(index);
                              _imageBytes.removeAt(index);
                            }),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFDC2626),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}
