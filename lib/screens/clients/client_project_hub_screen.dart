import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/client_service.dart';
import '../../models/client_model.dart';
import '../../theme/app_theme.dart';
import 'project_hub_page.dart';

class ClientProjectHubScreen extends StatefulWidget {
  const ClientProjectHubScreen({super.key});

  @override
  State<ClientProjectHubScreen> createState() => _ClientProjectHubScreenState();
}

class _ClientProjectHubScreenState extends State<ClientProjectHubScreen> {
  Client? _client;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    final user = AuthService.instance.userData;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'User not found.';
      });
      return;
    }

    try {
      // Find client record by phone or assigned unitNumber if available
      final clients = await ClientService.instance.getClients().first;
      Client? matchedClient;

      // Try matching by phone number
      matchedClient = clients.where((c) => c.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '') == user.phone.replaceAll(RegExp(r'[^0-9]'), '')).firstOrNull;

      // Fallback: match by name
      matchedClient ??= clients.where((c) => c.clientName.toLowerCase() == user.name.toLowerCase()).firstOrNull;

      // Fallback 2: If the user has assignedSites, use the first one
      if (matchedClient == null && user.assignedSites.isNotEmpty) {
        matchedClient = clients.where((c) => c.unitNumber == user.assignedSites.first).firstOrNull;
      }

      if (matchedClient != null) {
        setState(() {
          _client = matchedClient;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'No project linked to your account. Please contact admin.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading project: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.border)),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('CLIENT PORTAL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
          backgroundColor: AppColors.border,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: AppColors.alertRed),
              const SizedBox(height: 20),
              Text(_error, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loadClientData,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.border, foregroundColor: Colors.white),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    // Successfully found the client, show the hub
    return ProjectHubPage(client: _client!);
  }
}
