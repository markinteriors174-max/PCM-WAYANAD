import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleAdminLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter email and password'),
        backgroundColor: AppColors.alertRed,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.adminLogin(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Admin Login Failed: ${e.toString().replaceAll('Exception:', '')}'),
          backgroundColor: AppColors.alertRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
              const Text('PCM ADMIN CONSOLE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.border)),
              const Text('Internal staff access only', style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 45),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: AppStyles.inputDecoration('Admin Email'),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: AppStyles.inputDecoration('Password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.border),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 35),
                    SizedBox(
                      height: 60,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleAdminLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.border,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('LOG IN AS ADMIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'v4.9 Admin Tools',
                style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
