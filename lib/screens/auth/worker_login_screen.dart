import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class WorkerLoginScreen extends StatefulWidget {
  const WorkerLoginScreen({super.key});

  @override
  State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
}

class _WorkerLoginScreenState extends State<WorkerLoginScreen> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _idController.addListener(_updateState);
    _nameController.addListener(_updateState);
  }

  void _updateState() => setState(() {});

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_idController.text.isEmpty || _nameController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.loginAsWorker(
        _idController.text,
        _nameController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Failed: $e'), backgroundColor: AppColors.alertRed));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isButtonEnabled => !_isLoading && _idController.text.isNotEmpty && _nameController.text.isNotEmpty;

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
              const Icon(Icons.engineering, size: 80, color: AppColors.border),
              const SizedBox(height: 25),
              const Text('PCM WORKER PORTAL', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3, color: AppColors.border)),
              const Text('On-Site Management Login', style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 45),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: AppStyles.inputDecoration('Worker Name'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _idController,
                      decoration: AppStyles.inputDecoration('Employee ID'),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.border),
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
                          : const Text('ENTER PORTAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('ADMIN LOGIN', style: TextStyle(color: AppColors.border, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }
}
