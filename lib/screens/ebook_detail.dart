import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/components/shimmer_ebook_detail_loader.dart';
import 'package:ebook_project/screens/ebook_subjects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebook_project/utils/token_store.dart';

class EbookDetailPage extends StatefulWidget {
  final String ebookId;
  final Map<String, dynamic> ebook;

  const EbookDetailPage({super.key, required this.ebookId, required this.ebook});

  @override
  _EbookDetailPageState createState() => _EbookDetailPageState();
}

class _EbookDetailPageState extends State<EbookDetailPage> {
  static const double _ctaHeight = 52;

  Map<String, dynamic> ebookDetail = {};
  bool isLoading = true;
  bool isError = false;
  bool? practiceAvailable;
  bool isPracticeStatusLoading = true;
  String selectedTab = 'features';

  @override
  void initState() {
    super.initState();
    _maybeStoreTokenFromLink();
    fetchEbookDetails();
    _checkPracticeAvailability();
  }

  Future<void> _maybeStoreTokenFromLink() async {
    final rawLink = widget.ebook['button']?['link']?.toString();
    final fallbackLink = widget.ebook['image']?.toString();
    final token = TokenStore.extractTokenFromUrl(rawLink) ??
        TokenStore.extractTokenFromUrl(fallbackLink);

    if (token == null || token.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await TokenStore.savePracticeToken(token);
  }

  Future<void> fetchEbookDetails() async {
    ApiService apiService = ApiService();
    try {
      final data = await apiService.fetchEbookData("/v1/ebooks/${widget.ebookId}");
      setState(() {
        ebookDetail = data['eBook'];
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
        isError = true;
      });
      print("Error fetching ebook details: $error");
    }
  }

  Future<void> _checkPracticeAvailability() async {
    final apiService = ApiService();
    try {
      final endpoint = await TokenStore.attachPracticeToken(
        "/v1/ebooks/${widget.ebookId}/practice-access",
      );
      final data = await apiService.fetchEbookData(endpoint);
      final available = data['practice_questions_available'] == true;

      if (!mounted) return;
      setState(() {
        practiceAvailable = available;
        isPracticeStatusLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        practiceAvailable = null;
        isPracticeStatusLoading = false;
      });
      print("Error fetching practice availability: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpired = widget.ebook['isExpired'] == true;

    // তোমার আগের লজিক 그대로
    final bool canShowPracticeButton = practiceAvailable == true && isExpired;

    // ✅ AppLayout এর ভেতরে BottomNav থাকায় এখানে BottomNavHeight যোগ করবো না
    const double gapAboveBottomBar = 8; // ঠিক উপরে চাইলে 0, একটু গ্যাপ চাইলে 6/8/10

    // overlay বাটনের মোট height (একটা/দুইটা বাটন)
    final double ctaStackHeight =
        (!isExpired ? _ctaHeight : 0) + (canShowPracticeButton ? (_ctaHeight + 10) : 0);

    // scroll content যেন overlay বাটনের নিচে না যায়
    final double scrollBottomReserve = ctaStackHeight + gapAboveBottomBar + 24;

    return AppLayout(
      title: "${widget.ebook['name']} Details",
      body: isLoading
          ? const ShimmerEbookDetailLoader()
          : isError
          ? const Center(child: Text('Failed to load ebook details'))
          : Stack(
        children: [
          // ---- Scrollable Content ----
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, scrollBottomReserve),
            child: Column(
              children: [
                Text(
                  'Welcome to Banglamed E-Book',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),

                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: ((ebookDetail['specifications'] as List?) ?? [])
                            .map<Widget>((spec) {
                          if (spec == null || spec is! Map) {
                            return const SizedBox.shrink();
                          }
                          return _buildRow(spec['title'], spec['value']);
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                if (isExpired)
                  const Padding(
                    padding: EdgeInsets.only(top: 6.0),
                    child: Text(
                      'Your reading access is expired.',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                (ebookDetail['image'] == null || ebookDetail['image'] == "")
                    ? Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.book, color: Colors.grey, size: 80),
                  ),
                )
                    : SizedBox(
                  width: double.infinity,
                  height: 400,
                  child: Image.network(
                    ebookDetail['image'],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error, color: Colors.red, size: 80),
                      );
                    },
                  ),
                ),

                DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        onTap: (index) {
                          setState(() {
                            selectedTab = index == 0 ? 'features' : 'instructions';
                          });
                        },
                        tabs: const [
                          Tab(text: 'Features'),
                          Tab(text: 'Instructions'),
                        ],
                      ),
                      SizedBox(
                        height: 250,
                        child: TabBarView(
                          children: [
                            (ebookDetail['features'] != null &&
                                ebookDetail['features'].isNotEmpty)
                                ? SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Html(data: ebookDetail['features']),
                              ),
                            )
                                : const Center(child: Text('No features available')),
                            (ebookDetail['instructions'] != null &&
                                ebookDetail['instructions'].isNotEmpty)
                                ? SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Html(data: ebookDetail['instructions']),
                              ),
                            )
                                : const Center(child: Text('No instructions available')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // ---- Floating Buttons (fixed bottom) ----
          if (!isExpired || canShowPracticeButton)
            Positioned(
              left: 16,
              right: 16,
              bottom: gapAboveBottomBar, // ✅ bottom bar এর ঠিক উপরে বসবে
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (canShowPracticeButton) ...[
                    SizedBox(
                      height: _ctaHeight,
                      child: ElevatedButton(
                        onPressed: () => _openSubjects(practice: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0f172a),
                          padding:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              FontAwesomeIcons.questionCircle,
                              color: Colors.white,
                              size: 26,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Practice Questions',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (!isExpired)
                    SizedBox(
                      height: _ctaHeight,
                      child: ElevatedButton(
                        onPressed: () => _openSubjects(practice: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0c4a6e),
                          padding:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ).copyWith(
                          backgroundColor:
                          MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                              if (states.contains(MaterialState.pressed)) {
                                return const Color.fromARGB(255, 8, 140, 216)
                                    .withOpacity(0.5);
                              } else if (states.contains(MaterialState.hovered)) {
                                return const Color.fromARGB(255, 8, 140, 216)
                                    .withOpacity(0.8);
                              }
                              return const Color.fromARGB(255, 12, 128, 196);
                            },
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              FontAwesomeIcons.solidHandPointRight,
                              color: Colors.white,
                              size: 30,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Go to Subjects',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openSubjects({required bool practice}) async {
    await _maybeStoreTokenFromLink();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EbookSubjectsPage(
          ebookId: ebookDetail['id'].toString(),
          ebookName: widget.ebook['name'].toString(),
          practice: practice,
        ),
      ),
    );
  }

  Widget _buildRow(dynamic label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
