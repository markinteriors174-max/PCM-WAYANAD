import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../models/client_model.dart';
import 'worker_login_screen.dart';

class PortalLoginScreen extends StatefulWidget {
  const PortalLoginScreen({super.key});

  @override
  State<PortalLoginScreen> createState() => _PortalLoginScreenState();
}

class _PortalLoginScreenState extends State<PortalLoginScreen> {
  bool _isRegisterMode = true;
  bool _isLoading = false;
  String? _errorMsg;
  String? _generatedId;

  // Form Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _idSuffixCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateNewId();
  }

  void _generateNewId() {
    final random = Random();
    final suffix = (1000 + random.nextInt(9000)).toString();
    _idSuffixCtrl.text = suffix;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _idSuffixCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final phone = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    final suffix = _idSuffixCtrl.text.trim();

    if (phone.length != 10) {
      setState(() => _errorMsg = 'Enter a valid 10-digit phone number');
      return;
    }

    if (_isRegisterMode) {
      if (_nameCtrl.text.isEmpty || _locationCtrl.text.isEmpty) {
        setState(() => _errorMsg = 'Please fill all registration fields');
        return;
      }
    } else {
      if (suffix.length != 4) {
        setState(() => _errorMsg = 'Enter your 4-digit Project ID');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final unitNumber = 'pcm-ms-$suffix';
      
      if (_isRegisterMode) {
        final client = Client(
          id: unitNumber,
          clientName: _nameCtrl.text.trim(),
          phoneNumber: phone,
          siteLocation: _locationCtrl.text.trim(),
          unitNumber: unitNumber,
          clientSelfie: '',
          totalContractAmount: 0,
          advanceReceived: 0,
          totalLaborCost: 0,
          createdAt: DateTime.now(),
        );
        await ClientService.instance.addClient(client);
        
        if (mounted) {
          setState(() {
             _generatedId = unitNumber;
             _isLoading = false;
          });
        }
      } else {
        final client = await ClientService.instance.getAssignedClientByPhone(phone, unitNumber);
        if (client != null) {
          await AuthService.instance.loginAsWorker(unitNumber, client.clientName);
        } else {
          setState(() => _errorMsg = 'Invalid credentials. Check Phone & ID.');
        }
      }
    } catch (e) {
      setState(() => _errorMsg = 'Auth failed: $e');
    } finally {
      if (mounted && !_isRegisterMode) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_generatedId != null) return _buildSuccessScreen();

    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D11),
      body: Stack(
        children: [
          // Ambient LED Cove Lighting Effects
          Positioned(top: -100, left: -100, child: _ambientGlow(Colors.blue.withValues(alpha: 0.12), 400)),
          Positioned(bottom: -150, right: -100, child: _ambientGlow(const Color(0xFFD4AF37).withValues(alpha: 0.08), 500)),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Container(
                width: isWide ? 1150 : size.width * 0.95,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 60, spreadRadius: 10),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1.0),
                      ),
                      child: isWide ? _buildDesktopLayout() : _buildMobileLayout(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ambientGlow(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 180, spreadRadius: 60)]),
    );
  }

  Widget _buildDesktopLayout() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: _buildLeftPanel()),
          Expanded(flex: 5, child: _buildRightPanel()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        SizedBox(height: 380, child: _buildLeftPanel(isMobile: true)),
        _buildRightPanel(isMobile: true),
      ],
    );
  }

  Widget _buildLeftPanel({bool isMobile = false}) {
    return Container(
      decoration: BoxDecoration(
        border: isMobile ? null : const Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Seamless High-Res Interior Photo Background
          Image.network(
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80&w=1200',
            fit: BoxFit.cover,
          ),
          // Elegant Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft, end: Alignment.centerRight,
                colors: [Colors.black.withValues(alpha: 0.3), const Color(0xFF0D0D11).withValues(alpha: 0.9)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', height: 110, errorBuilder: (_, __, ___) => const Icon(Icons.architecture, size: 90, color: Color(0xFFD4AF37))),
                const SizedBox(height: 35),
                const Text(
                  'PCM WAYANAD',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 4),
                ),
                const Text(
                  'PREMIUM CEILING HUB',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 3),
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 45),
                  const Text(
                    'Exclusive Project Portal for Gypsum Ceilings & Premium Interior Works.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 15, fontWeight: FontWeight.w400, height: 1.6),
                  ),
                  const SizedBox(height: 55),
                  _buildTrustGalleryWidget(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustGalleryWidget() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined, color: Color(0xFFD4AF37), size: 18),
            SizedBox(width: 10),
            Text('TRUSTED BY 500+ CLIENTS', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _galleryItem('https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&q=80&w=200'),
            const SizedBox(width: 12),
            _galleryItem('https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&q=80&w=200'),
            const SizedBox(width: 12),
            _galleryItem('https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&q=80&w=200'),
          ],
        ),
      ],
    );
  }

  Widget _galleryItem(String url) {
    return Container(
      width: 90, height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover, opacity: 0.6),
      ),
    );
  }

  Widget _buildRightPanel({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 35 : 70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isRegisterMode ? 'NEW SITE REGISTRY' : 'CLIENT ACCESS',
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          Container(height: 4, width: 45, decoration: BoxDecoration(color: const Color(0xFFD4AF37), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 35),
          _buildModeToggle(),
          const SizedBox(height: 45),
          if (_errorMsg != null) _buildError(),
          _buildFormFields(),
          const SizedBox(height: 45),
          _buildActionButton(),
          const SizedBox(height: 30),
          if (!kIsWeb)
            Center(
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerLoginScreen())),
                child: const Text('WORKER PORTAL', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Expanded(child: _toggleBtn('ACCESS HUB', !_isRegisterMode, () {
            setState(() {
              _isRegisterMode = false;
              _errorMsg = null;
            });
          })),
          Expanded(child: _toggleBtn('NEW REGISTRY', _isRegisterMode, () {
            setState(() {
              _isRegisterMode = true;
              _errorMsg = null;
              _generateNewId();
            });
          })),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFD4AF37) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active ? [BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), blurRadius: 15)] : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: active ? Colors.black : Colors.white38, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.2)),
      ),
      child: Text(
        _errorMsg!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        if (_isRegisterMode) ...[
          _sleekInput('FULL NAME', _nameCtrl, Icons.person_outline),
          const SizedBox(height: 20),
          _sleekInput('LOCATION / PLACE', _locationCtrl, Icons.location_on_outlined),
          const SizedBox(height: 20),
        ],
        _sleekInput('PHONE NUMBER', _phoneCtrl, Icons.phone_outlined, inputType: TextInputType.phone),
        const SizedBox(height: 20),
        _idPrefixInput(),
      ],
    );
  }

  Widget _sleekInput(String label, TextEditingController ctrl, IconData icon, {TextInputType inputType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 10),
        TextField(
          controller: ctrl,
          keyboardType: inputType,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFFD4AF37).withValues(alpha: 0.4), size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.01),
            contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _idPrefixInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PROJECT CLIENT ID', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.01),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: const Color(0xFFD4AF37).withValues(alpha: 0.4), size: 20),
              const SizedBox(width: 18),
              const Text('pcm-ms-', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'monospace')),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _idSuffixCtrl,
                  readOnly: _isRegisterMode,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: TextStyle(
                    color: _isRegisterMode ? const Color(0xFFD4AF37).withValues(alpha: 0.6) : Colors.white, 
                    fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 8, fontFamily: 'monospace'
                  ),
                  decoration: const InputDecoration(
                    hintText: '####',
                    hintStyle: TextStyle(color: Colors.white10),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              if (_isRegisterMode) 
                IconButton(
                  onPressed: _generateNewId, 
                  icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37), size: 18),
                  tooltip: 'Generate New ID',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 25,
          shadowColor: const Color(0xFFD4AF37).withValues(alpha: 0.4),
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.black)
          : Text(_isRegisterMode ? 'INITIALIZE SITE REGISTRY' : 'LAUNCH PROJECT HUB', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D11),
      body: Center(
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(50),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFFD4AF37), size: 90),
              const SizedBox(height: 35),
              const Text('REGISTRY SUCCESSFUL', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 3)),
              const SizedBox(height: 20),
              const Text('Your system-generated Project Site ID is:', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(20), 
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3))
                ),
                child: Text(_generatedId!, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 10, fontFamily: 'monospace')),
              ),
              const SizedBox(height: 35),
              const Text('Please save this ID safely for future portal access.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton(
                  onPressed: () {
                    final unit = _generatedId!;
                    final name = _nameCtrl.text.trim();
                    setState(() => _generatedId = null);
                    AuthService.instance.loginAsWorker(unit, name);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text('LAUNCH PROJECT HUB', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
