import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../../services/client_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  
  String _searchQuery = '';
  String _selectedLocationFilter = 'ALL LOCATIONS';
  String _selectedCategoryFilter = 'ALL CATEGORIES';
  Client? _selectedClient;

  Stream<List<Client>>? _projectsStream;

  @override
  void initState() {
    super.initState();
    // Start polling for rich push notifications for uploaded photos
    PhotoNotificationService.instance.startPolling();

    _projectsStream ??= _buildMergedProjectsStream();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    PhotoNotificationService.instance.stopPolling();
    super.dispose();
  }

  Stream<List<Client>> _buildMergedProjectsStream() {
    late StreamController<List<Client>> controller;

    QuerySnapshot<Map<String, dynamic>>? clientsSnap;
    QuerySnapshot<Map<String, dynamic>>? quotationsSnap;
    QuerySnapshot<Map<String, dynamic>>? projectsSnap;
    QuerySnapshot<Map<String, dynamic>>? registrationsSnap;
    QuerySnapshot<Map<String, dynamic>>? profilesSnap;
    QuerySnapshot<Map<String, dynamic>>? submissionsSnap;

    void update() {
      if (controller.isClosed) return;
      final Map<String, Client> mergedMap = {};

      void processDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
        if (!doc.exists || doc.data() == null) return;
        final data = doc.data()!;
        if (data['isDeleted'] == true || data['is_deleted'] == true) return;

        final client = Client.fromMap(data, doc.id);
        final String cleanDigitsPhone = client.phoneNumber.replaceAll(RegExp(r'\D'), '');
        final String effectiveKey = (cleanDigitsPhone.length >= 10)
            ? 'phone_$cleanDigitsPhone'
            : (client.unitNumber.isNotEmpty ? client.unitNumber : doc.id);

        if (effectiveKey.isEmpty) return;

        final existing = mergedMap[effectiveKey];
        if (existing == null) {
          mergedMap[effectiveKey] = client;
        } else {
          final bool isDraftName = existing.clientName.isEmpty ||
              existing.clientName.toUpperCase() == 'SITE DRAFT' ||
              existing.clientName.toUpperCase() == 'PCM SITE' ||
              existing.clientName.toUpperCase() == 'PCM SITE DRAFT';

          final bool isTimestampUnit = RegExp(r'#\s*PCM-\d{8}-\d{4}', caseSensitive: false).hasMatch(existing.unitNumber);
          final bool isDraftUnit = existing.unitNumber.isEmpty ||
              existing.unitNumber.contains('google_') ||
              isTimestampUnit;

          final bool hasLiveClientName = client.clientName.isNotEmpty &&
              client.clientName.toUpperCase() != 'SITE DRAFT' &&
              client.clientName.toUpperCase() != 'PCM SITE' &&
              client.clientName.toUpperCase() != 'PCM SITE DRAFT';

          final bool hasLiveUnitNumber = client.unitNumber.isNotEmpty &&
              !RegExp(r'#\s*PCM-\d{8}-\d{4}', caseSensitive: false).hasMatch(client.unitNumber);

          mergedMap[effectiveKey] = existing.copyWith(
            clientName: (isDraftName && hasLiveClientName) ? client.clientName : existing.clientName,
            phoneNumber: existing.phoneNumber.isEmpty ? client.phoneNumber : existing.phoneNumber,
            siteLocation: existing.siteLocation.isEmpty ? client.siteLocation : existing.siteLocation,
            unitNumber: (isDraftUnit && hasLiveUnitNumber) ? client.unitNumber : existing.unitNumber,
            totalContractAmount: existing.totalContractAmount > 0 ? existing.totalContractAmount : client.totalContractAmount,
            advanceReceived: existing.advanceReceived > 0 ? existing.advanceReceived : client.advanceReceived,
          );
        }
      }

      // Process registrationsSnap FIRST so live Vercel portal registrations form the baseline entry
      if (registrationsSnap != null) {
        for (var doc in registrationsSnap!.docs) { processDoc(doc); }
      }
      if (clientsSnap != null) {
        for (var doc in clientsSnap!.docs) { processDoc(doc); }
      }
      if (quotationsSnap != null) {
        for (var doc in quotationsSnap!.docs) { processDoc(doc); }
      }
      if (projectsSnap != null) {
        for (var doc in projectsSnap!.docs) { processDoc(doc); }
      }
      if (profilesSnap != null) {
        for (var doc in profilesSnap!.docs) { processDoc(doc); }
      }
      if (submissionsSnap != null) {
        for (var doc in submissionsSnap!.docs) { processDoc(doc); }
      }

      final list = mergedMap.values.toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(list);
    }

    StreamSubscription? sub1;
    StreamSubscription? sub2;
    StreamSubscription? sub3;
    StreamSubscription? sub4;
    StreamSubscription? sub5;
    StreamSubscription? sub6;
    Timer? heartbeatTimer;

    Future<QuerySnapshot<Map<String, dynamic>>?> safeFetch(String col) async {
      try {
        final options = kIsWeb
            ? const GetOptions(source: Source.server)
            : const GetOptions(source: Source.serverAndCache);
        return await FirebaseFirestore.instance.collection(col).get(options).timeout(
          const Duration(seconds: 10),
          onTimeout: () => FirebaseFirestore.instance.collection(col).get(),
        );
      } catch (e) {
        try {
          return await FirebaseFirestore.instance
              .collection(col)
              .get();
        } catch (err) {
          debugPrint('Firestore fetch notice ($col): $err');
          return null;
        }
      }
    }

    void handleStreamError(String collectionName, Object error) {
      debugPrint('Firestore stream notice ($collectionName): $error');
      // Auto-recover from transient WebChannel stream drops cleanly
      Future.microtask(() async {
        try {
          final snap = await safeFetch(collectionName);
          if (snap != null) {
            if (collectionName == 'clients') clientsSnap = snap;
            if (collectionName == 'quotations') quotationsSnap = snap;
            if (collectionName == 'projects') projectsSnap = snap;
            if (collectionName == 'registrations') registrationsSnap = snap;
            if (collectionName == 'client_profiles') profilesSnap = snap;
            if (collectionName == 'submissions') submissionsSnap = snap;
            update();
          }
        } catch (_) {}
      });
    }

    controller = StreamController<List<Client>>.broadcast(
      onListen: () {
        // Fast initial fetch
        Future.microtask(() async {
          try {
            clientsSnap = await safeFetch('clients');
            quotationsSnap = await safeFetch('quotations');
            projectsSnap = await safeFetch('projects');
            registrationsSnap = await safeFetch('registrations');
            profilesSnap = await safeFetch('client_profiles');
            submissionsSnap = await safeFetch('submissions');
            update();
          } catch (e) {
            debugPrint('Initial Firestore fetch notice: $e');
          }
        });

        // Periodic fallback timer for Web platform to maintain data freshness
        if (kIsWeb) {
          heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
            try {
              clientsSnap = await safeFetch('clients') ?? clientsSnap;
              quotationsSnap = await safeFetch('quotations') ?? quotationsSnap;
              projectsSnap = await safeFetch('projects') ?? projectsSnap;
              registrationsSnap = await safeFetch('registrations') ?? registrationsSnap;
              profilesSnap = await safeFetch('client_profiles') ?? profilesSnap;
              submissionsSnap = await safeFetch('submissions') ?? submissionsSnap;
              update();
            } catch (e) {
              debugPrint('Web heartbeat sync notice: $e');
            }
          });
        }

        // Real-time stream subscriptions with auto-reconnection error handling
        sub1 = FirebaseFirestore.instance.collection('clients').snapshots().listen((snap) {
          clientsSnap = snap;
          update();
        }, onError: (e) => handleStreamError('clients', e));

        sub2 = FirebaseFirestore.instance.collection('quotations').snapshots().listen((snap) {
          quotationsSnap = snap;
          update();
        }, onError: (e) => handleStreamError('quotations', e));

        sub3 = FirebaseFirestore.instance.collection('projects').snapshots().listen((snap) {
          projectsSnap = snap;
          update();
        }, onError: (e) => handleStreamError('projects', e));

        sub4 = FirebaseFirestore.instance.collection('registrations').snapshots().listen((snap) {
          registrationsSnap = snap;
          update();
        }, onError: (e) => handleStreamError('registrations', e));

        sub5 = FirebaseFirestore.instance.collection('client_profiles').snapshots().listen((snap) {
          profilesSnap = snap;
          update();
        }, onError: (e) => handleStreamError('client_profiles', e));

        sub6 = FirebaseFirestore.instance.collection('submissions').snapshots().listen((snap) {
          submissionsSnap = snap;
          update();
        }, onError: (e) => handleStreamError('submissions', e));
      },
      onCancel: () {
        heartbeatTimer?.cancel();
        sub1?.cancel();
        sub2?.cancel();
        sub3?.cancel();
        sub4?.cancel();
        sub5?.cancel();
        sub6?.cancel();
      },
    );

    return controller.stream;
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
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('REGISTER'),
          ),
        ],
      ),
    );
  }

  Future<void> _forceCloudFetch() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('☁️ Syncing all client folders from Cloud Firestore...'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.border,
          ),
        );
      }
      _projectsStream = null;
      setState(() {
        _projectsStream = _buildMergedProjectsStream();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cloud sync notice: $e'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'CLIENTS REGISTRY',
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync, color: Colors.white),
            tooltip: 'Fetch All From Cloud',
            onPressed: _forceCloudFetch,
          ),
          IconButton(
            icon: const Icon(Icons.phone_forwarded, color: Colors.white),
            tooltip: 'Call Admin',
            onPressed: _callAdmin,
          ),
        ],
      ),
      body: StreamBuilder<List<Client>>(
        stream: _projectsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.border));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading site folders: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.border),
                    icon: const Icon(Icons.cloud_download, color: Colors.white),
                    label: const Text('RECONNECT & FETCH FROM CLOUD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: _forceCloudFetch,
                  ),
                ],
              ),
            );
          }

          final allClients = List<Client>.from(snapshot.data ?? []);

          // Sort by createdAt descending
          allClients.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Extract locations for filter dropdown dynamically
          final locSet = allClients
              .map((c) => c.siteLocation.trim())
              .where((loc) => loc.isNotEmpty)
              .toSet()
              .toList();
          locSet.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          final locationsList = ['ALL LOCATIONS', ...locSet];

          final activeLocationFilter = locationsList.contains(_selectedLocationFilter)
              ? _selectedLocationFilter
              : 'ALL LOCATIONS';

          // Filter by location
          List<Client> filteredClients = allClients;
          if (activeLocationFilter != 'ALL LOCATIONS') {
            filteredClients = filteredClients
                .where((c) => c.siteLocation.trim().toUpperCase() == activeLocationFilter.toUpperCase())
                .toList();
          }

          // Filter by category / project type (including 'HOUSES / വീട്')
          final categoriesList = ['ALL CATEGORIES', 'HOUSES / വീട്', 'COMMERCIAL', 'RENOVATION'];
          final activeCategoryFilter = categoriesList.contains(_selectedCategoryFilter)
              ? _selectedCategoryFilter
              : 'ALL CATEGORIES';

          if (activeCategoryFilter != 'ALL CATEGORIES') {
            filteredClients = filteredClients.where((c) {
              final catUpper = activeCategoryFilter.toUpperCase();
              if (catUpper.contains('HOUSE') || catUpper.contains('വീട്')) {
                final type = c.projectType.toLowerCase();
                final name = c.clientName.toLowerCase();
                final loc = c.siteLocation.toLowerCase();
                return type.contains('house') ||
                    type.contains('വീട്') ||
                    type.contains('residential') ||
                    type.contains('home') ||
                    type.contains('veedu') ||
                    name.contains('വീട്') ||
                    loc.contains('വീട്') ||
                    type.isEmpty;
              }
              return c.projectType.toUpperCase().contains(catUpper);
            }).toList();
          }

          // Filter by search query (matching name, phone, location, site ID, projectType / വീട്)
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final isHouseQuery = q.contains('വീട്') ||
                q.contains('house') ||
                q.contains('veedu') ||
                q.contains('home') ||
                q.contains('residential');

            filteredClients = filteredClients.where((c) {
              if (isHouseQuery) {
                final type = c.projectType.toLowerCase();
                final name = c.clientName.toLowerCase();
                final loc = c.siteLocation.toLowerCase();
                if (type.contains('house') ||
                    type.contains('വീട്') ||
                    type.contains('residential') ||
                    type.contains('home') ||
                    type.contains('veedu') ||
                    name.contains('വീട്') ||
                    loc.contains('വീട്') ||
                    type.isEmpty) {
                  return true;
                }
              }

              return c.clientName.toLowerCase().contains(q) ||
                  c.phoneNumber.toLowerCase().contains(q) ||
                  c.siteLocation.toLowerCase().contains(q) ||
                  c.unitNumber.toLowerCase().contains(q) ||
                  c.projectType.toLowerCase().contains(q) ||
                  c.customerType.toLowerCase().contains(q);
            }).toList();
          }

          final double screenWidth = MediaQuery.of(context).size.width;
          final bool isWideScreen = screenWidth >= 850;
          final bool isClientSelected = _selectedClient != null;

          Widget buildClientListPane() {
            return Column(
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
                    },
                    decoration: AppStyles.inputDecoration('Search by Name, Location, Category or Site ID...').copyWith(
                      prefixIcon: const Icon(Icons.search, color: AppColors.border),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.2), width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: activeLocationFilter,
                              isExpanded: true,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor, fontSize: 12),
                              dropdownColor: Colors.white,
                              items: locationsList.map((loc) {
                                return DropdownMenuItem<String>(
                                  value: loc,
                                  child: Text(loc.toUpperCase(), overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedLocationFilter = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.2), width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: activeCategoryFilter,
                              isExpanded: true,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor, fontSize: 12),
                              dropdownColor: Colors.white,
                              items: categoriesList.map((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat,
                                  child: Text(cat, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedCategoryFilter = val;
                                  });
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
                  child: filteredClients.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _forceCloudFetch,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: filteredClients.length,
                            itemBuilder: (context, index) {
                              final client = filteredClients[index];
                              final isSelected = _selectedClient != null &&
                                  (_selectedClient!.id == client.id || _selectedClient!.unitNumber == client.unitNumber);
                              return ClientCardWidget(
                                client: client,
                                isSelected: isSelected,
                                onSelectClient: (c) {
                                  setState(() {
                                    _selectedClient = c;
                                  });
                                },
                                onRefresh: () => setState(() {}),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          }

          if (isWideScreen) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 400,
                  child: buildClientListPane(),
                ),
                Container(width: 1, color: AppColors.border.withValues(alpha: 0.2)),
                Expanded(
                  child: isClientSelected
                      ? _buildClientDetailPane(_selectedClient!)
                      : _buildSelectClientPrompt(),
                ),
              ],
            );
          } else {
            if (isClientSelected) {
              return _buildClientDetailPane(_selectedClient!);
            }
            return buildClientListPane();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'clients_screen_add_fab',
        backgroundColor: AppColors.border,
        foregroundColor: Colors.white,
        onPressed: _showAddClientDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasActiveFilter = _searchQuery.isNotEmpty || _selectedLocationFilter != 'ALL LOCATIONS';
    final List<Widget> buttons = [];

    if (hasActiveFilter) {
      buttons.add(
        OutlinedButton(
          onPressed: () {
            setState(() {
              _searchQuery = '';
              _searchController.clear();
              _selectedLocationFilter = 'ALL LOCATIONS';
            });
          },
          child: const Text('RESET FILTERS', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    buttons.add(
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryButton,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.cloud_download, size: 18),
        label: const Text('FETCH ALL FROM CLOUD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        onPressed: _forceCloudFetch,
      ),
    );

    buttons.add(
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.border,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.person_add, size: 18),
        label: const Text('REGISTER CLIENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        onPressed: _showAddClientDialog,
      ),
    );

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_sync_outlined, size: 64, color: AppColors.border),
            const SizedBox(height: 15),
            const Text(
              'No Registered Clients Displayed',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.labelColor, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'If clients were registered via the Web Portal or Mobile App, click "FETCH ALL FROM CLOUD" below to pull live site records directly from Firestore.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: buttons,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientDetailPane(Client client) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Detail Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.border),
                  tooltip: 'Back to Client List',
                  onPressed: () {
                    setState(() {
                      _selectedClient = null;
                    });
                  },
                ),
                CircleAvatar(
                  backgroundColor: AppColors.border,
                  radius: 18,
                  child: Text(
                    client.clientName.isNotEmpty ? client.clientName[0].toUpperCase() : 'M',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.clientName.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.border),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryButton.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              client.unitNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryButton),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            client.phoneNumber,
                            style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.border),
                  tooltip: 'Close Detail View',
                  onPressed: () {
                    setState(() {
                      _selectedClient = null;
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Scrollable Detail Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ClientCardWidget(
                client: client,
                isSelected: true,
                onRefresh: () => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectClientPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.touch_app_outlined, size: 64, color: AppColors.border),
          SizedBox(height: 16),
          Text(
            'Select a Client to View Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.border),
          ),
          SizedBox(height: 8),
          Text(
            'Click on any client card on the left panel to open their live site dashboard alongside the list.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
