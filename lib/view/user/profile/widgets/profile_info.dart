import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recycle_go/app/TextDesign.dart';
import 'package:recycle_go/app/app_theme.dart';
import 'package:recycle_go/services/storage_service.dart';
import 'package:intl/intl.dart';

class ProfileInfo extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final DateTime? createdAt;
  final String email;
  final String? phone;
  final String? countryCode;
  final Function(ImageSource) onPickImage;
  final VoidCallback onEditProfile;

  const ProfileInfo({
    super.key,
    required this.name,
    this.photoUrl,
    this.createdAt,
    required this.email,
    this.phone,
    this.countryCode,
    required this.onPickImage,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.color;
    final size = MediaQuery.of(context).size;
    final joinDate = createdAt != null ? DateFormat('MMM yyyy').format(createdAt!) : 'N/A';

    // Resolve URL: If it's just a file name, get the public URL from Supabase
    String resolvedUrl;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      if (photoUrl!.startsWith('http')) {
        resolvedUrl = photoUrl!;
      } else {
        resolvedUrl = StorageService().getPublicUrl('profiles', photoUrl!);
      }
    } else {
      // Use default image from profiles bucket if photoUrl is null or empty
      resolvedUrl = StorageService().getPublicUrl('profiles', 'userProfile/default.png');
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => _showImageSourceActionSheet(context),
          child: Stack(
            children: [
              CircleAvatar(
                radius: size.width * 0.15,
                backgroundColor: theme.surfaceVariant,
                backgroundImage: NetworkImage(resolvedUrl),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.surface, width: 2),
                  ),
                  child: Icon(Icons.camera_alt, size: size.width * 0.04, color: theme.onPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onEditProfile,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: TextDesign.headingOne(fontSize: size.width * 0.06),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined, size: size.width * 0.05, color: theme.primary),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Eco-Warrior since $joinDate',
          style: TextDesign.mediumText(color: theme.primary, fontSize: size.width * 0.035),
        ),
        const SizedBox(height: 12),
        _buildContactRow(Icons.email_outlined, email, size),
        _buildContactRow(Icons.phone_outlined, phone != null && phone!.isNotEmpty ? '${countryCode ?? ""} $phone' : 'Add phone number', size),
      ],
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                onPickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                onPickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, Size size) {
    final theme = AppThemes.color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: size.width * 0.04, color: theme.onHint),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextDesign.smallText(color: theme.onHint, fontSize: size.width * 0.035),
          ),
        ],
      ),
    );
  }
}
