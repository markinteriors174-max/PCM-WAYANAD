import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _companyNameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _aboutUsController = TextEditingController();
  final _disclaimerController = TextEditingController();
  final _termsController = TextEditingController();
  
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _profitMarginController = TextEditingController();
  final _securityPinController = TextEditingController();
  
  bool _isLoading = true;
  String? _signaturePath;
  String? _sealPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyNameController.text = prefs.getString('company_name') ?? 'PCM WAYANAD';
      _taglineController.text = prefs.getString('company_tagline') ?? 'Magic of Interiors';
      _aboutUsController.text = prefs.getString('company_about_us') ?? "At PCM Wayanad, we don't just build ceilings; we elevate the elegance of your interior spaces. With over a decade of expertise, we blend premium quality materials with artistic precision to craft ceilings that define luxury and durability.";
      _disclaimerController.text = prefs.getString('company_disclaimer') ?? 'Please note: This quotation is for ceiling works only. Painting and electrical works are not included.';
      _termsController.text = prefs.getString('company_terms') ?? '1. Quotation is valid for 30 days.\n2. 50% advance payment required before work commences.\n3. Final payment due immediately upon completion.';
      
      _bankNameController.text = prefs.getString('bank_name') ?? '';
      _accountNameController.text = prefs.getString('bank_account_name') ?? '';
      _accountNumberController.text = prefs.getString('bank_account_number') ?? '';
      _ifscController.text = prefs.getString('bank_ifsc') ?? '';
      _upiIdController.text = prefs.getString('bank_upi_id') ?? '';
      _profitMarginController.text = (prefs.getDouble('profit_margin') ?? 42.09).toStringAsFixed(2);
      _securityPinController.text = prefs.getString('security_pin') ?? '2025';
      
      _signaturePath = prefs.getString('signature_path');
      _sealPath = prefs.getString('seal_path');
      
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_name', _companyNameController.text.trim());
    await prefs.setString('company_tagline', _taglineController.text.trim());
    await prefs.setString('company_about_us', _aboutUsController.text.trim());
    await prefs.setString('company_disclaimer', _disclaimerController.text.trim());
    await prefs.setString('company_terms', _termsController.text.trim());
    
    await prefs.setString('bank_name', _bankNameController.text.trim());
    await prefs.setString('bank_account_name', _accountNameController.text.trim());
    await prefs.setString('bank_account_number', _accountNumberController.text.trim());
    await prefs.setString('bank_ifsc', _ifscController.text.trim().toUpperCase());
    await prefs.setString('bank_upi_id', _upiIdController.text.trim());
    await prefs.setString('security_pin', _securityPinController.text.trim());
    
    final margin = double.tryParse(_profitMarginController.text.trim()) ?? 42.09;
    await prefs.setDouble('profit_margin', margin);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Settings saved successfully!'), backgroundColor: AppColors.resultGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Company & Bank Settings', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: AppColors.border,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveSettings),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('BRANDING & COMPANY'),
              _buildTextField('Company Name', _companyNameController, required: true),
              _buildTextField('Tagline / Subtitle', _taglineController),
              _buildTextField('About Us / Vision (10 Years Exp)', _aboutUsController, maxLines: 3),
              
              const SizedBox(height: 30),
              _buildSectionTitle('LEGAL & TERMS'),
              _buildTextField('Disclaimer (e.g. No painting/electrical)', _disclaimerController, maxLines: 2),
              _buildTextField('Terms & Conditions (Validity, etc)', _termsController, maxLines: 3),
              
              const SizedBox(height: 30),
              _buildSectionTitle('BANKING DETAILS'),
              _buildTextField('Bank Name', _bankNameController),
              _buildTextField('Account Holder Name', _accountNameController),
              _buildTextField('Account Number', _accountNumberController, keyboardType: TextInputType.number),
              _buildTextField('IFSC Code', _ifscController),
              
              const SizedBox(height: 30),
              _buildSectionTitle('UPI PAYMENTS'),
              _buildTextField('UPI ID', _upiIdController),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('A QR code will automatically be generated for this UPI ID on the PDF.', style: TextStyle(color: Colors.black54, fontSize: 10, fontStyle: FontStyle.italic)),
              ),
              
              const SizedBox(height: 30),
              _buildSectionTitle('PROFIT-PROTECTION SETTINGS'),
              _buildTextField('Fixed Labor & Profit Margin (₹ / SqFt)', _profitMarginController, keyboardType: TextInputType.number, required: true),
              
              const SizedBox(height: 30),
              _buildSectionTitle('SECURITY & PDF AUTHORIZATION'),
              _buildTextField('Digital Signature PIN (4 Digits)', _securityPinController, keyboardType: TextInputType.number, required: true),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('This PIN is required to enable the "Include Digital Signature" toggle in the calculator.', style: TextStyle(color: Colors.black54, fontSize: 10, fontStyle: FontStyle.italic)),
              ),
              
              const SizedBox(height: 30),
              _buildSectionTitle('SIGNATURE & COMPANY SEAL'),
              _buildImageUploadFields(),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _saveSettings,
                  child: const Text('SAVE SETTINGS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadFields() {
    return Row(
      children: [
        Expanded(child: _buildUploadCard('Signature', _signaturePath, true)),
        const SizedBox(width: 15),
        Expanded(child: _buildUploadCard('Official Seal', _sealPath, false)),
      ],
    );
  }

  Widget _buildUploadCard(String label, String? path, bool isSignature) {
    // Simplified for Web compatibility - local disk images only show on mobile
    final bool hasImage = !kIsWeb && path != null && path.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppStyles.neumorphicDecoration(color: Colors.white, hasThickBorder: true),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.border, letterSpacing: 1.2)),
          const SizedBox(height: 15),
          if (hasImage) ...[
            const Icon(Icons.check_circle, color: AppColors.resultGreen, size: 40),
            const SizedBox(height: 15),
            Text('Saved on Device', style: TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 15),
          ] else ...[
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.image, color: Colors.black26, size: 30),
            ),
            const SizedBox(height: 15),
          ],
          if (!kIsWeb)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButton,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _pickImage(isSignature),
                icon: const Icon(Icons.upload, color: Colors.white, size: 16),
                label: Text(
                  hasImage ? 'CHANGE' : 'UPLOAD',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage(bool isSignature) async {
    if (kIsWeb) return;
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      // On mobile, we still use SharedPreferences to store the path
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(isSignature ? 'signature_path' : 'seal_path', image.path);
      
      setState(() {
        if (isSignature) {
          _signaturePath = image.path;
        } else {
          _sealPath = image.path;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isSignature ? "Signature" : "Seal"} uploaded successfully!'),
            backgroundColor: AppColors.resultGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.border, letterSpacing: 1.5, fontSize: 14)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        decoration: AppStyles.inputDecoration(label),
        validator: required ? (v) => v!.isEmpty ? 'This field is required' : null : null,
      ),
    );
  }
}
