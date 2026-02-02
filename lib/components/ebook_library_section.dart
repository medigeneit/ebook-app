import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../components/ebook_grid.dart';
import '../components/shimmer_ebook_card_loader.dart';
import '../components/under_maintanance_snackbar.dart';
import '../models/ebook.dart';
import '../screens/ebook_detail.dart';
import '../utils/token_store.dart';
import '../utils/update_manager.dart';

class EbookLibrarySection extends StatefulWidget {
  const EbookLibrarySection({super.key});

  @override
  State<EbookLibrarySection> createState() => _EbookLibrarySectionState();
}

class _EbookLibrarySectionState extends State<EbookLibrarySection> {
  final List<Ebook> _ebooks = [];
  final Map<int, bool> _practiceAvailability = {};
  final Map<int, Future<bool>> _practiceFutures = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    UpdateManager.checkForUpdate();
    _fetchEbooks();
  }

  Future<void> _fetchEbooks() async {
    final apiService = ApiService();
    try {
      final data = await apiService.fetchEbookData('/v1/ebooks');
      final list = _normalizeEbookList(data);
      setState(() {
        _ebooks
          ..clear()
          ..addAll(list.map((e) => Ebook.fromJson(e)));
        _practiceAvailability.clear();
        _practiceFutures.clear();
        _isLoading = false;
      });
      for (final ebook in _ebooks) {
        _ensurePracticeAvailability(ebook);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint("Error fetching ebooks: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: ShimmerEbookCardLoader(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: EbookGrid(
        ebooks: _ebooks,
        isLoading: _isLoading,
        practiceAvailability: _practiceAvailability,
        onCardTap: _handleCardTap,
      ),
    );
  }

  bool _isActive(Ebook ebook) {
    final s = ebook.status;
    return s == 1 || s == '1' || s == true || s == 'Active';
  }

  Future<void> _handleCardTap(BuildContext context, Ebook ebook) async {
    if (!ebook.isExpired && !_isActive(ebook)) {
      showUnderMaintenanceSnackbar();
      return;
    }

    final hasPractice = await _ensurePracticeAvailability(ebook);
    if (!hasPractice && ebook.isExpired) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Practice questions are not available for this book.'),
        ),
      );
      return;
    }

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
      return data['practice_questions_available'] == true;
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
