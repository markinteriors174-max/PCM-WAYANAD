import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_updateState);
    _pinController.addListener(_updateState);
  }

  void _updateState() => setState(() {});

  @override
  void dispose() {
    _mobileController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_mobileController.text.isEmpty || _pinController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      debugPrint('LoginScreen: Attempting login for ${_mobileController.text}');
      await AuthService.instance.login(
        _mobileController.text.trim(),
        _pinController.text.trim(),
      );
    } catch (e) {
      debugPrint('LoginScreen: Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Login Failed: ${e.toString().replaceAll('Exception:', '')}'),
          backgroundColor: AppColors.alertRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isButtonEnabled => !_isLoading && _mobileController.text.isNotEmpty && _pinController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(35),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'pcm_logo',
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 180,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.architecture, size: 80, color: AppColors.border),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                kIsWeb ? 'PCM CLIENT PORTAL' : 'PCM ADMIN LOGIN', 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3, color: AppColors.border)
              ),
              Text(
                kIsWeb ? 'Enter your credentials to track your project' : 'Secure access for PCM staff', 
                style: const TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 45),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
                child: Column(
                  children: [
                    TextField(
                      controller: _mobileController,
                      decoration: AppStyles.inputDecoration('Mobile Number'),
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _pinController,
                      decoration: AppStyles.inputDecoration('SITE ID').copyWith(
                        prefixText: 'pcm-ms-',
                        prefixStyle: const TextStyle(color: AppColors.premiumGold, fontWeight: FontWeight.w900, letterSpacing: 1),
                        hintText: '8896',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.border, letterSpacing: 8),
                    ),
                    const SizedBox(height: 35),
                    SizedBox(
                      height: 60,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isButtonEnabled ? _handleLogin : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryButton,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primaryButton.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('LOG IN TO PORTAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (kIsWeb)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('New user? ', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                        );
                      },
                      child: const Text('REGISTER HERE', style: TextStyle(color: AppColors.border, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
