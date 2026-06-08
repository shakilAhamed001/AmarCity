import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

// ProfileAvatarWidget — সব user এর profile picture দেখানো ও upload করার shared widget
class ProfileAvatarWidget extends StatefulWidget {
  final String userName;
  final double radius;
  final bool editable;

  const ProfileAvatarWidget({
    Key? key,
    required this.userName,
    this.radius = 44,
    this.editable = false,
  }) : super(key: key);

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> {
  String? _avatarUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  // profiles table থেকে avatar_url load করা
  Future<void> _loadAvatar() async {
    try {
      final data = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', AuthService.currentUser!.id)
          .single();
      if (mounted) setState(() => _avatarUrl = data['avatar_url'] as String?);
    } catch (_) {}
  }

  // Gallery থেকে image pick করে Supabase Storage এ upload করা
  Future<void> _pickAndUpload() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await image.readAsBytes();
      final userId = AuthService.currentUser!.id;
      final path = '$userId/avatar.jpg';

      // Supabase Storage এ upload — upsert true মানে আগেরটা replace হবে
      await supabase.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      // Public URL বানানো হচ্ছে — timestamp দিয়ে cache bust করা হচ্ছে
      final url = supabase.storage.from('avatars').getPublicUrl(path);
      final freshUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      // profiles table এ avatar_url save করা
      await supabase
          .from('profiles')
          .update({'avatar_url': freshUrl})
          .eq('id', userId);

      if (mounted) setState(() => _avatarUrl = freshUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.userName.isNotEmpty
        ? widget.userName[0].toUpperCase()
        : '?';

    // Avatar — url থাকলে image, না থাকলে নামের প্রথম অক্ষর
    final avatar = CircleAvatar(
      radius: widget.radius,
      backgroundColor: const Color(0xFF1E40AF),
      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
      child: _avatarUrl == null
          ? Text(
              initial,
              style: TextStyle(
                fontSize: widget.radius * 0.8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );

    if (!widget.editable) return avatar;

    // editable হলে camera icon overlay সহ দেখাবে
    return GestureDetector(
      onTap: _uploading ? null : _pickAndUpload,
      child: Stack(
        children: [
          avatar,
          if (_uploading)
            Positioned.fill(
              child: CircleAvatar(
                radius: widget.radius,
                backgroundColor: Colors.black38,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          // নিচে ডান কোণে camera icon
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFF1E40AF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
