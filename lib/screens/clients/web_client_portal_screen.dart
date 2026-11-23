import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/client_model.dart';
import '../../services/client_service.dart';
import '../../theme/app_theme.dart';
import 'project_hub_page.dart';

class WebClientPortalScreen extends StatefulWidget {
  const WebClientPortalScreen({super.key});

  @override
  State<WebClientPortalScreen> createState() => _WebClientPortalScreenState();
}

class _WebClientPortalScreenState extends State<WebClientPortalScreen> {
  Client? _selectedClient;
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkUrlAndLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkUrlAndLoad() async {
    final String? unitFromUrl = _extractUnitFromUrl();
    if (unitFromUrl != null && unitFromUrl.isNotEmpty) {
      _searchController.text = unitFromUrl;
      final client = await ClientService.instance.getClientByUnitNumber(unitFromUrl);
      if (client != null && mounted) {
        setState(() {
          _selectedClient = client;
          _isLoading = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _extractUnitFromUrl() {
    try {
      final uri = Uri.base;

      // 1. Query Parameters e.g. ?unit=7890, ?project=7890, ?id=7890, ?site=7890, ?clientId=7890
      const paramKeys = ['unit', 'project', 'id', 'site', 'siteid', 'client', 'clientid', 'unitnumber'];
      for (final key in paramKeys) {
        if (uri.queryParameters.containsKey(key) && uri.queryParameters[key]!.trim().isNotEmpty) {
          return uri.queryParameters[key]!.trim();
        }
      }

      // 2. Path Segments e.g. /project/7890 or /quotation/7890 or /dispatch/7890 or /site/7890
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final key = segments[segments.length - 2].toLowerCase();
        if (key == 'project' || key == 'quotation' || key == 'dispatch' || key == 'site' || key == 'client') {
          return segments.last.trim();
        }
      } else if (segments.length == 1 && segments.first.isNotEmpty && segments.first != 'index.html') {
        return segments.first.trim();
      }

      // 3. Fragment / Hash e.g. #/project/7890 or #7890
      if (uri.fragment.isNotEmpty) {
        final frag = uri.fragment.startsWith('/') ? uri.fragment : '/${uri.fragment}';
        final fragUri = Uri.parse(frag);

        for (final key in paramKeys) {
          if (fragUri.queryParameters.containsKey(key) && fragUri.queryParameters[key]!.trim().isNotEmpty) {
            return fragUri.queryParameters[key]!.trim();
          }
        }

        final fragSegs = fragUri.pathSegments;
        if (fragSegs.length >= 2) {
          final key = fragSegs[fragSegs.length - 2].toLowerCase();
          if (key == 'project' || key == 'quotation' || key == 'dispatch' || key == 'site' || key == 'client') {
            return fragSegs.last.trim();
          }
        } else if (fragSegs.length == 1 && fragSegs.first.isNotEmpty) {
          return fragSegs.first.trim();
        }
      }
    } catch (e) {
      debugPrint('Error parsing web URL: $e');
    }
    return null;
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final client = await ClientService.instance.getClientByUnitNumber(clean);

    if (mounted) {
      if (client != null) {
        setState(() {
          _selectedClient = client;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No project found matching "$clean". Please verify your Site ID or Phone Number.';
        });
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Site Folder', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete site folder for ${client.clientName} (${client.unitNumber})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await ClientService.instance.deleteClient(client.id, unitNumber: client.unitNumber);

                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Site folder deleted successfully!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Stream<Client?> _streamClient(String queryStr) {
    final raw = queryStr.trim();
    if (raw.isEmpty) return Stream.value(null);

    final normalized = ClientService.normalizeUnitNumber(raw);

    return FirebaseFirestore.instance
        .collection('clients')
        .doc(normalized)
        .snapshots()
        .asyncMap((doc) async {
      if (doc.exists && doc.data() != null) {
        return Client.fromMap(doc.data()!, doc.id);
      }

      final docRaw = await FirebaseFirestore.instance.collection('clients').doc(raw).get();
      if (docRaw.exists && docRaw.data() != null) {
        return Client.fromMap(docRaw.data()!, docRaw.id);
      }

      return await ClientService.instance.getClientByUnitNumber(raw);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedClient != null) {
      return StreamBuilder<Client?>(
        stream: _streamClient(_selectedClient!.unitNumber),
        builder: (context, snapshot) {
          final liveClient = snapshot.data ?? _selectedClient!;
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.border,
              foregroundColor: Colors.white,
              elevation: 2,
              title: Text(
                'PCM PORTAL: ${liveClient.clientName.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedClient = null;
                      _errorMessage = '';
                    });
                  },
                  icon: const Icon(Icons.search, color: Colors.white, size: 18),
                  label: const Text('SEARCH ANOTHER PROJECT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: ProjectHubPage(client: liveClient),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Logo Banner
                Hero(
                  tag: 'pcm_logo',
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                    errorBuilder: (_, __, ___) => const Icon(Icons.architecture, size: 80, color: AppColors.border),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PREMIUM CEILING MASTER | WAYANAD',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3E2723),
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'LIVE CLIENT PROJECT PORTAL & DESIGN STUDIO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF795548),
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Search / Lookup Card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.travel_explore, color: AppColors.border, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Track Your False Ceiling Project',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your Site ID / Unit Number (e.g. 7890) or registered phone number to view live progress, 3D designs, payment receipts, and site photos.',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: _performSearch,
                              decoration: InputDecoration(
                                hintText: 'Enter Site ID (e.g. 7890) or Phone Number...',
                                prefixIcon: const Icon(Icons.numbers, color: AppColors.border),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade400),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.border, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => _performSearch(_searchController.text),
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('TRACK PROJECT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.border,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                      if (_isLoading) ...[
                        const SizedBox(height: 20),
                        const Center(child: CircularProgressIndicator(color: AppColors.border)),
                      ],
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Active Registered Projects List
                StreamBuilder<List<Client>>(
                  stream: ClientService.instance.getClients(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final clients = snapshot.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.dashboard_customize, color: AppColors.border, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Active Client Projects',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            mainAxisExtent: 130,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: clients.length,
                          itemBuilder: (context, index) {
                            final client = clients[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    _selectedClient = client;
                                    _errorMessage = '';
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  client.clientName.toUpperCase(),
                                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 32), // Spacing for top-right delete button
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'ID: #${client.unitNumber} • SITE: ${client.siteLocation}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('LIVE PORTAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '₹${client.totalContractAmount.toStringAsFixed(2)}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        top: -6,
                                        right: -6,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          tooltip: 'Delete Site Folder',
                                          onPressed: () {
                                            _showDeleteConfirmation(context, client);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Footer
                const Text(
                  'PREMIUM CEILING MASTER | WAYANAD   •   MOB: 93 83 40 61 85\nEmail: MARKINTERIOR174@GMAIL.COM',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
