import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../../services/client_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/quotation_builder.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/photo_notification_service.dart';
import '../call_screen.dart';


class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Client> _clients = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String _searchQuery = '';
  String _selectedLocationFilter = 'ALL LOCATIONS';
  List<String> _locations = ['ALL LOCATIONS'];
  
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    // Initial fetch
    _loadLocations();
    _loadNextPage(isRefresh: true);

    // Run an immediate sync from Supabase on load
    ClientService.instance.syncClientsFromSupabase().then((_) {
      _loadLocations();
      _loadNextPage(isRefresh: true);
    });

    // Set up a periodic background sync every 4 seconds to catch new client self-registrations instantly
    _syncTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        ClientService.instance.syncClientsFromSupabase().then((_) {
          _loadLocations();
        });
      }
    });

    // Start polling for rich push notifications for uploaded photos
    PhotoNotificationService.instance.startPolling();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _syncTimer?.cancel();
    _searchController.dispose();
    PhotoNotificationService.instance.stopPolling();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadLocations() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('clients').get();
      final locs = snap.docs
          .map((doc) => (doc.data()['site_location'] ?? doc.data()['location'] ?? '').toString().trim())
          .where((loc) => loc.isNotEmpty)
          .toSet()
          .toList();
      locs.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (mounted) {
        setState(() {
          _locations = ['ALL LOCATIONS', ...locs];
        });
      }
    } catch (e) {
      debugPrint('Error loading locations: $e');
    }
  }

  Future<void> _loadNextPage({bool isRefresh = false}) async {
    if (_isLoadingMore || (!_hasMore && !isRefresh)) return;

    if (mounted) {
      setState(() {
        _isLoadingMore = true;
        if (isRefresh) {
          _isLoading = true;
          _clients.clear();
          _lastDocument = null;
          _hasMore = true;
        }
      });
    }

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('clients');

      if (_selectedLocationFilter != 'ALL LOCATIONS') {
        query = query.where('site_location', isEqualTo: _selectedLocationFilter);
      }

      if (_searchQuery.isNotEmpty) {
        final queryUpper = _searchQuery.toUpperCase();
        query = query
            .orderBy('client_name')
            .startAt([queryUpper])
            .endAt(['$queryUpper\uf8ff']);
      } else {
        query = query.orderBy('createdAt', descending: true);
      }

      query = query.limit(20);

      if (_lastDocument != null && !isRefresh) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.length < 20) {
        _hasMore = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      final List<Client> fetchedClients = querySnapshot.docs
          .map((doc) => Client.fromMap(doc.data(), doc.id))
          .toList();

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _clients = fetchedClients;
          } else {
            _clients.addAll(fetchedClients);
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading next page: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _playClickSound() {}

  Future<void> _callAdmin() async {
    _playClickSound();
    _showCallOptionDialog('pcm_admin_support');
  }

  void _startCall(String channel, bool isVideo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: channel,
          isVideoCall: isVideo,
        ),
      ),
    );
  }

  void _showCallOptionDialog(String channel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CONTACT PCM SUPPORT',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.border),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryButton,
                child: Icon(Icons.phone, color: Colors.white),
              ),
              title: const Text('VOICE CALL', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Internet voice call via Agora'),
              onTap: () {
                Navigator.pop(context);
                _startCall(channel, false);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.border,
                child: Icon(Icons.videocam, color: Colors.white),
              ),
              title: const Text('VIDEO CALL', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('High-quality video call'),
              onTap: () {
                Navigator.pop(context);
                _startCall(channel, true);
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.dialpad, color: Colors.white),
              ),
              title: const Text('NATIVE DIALER', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Traditional cellular call'),
              onTap: () async {
                Navigator.pop(context);
                final url = Uri.parse('tel:9383406185');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  

  

  

  void _showAddClientDialog() {
    _playClickSound();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final locationController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Register New Client',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.border),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: AppStyles.inputDecoration('Client Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: phoneController,
                decoration: AppStyles.inputDecoration('Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: locationController,
                decoration: AppStyles.inputDecoration('Site Location / Address'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: emailController,
                decoration: AppStyles.inputDecoration('Email Address'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryButton,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final loc = locationController.text.trim();
              final email = emailController.text.trim();

              if (name.isEmpty || phone.isEmpty || loc.isEmpty || email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all registration fields.'),
                    backgroundColor: AppColors.alertRed,
                  ),
                );
                return;
              }

              // Auto-generate Project Site ID in format: pcm-ms-XXXX (4-digit number)
              final randomCode = (1000 + Random().nextInt(9000)).toString();
              final unit = 'pcm-ms-$randomCode';

              final client = Client(
                id: unit,
                clientName: name,
                phoneNumber: phone,
                siteLocation: loc,
                unitNumber: unit,
                clientSelfie: '',
                totalContractAmount: 0.0,
                advanceReceived: 0.0,
                totalLaborCost: 0.0,
                createdAt: DateTime.now(),
                email: email,
              );

              await ClientService.instance.addClient(client);
              _loadLocations();
              _loadNextPage(isRefresh: true);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('REGISTER'),
          ),
        ],
      ),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'CLIENTS REGISTRY',
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_forwarded, color: Colors.white),
            tooltip: 'Call Admin',
            onPressed: _callAdmin,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PCM CLIENT HUB',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.labelColor,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'REGISTERED CLIENTS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.border,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
                _loadNextPage(isRefresh: true);
              },
              decoration: AppStyles.inputDecoration('Search by Name...').copyWith(
                prefixIcon: const Icon(Icons.search, color: AppColors.border),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: AppColors.border, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Location:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.border),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.2), width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLocationFilter,
                        isExpanded: true,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor, fontSize: 13),
                        dropdownColor: Colors.white,
                        items: _locations.map((loc) {
                          return DropdownMenuItem<String>(
                            value: loc,
                            child: Text(loc.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedLocationFilter = val;
                            });
                            _loadNextPage(isRefresh: true);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.border))
                : _clients.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ClientService.instance.syncClientsFromSupabase();
                          await _loadLocations();
                          await _loadNextPage(isRefresh: true);
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _isLoadingMore ? _clients.length + 1 : _clients.length,
                          itemBuilder: (context, index) {
                            if (index == _clients.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(color: AppColors.border),
                                ),
                              );
                            }
                            return ClientCardWidget(
                              client: _clients[index],
                              onRefresh: () => _loadNextPage(isRefresh: true),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.border,
        foregroundColor: Colors.white,
        onPressed: _showAddClientDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 15),
          const Text(
            'No Clients Found',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'No clients match the active filters. You can register a client manually or adjust your location filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.border),
            onPressed: _showAddClientDialog,
            child: const Text('ADD CLIENT MANUALLY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}