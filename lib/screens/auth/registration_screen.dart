import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  late String _preGeneratedPin;

  @override
  void initState() {
    super.initState();
    _preGeneratedPin = (1000 + (DateTime.now().millisecond % 900) + (DateTime.now().second * 10)).toString().padLeft(4, '0');
    // Ensure it's exactly 4 digits
    if (_preGeneratedPin.length > 4) _preGeneratedPin = _preGeneratedPin.substring(0, 4);
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: AppColors.alertRed),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final unitNumber = await context.read<AuthService>().registerGuest(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        manualPin: _preGeneratedPin,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (unitNumber != null) {
          final savedName = _nameController.text.trim();
          final savedPhone = _phoneController.text.trim();
          final savedLocation = _locationController.text.trim();

          // Clear inputs on success
          _nameController.clear();
          _phoneController.clear();
          _locationController.clear();

          _showSuccessDialog(
            fullId: unitNumber,
            name: savedName,
            phone: savedPhone,
            location: savedLocation,
          );
        } else {
          // This should not happen as registerGuest rethrows, but for safety:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration failed. Please try again.'), backgroundColor: AppColors.alertRed),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Display the ACTUAL error returned by Supabase
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SYSTEM ERROR: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.alertRed,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
          ),
        );
      }
    }
  }

  void _showSuccessDialog({
    required String fullId,
    required String name,
    required String phone,
    required String location,
  }) {
    // Extract just the 4 digits (hide pcm-ms- prefix)
    final fourDigits = fullId.contains('-') ? fullId.split('-').last : fullId;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: const BorderSide(color: AppColors.border, width: 3)),
        backgroundColor: Colors.white,
        title: const Text('REGISTRATION SUCCESSFUL', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.resultGreen, size: 70),
            const SizedBox(height: 25),
            const Text('YOUR UNIQUE 4-DIGIT PIN IS:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black45, fontSize: 11, letterSpacing: 1)),
            const SizedBox(height: 15),
            
            // ULTRA BOLD PIN DISPLAY
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
              ),
              child: Text(
                fourDigits,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 56, 
                  fontWeight: FontWeight.w900, 
                  color: AppColors.border, 
                  letterSpacing: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 25),
            _buildDetailRow('REGISTERED NAME', name),
            _buildDetailRow('MOBILE NUMBER', phone),
            const Divider(height: 40),
            const Text('PLEASE SAVE THIS PIN TO LOGIN LATER', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.alertRed, fontWeight: FontWeight.w900)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to welcome screen (or auto-login)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.border, 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('ENTER MY PORTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey)),
          Text(value.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.border)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NEW CLIENT REGISTRATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: AppColors.border,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Icon(Icons.person_add_outlined, size: 80, color: AppColors.border),
            const SizedBox(height: 20),
            const Text(
              'Welcome to PCM Wayanad.\nRegister to track your ceiling project live.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(25),
              decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: AppStyles.inputDecoration('Full Name'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _phoneController,
                    decoration: AppStyles.inputDecoration('Mobile Number'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _locationController,
                    decoration: AppStyles.inputDecoration('Site Location'),
                  ),
                  const SizedBox(height: 35),
                  
                  // DYNAMIC PIN DISPLAY AREA
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YOUR UNIQUE PIN:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
                            Text('AUTO-GENERATED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.border)),
                          ],
                        ),
                        Text(
                          'pcm-ms-$_preGeneratedPin',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.premiumGold, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.border,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('REGISTER & GET ID', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
