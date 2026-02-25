import 'package:ebook_project/components/ebook_grid.dart';
import 'package:ebook_project/screens/my_notes_page.dart';
import 'package:ebook_project/screens/profile.dart';
import 'package:ebook_project/screens/splash.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:ebook_project/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:in_app_update/in_app_update.dart';

import '../api/api_service.dart';
import '../components/app_layout.dart';
import '../components/shimmer_ebook_card_loader.dart';
import '../models/all_ebook.dart';
import '../models/ebook.dart';
import '../utils/token_store.dart';
import 'device_verification/device_verification_screen.dart';
import 'device_verification/device_verification_otp_screen.dart';
import 'device_verification/device_verification_reason_submit_screen.dart';
import 'ebook_detail.dart';
import 'login.dart';
import 'my_ebooks_page.dart';
import 'subscription_page.dart';
import 'package:ebook_project/screens/my_bookmarks_page.dart';
import 'package:ebook_project/screens/my_flags_page.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'My Ebooks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // theme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0EA5E9)),
      //   useMaterial3: true,
      // ),
      initialRoute: initialRoute,
      // routes: {
      //   '/': (context) => MyHomePage(title: 'My Ebooks'),
      //   '/login': (context) => LoginPage(),
      //   '/profile': (context) => ProfilePage(),
      // },
      routes: {
        '/splash': (context) => const SplashPage(),
        '/': (context) => const MyHomePage(title: 'All Ebooks'),
        '/my-ebooks': (context) => const MyEbooksPage(),
        '/login': (context) => const LoginPage(),
        '/profile': (context) => const ProfilePage(),
        '/device-verification': (_) => const DeviceVerificationScreen(),
        '/device-verification-otp': (_) =>
            const DeviceVerificationOtpScreen(),
        '/device-verification-reason': (_) =>
            const DeviceVerificationReasonSubmitScreen(),
        '/device-info': (_) => const DeviceVerificationScreen(),
        '/my-bookmarks': (_) => const MyBookmarksPage(),
        '/my-flags': (_) => const MyFlagsPage(),
        '/my-notes': (_) => const MyNotesPage(),
      },
      navigatorObservers: [routeObserver],
    );
  }
}

// Method to check for update
// Future<void> _checkForUpdate() async {
//   // Check for available update
//
//   InAppUpdate.checkForUpdate().then((info) {
//     if (info.updateAvailability == UpdateAvailability.updateAvailable) {
//       // If update is available, start the update flow
//       _performUpdate();
//     }
//   });
// }
//
// // Method to perform update
// Future<void> _performUpdate() async {
//   InAppUpdate.performImmediateUpdate().catchError((e) {
//     print("Update failed: $e");
//   });
// }

Future<void> _checkForUpdate() async {
  try {
    final info = await InAppUpdate.checkForUpdate();

    if (info.updateAvailability == UpdateAvailability.updateAvailable &&
        info.immediateUpdateAllowed) {
      await _performUpdate();
    }
  } catch (e) {
    // Emulator / dev mode এ এখানে আসবে
    debugPrint('In-app update skipped: $e');
  }
}

Future<void> _performUpdate() async {
  try {
    await InAppUpdate.performImmediateUpdate();
  } catch (e) {
    debugPrint('Update failed: $e');
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with RouteAware {
  List<Ebook> ebooks = [];
  bool isLoading = true;
  final Map<int, bool> _practiceAvailability = {};
  final Map<int, Future<bool>> _practiceFutures = {};
  final Map<int, AllEbook> _allEbookById = {};

  @override
  void initState() {
    _checkForUpdate();
    super.initState();
    fetchEbooks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    fetchEbooks();
  }

  Future<void> fetchEbooks() async {
    final apiService = ApiService();
    try {
      final allData = await apiService.fetchEbookData('/v1/all-ebooks');
      final ownedActiveIds = await _fetchOwnedActiveEbookIds(apiService);
      final list = _normalizeEbookList(allData);
      final parsed = list.map((e) => AllEbook.fromJson(e)).toList();
      // print('Fetched all ebooks: ${ownedActiveIds}');
      final filtered = parsed
          .where(
            (ebook) =>
                ebook.productId != 0 &&
                !ownedActiveIds.contains(ebook.productId),
          )
          .toList();

      setState(() {
        _allEbookById
          ..clear()
          ..addEntries(
            parsed
                .where((ebook) => ebook.softcopyId != 0)
                .map((ebook) => MapEntry(ebook.softcopyId, ebook)),
          );
        ebooks = filtered.map((e) => e.toEbook()).toList();
        isLoading = false;
        _practiceAvailability.clear();
        _practiceFutures.clear();
      });

      for (final ebook in ebooks) {
        _ensurePracticeAvailability(ebook);
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching ebooks: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: widget.title,
      // body: isLoading
      //     ? const Padding(
      //         padding: EdgeInsets.all(8.0),
      //         child: ShimmerEbookCardLoader(),
      //       )
      //     : Padding(
      //         padding: const EdgeInsets.all(8.0),
      //         child: ListView.builder(
      //           itemCount: ebooks.length,
      //           padding: const EdgeInsets.all(8.0),
      //           itemBuilder: (context, index) {
      //             return EbookCard(ebook: ebooks[index]);
      //           },
      //         ),
      //       ),

      body: isLoading
          ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: ShimmerEbookCardLoader(),
            )
          // : _buildLoadedBody(),
          : RefreshIndicator(
              onRefresh: () async {
                await fetchEbooks(); // ✅ pull করলে আবার API call
              },
              child:
                  _buildLoadedBody(), // ✅ এখানে scrollable থাকতে হবে (নিচে দিয়েছি)
            ),
    );
  }

  bool _isActive(Ebook ebook) {
    final s = ebook.status;
    return s == 1 || s == '1' || s == true || s == 'Active';
  }

  Future<void> _handleCardTap(BuildContext context, Ebook ebook) async {
    if (!_isActive(ebook)) {
      await _openPurchaseLink(ebook);
      return;
    }

    final hasPractice = await _ensurePracticeAvailability(ebook);
    // if(ebook.isExpired) {
    //
    // }
    if (!hasPractice && ebook.isExpired) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Practice questions are not available for this book.'),
        ),
      );
      return;
    }
    //for debugging
    // ScaffoldMessenger.of(context).showSnackBar(
    //    SnackBar(
    //     content: Text('${ebook.isExpired}'),
    //   ),
    // );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EbookDetailPage(
          ebook: ebook.toJson(),
          ebookId: ebook.id.toString(),
        ),
        settings: RouteSettings(name: '/my-ebooks/${ebook.id}'),
      ),
    );
  }

  Future<void> _handleHomeCardTap(BuildContext context, Ebook ebook) async {
    await _openPurchaseLink(ebook);
  }

  Widget _buildLoadedBody() {
    final pendingEbooks = ebooks.where((ebook) => !_isActive(ebook)).toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // _buildDeviceVerificationCard(),
          // const SizedBox(height: 12),
          if (pendingEbooks.isNotEmpty) ...[
            _buildPurchaseSection(pendingEbooks),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: EbookGrid(
              ebooks: ebooks,
              isLoading: isLoading,
              practiceAvailability: _practiceAvailability,
              onCardTap: _handleHomeCardTap,
              onBuyTap: _openPurchaseLink,
              showStatusBadge: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceVerificationCard() {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.verified_user, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keep this device verified',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verify on banglamed.net to keep your ebooks available here.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: _openDeviceVerification,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseSection(List<Ebook> pendingEbooks) {
    final preview = pendingEbooks.take(3).toList();
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.shopping_cart, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Grab your next ebook plan',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: _openPurchaseCatalog,
                  child: const Text('Visit store'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: preview.map((ebook) {
                return SizedBox(
                  width: 150,
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => _openPurchaseLink(ebook),
                    style: OutlinedButton.styleFrom(
                      side:
                          BorderSide(color: AppColors.primary.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      ebook.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (pendingEbooks.length > preview.length)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Plus ${pendingEbooks.length - preview.length} more on the store.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openDeviceVerification() {
    Navigator.pushNamed(context, '/device-verification');
  }

  Future<void> _openPurchaseLink(Ebook ebook) async {
    final softcopy = _allEbookById[ebook.id];
    if (!mounted) return;
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionPage(
          ebook: ebook,
          softcopy: softcopy,
          fallbackUrl:
              Uri.parse('https://banglamed.net/choose-plan/${ebook.id}'),
        ),
      ),
    );
    if (success == true) {
      await fetchEbooks();
      Navigator.pushNamed(context, '/my-ebooks');
    }
  }

  Future<void> _openPurchaseCatalog() async {
    if (!mounted) return;
    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionPage(
          ebook: Ebook(
            id: 0,
            subcriptionId: 0,
            image: '',
            name: 'Banglamed Plans',
            status: 0,
            validity: '',
            ending: '',
            button: null,
            statusText: '',
            isExpired: false,
          ),
          softcopy: null,
          fallbackUrl: Uri.parse('https://banglamed.net/choose-plan'),
          showLegacyPlans: true,
        ),
      ),
    );
    if (success == true) {
      await fetchEbooks();
      Navigator.pushNamed(context, '/my-ebooks');
    }
  }

  Future<bool> _ensurePracticeAvailability(Ebook ebook) {
    if (_practiceAvailability.containsKey(ebook.id)) {
      return Future.value(_practiceAvailability[ebook.id]!);
    }
    if (_practiceFutures.containsKey(ebook.id)) {
      return _practiceFutures[ebook.id]!;
    }

    final future = _detectPracticeAvailability(ebook);

    _practiceFutures[ebook.id] = future;
    future.then((value) {
      if (!mounted) return;
      setState(() {
        _practiceAvailability[ebook.id] = value;
      });
      _practiceFutures.remove(ebook.id);
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _practiceAvailability.remove(ebook.id);
      });
      _practiceFutures.remove(ebook.id);
    });

    return future;
  }

  Future<bool> _detectPracticeAvailability(Ebook ebook) async {
    await _ensurePracticeToken(ebook);
    final apiService = ApiService();
    try {
      final endpoint = await TokenStore.attachPracticeToken(
          "/v1/ebooks/${ebook.id}/practice-access");
      final data = await apiService.fetchEbookData(endpoint);
      return (data['practice_questions_available'] == true);
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensurePracticeToken(Ebook ebook) async {
    final existing = await TokenStore.practiceToken();
    if (existing != null && existing.isNotEmpty) return;
    final token = TokenStore.extractTokenFromUrl(ebook.button?.link);
    if (token == null || token.isEmpty) return;
    await TokenStore.savePracticeToken(token);
  }

  Future<Set<int>> _fetchOwnedActiveEbookIds(ApiService apiService) async {
    try {
      final data = await apiService.fetchEbookData('/v1/ebooks');
      final normalized = _normalizeEbookList(data);
      print('Normalized owned ebooks: $normalized');
      final owned = <int>{};

      for (final item in normalized) {
        final ebook = Ebook.fromJson(item);
        if (!_isActive(ebook) || ebook.isExpired) continue;
        owned.add(ebook.id);
        _collectOwnedIdentifiers(owned, item);
      }

      return owned;
    } catch (error) {
      debugPrint('Failed to load owned ebooks: $error');
      return {};
    }
  }

  void _collectOwnedIdentifiers(
      Set<int> target, Map<String, dynamic> rawEbook) {
    const candidateKeys = [
      'softcopy_id',
      'softcopyId',
      'ebook_id',
      'ebookId',
      'product_id',
      'productId',
      'subscription_id',
      'subscriptionId',
      'subcription_id',
      'subcriptionId',
      'id',
    ];

    for (final key in candidateKeys) {
      final candidate = _parseInt(rawEbook[key]);
      if (candidate != null && candidate > 0) {
        target.add(candidate);
      }
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9-]'), '');
      if (cleaned.isEmpty) return null;
      return int.tryParse(cleaned);
    }
    return null;
  }

  List<Map<String, dynamic>> _normalizeEbookList(Map<String, dynamic> data) {
    final raw = data['ebooks'] ?? data['0'] ?? data['data'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }
}
