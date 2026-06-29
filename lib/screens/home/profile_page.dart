import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() => _isUploading = true);
      final bytes = await image.readAsBytes();
      final success = await AuthService.instance.updateProfilePhoto(bytes);
      
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Profile photo updated!' : 'Failed to update photo'),
            backgroundColor: success ? AppColors.resultGreen : AppColors.alertRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final user = AuthService.instance.userData;
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('USER PROFILE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            backgroundColor: AppColors.border,
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                          child: user?.photoUrl == null 
                            ? const Icon(Icons.person, size: 70, color: AppColors.border)
                            : null,
                        ),
                      ),
                      if (_isUploading)
                        const Positioned.fill(
                          child: CircularProgressIndicator(color: AppColors.border),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: const CircleAvatar(
                            backgroundColor: AppColors.border,
                            radius: 18,
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildInfoCard(
                  title: 'FULL NAME',
                  value: user?.name ?? 'Madhusudhan',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'PHONE NUMBER',
                  value: user?.phone ?? '9383406185',
                  icon: Icons.phone_android,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'BUSINESS NAME',
                  value: 'MARK GYPSUM',
                  icon: Icons.business,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'EMAIL ADDRESS',
                  value: user?.email ?? 'asmadhu299@gmail.com',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 40),
                const Text(
                  'PCM Project Management System',
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({required String title, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white),
      child: Row(
        children: [
          Icon(icon, color: AppColors.border),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w900)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.labelColor)),
            ],
          ),
        ],
      ),
    );
  }
}
