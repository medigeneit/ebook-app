import 'package:ebook_project/api/api_service.dart';
import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/components/shimmer_list_loader.dart';
import 'package:ebook_project/models/saved_content_item.dart';
import 'package:ebook_project/screens/ebook_contents.dart';
import 'package:ebook_project/theme/app_colors.dart';
import 'package:ebook_project/utils/token_store.dart';
import 'package:flutter/material.dart';

enum SavedListMode { bookmarks, flags, notes }

class SavedContentsListPage extends StatefulWidget {
  final SavedListMode mode;

  const SavedContentsListPage({super.key, required this.mode});

  String get title {
    switch (mode) {
      case SavedListMode.bookmarks:
        return 'My Bookmarks';
      case SavedListMode.flags:
        return 'My Flags';
      case SavedListMode.notes:
        return 'My Notes';
    }
  }

  @override
  State<SavedContentsListPage> createState() => _SavedContentsListPageState();
}

class _SavedContentsListPageState extends State<SavedContentsListPage> {
  final ApiService api = ApiService();

  // products state
  bool _loadingProducts = true;
  bool _errorProducts = false;
  String _errorProductsMsg = '';
  String _serverTitle = '';
  final List<_ProductItem> _products = [];
  _ProductItem? _selectedProduct;

  // items state
  bool _loadingItems = false;
  bool _errorItems = false;
  String _errorItemsMsg = '';
  final List<SavedContentItem> _items = [];

  // search
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<Map<String, dynamic>> _fetchFirstOk(List<String> endpoints) async {
    Object? last;
    for (final ep0 in endpoints) {
      try {
        final ep = await TokenStore.attachPracticeToken(ep0);
        return await api.fetchEbookData(ep);
      } catch (e) {
        last = e;
      }
    }
    throw last ?? Exception('API call failed');
  }

  String get _option {
    switch (widget.mode) {
      case SavedListMode.bookmarks:
        return 'my-bookmarks';
      case SavedListMode.flags:
        return 'my-flags';
      case SavedListMode.notes:
        return 'my-notes';
    }
  }

  String get _itemsKey {
    switch (widget.mode) {
      case SavedListMode.bookmarks:
        return 'bookmarks';
      case SavedListMode.flags:
        return 'flags';
      case SavedListMode.notes:
        return 'notes';
    }
  }

  String get _base {
    switch (widget.mode) {
      case SavedListMode.bookmarks:
        return 'my-bookmarks';
      case SavedListMode.flags:
        return 'my-flags';
      case SavedListMode.notes:
        return 'my-notes';
    }
  }

  IconData get _modeIcon {
    switch (widget.mode) {
      case SavedListMode.bookmarks:
        return Icons.bookmark_rounded;
      case SavedListMode.flags:
        return Icons.flag_rounded;
      case SavedListMode.notes:
        return Icons.sticky_note_2_rounded;
    }
  }

  String get _countLabel => widget.mode == SavedListMode.notes ? 'notes' : 'items';

  // ---------------------------------------
  // Step 1: product list
  // ---------------------------------------
  Future<void> _loadProducts() async {
    setState(() {
      _loadingProducts = true;
      _errorProducts = false;
      _errorProductsMsg = '';
      _serverTitle = '';
      _products.clear();

      _selectedProduct = null;
      _items.clear();
      _loadingItems = false;
      _errorItems = false;
      _errorItemsMsg = '';
      _search.clear();
      _query = '';
    });

    try {
      // ✅ তোমার দেয়া: Route::get('my-notes/products', poductwise_item)
      final data = await _fetchFirstOk([
        '/my-notes/products?option=$_option',
        '/v1/my-notes/products?option=$_option',
        // fallback safe
        '/productwise-items?option=$_option',
        '/v1/productwise-items?option=$_option',
      ]);

      final title = (data['title'] ?? '').toString().trim();
      if (title.isNotEmpty) _serverTitle = title;

      final rawProducts = data['products'];
      final out = <_ProductItem>[];

      // Laravel pluck => Map { "id": "book_name" }
      if (rawProducts is Map) {
        rawProducts.forEach((k, v) {
          final id = int.tryParse(k.toString()) ?? 0;
          final name = (v ?? '').toString().trim();
          if (id > 0 && name.isNotEmpty) out.add(_ProductItem(id: id, name: name));
        });
      } else if (rawProducts is List) {
        for (final x in rawProducts) {
          if (x is! Map) continue;
          final m = Map<String, dynamic>.from(x);
          final id = _asInt(m['id'] ?? m['product_id']);
          final name = (m['book_name'] ?? m['name'] ?? m['title'] ?? '').toString().trim();
          if (id > 0 && name.isNotEmpty) out.add(_ProductItem(id: id, name: name));
        }
      }

      out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _products.addAll(out);
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProducts = false;
        _errorProducts = true;
        _errorProductsMsg = e.toString();
      });
    }
  }

  // ---------------------------------------
  // Step 2: items list by product
  // ---------------------------------------
  Future<void> _loadItemsForProduct(_ProductItem p) async {
    setState(() {
      _selectedProduct = p;
      _loadingItems = true;
      _errorItems = false;
      _errorItemsMsg = '';
      _items.clear();
      _search.clear();
      _query = '';
    });

    try {
      // ✅ তোমার দেয়া API:
      // my-bookmarks/products/{product}
      // my-flags/products/{product}
      // my-notes/products/{product}
      final data = await _fetchFirstOk([
        '/$_base/products/${p.id}',
        '/v1/$_base/products/${p.id}',
      ]);

      dynamic rawList = data[_itemsKey];

      // notes: server key mismatch হলে fallback
      rawList ??= data['my_notes'] ?? data['doctor_notes'] ?? data['items'] ?? data['data'];

      final list = (rawList is List) ? rawList : <dynamic>[];

      final parsed = <SavedContentItem>[];
      for (final row in list) {
        if (row is! Map) continue;
        final m = Map<String, dynamic>.from(row);

        // inject product info
        m['ebook_id'] = p.id;
        m['ebook_title'] = p.name;

        // bookmarks/flags => question relation flatten
        if (m['question'] is Map) {
          final q = Map<String, dynamic>.from(m['question']);
          m['question_id'] = q['id'];
          m['question_title'] = q['question_title'];
        }

        // notes => subject/chapter/topic name flatten (তোমার response অনুযায়ী)
        if (widget.mode == SavedListMode.notes) {
          if (m['subject'] is Map) {
            final s = Map<String, dynamic>.from(m['subject']);
            m['subject_name'] = s['subject_name'] ?? s['name'];
          }
          if (m['chapter'] is Map) {
            final c = Map<String, dynamic>.from(m['chapter']);
            m['chapter_name'] = c['chapter_name'] ?? c['name'];
          }
          if (m['topic'] is Map) {
            final t = Map<String, dynamic>.from(m['topic']);
            m['topic_name'] = t['topic_name'] ?? t['name'];
          }
        }

        parsed.add(SavedContentItem.fromJsonFlexible(m));
      }

      // recent first (createdAt null হলে stable রাখবে)
      parsed.sort((a, b) {
        final ca = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final cb = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return cb.compareTo(ca);
      });

      if (!mounted) return;
      setState(() {
        _items.addAll(parsed);
        _loadingItems = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingItems = false;
        _errorItems = true;
        _errorItemsMsg = e.toString();
      });
    }
  }

  // ---------------------------------------
  // open item
  // ---------------------------------------
  void _openItem(SavedContentItem it) {
    // notes এ ট্যাপ করলে শুধু BottomSheet দেখাবে
    if (widget.mode == SavedListMode.notes) {
      _openNoteSheet(it);
      return;
    }

    // bookmarks/flags => direct open content
    _openContentPage(it);
  }

  // ✅ নতুন: কন্টেন্ট পেজ ওপেন করার আলাদা মেথড
  void _openContentPage(SavedContentItem it) {
    if (!it.canOpenContent) {
      _snack('এই আইটেমে subject/chapter/topic/content id নাই। Backend থেকে id গুলো পাঠালে direct open হবে।');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EbookContentsPage(
          ebookId: it.ebookId.toString(),
          subjectId: it.subjectId!.toString(),
          chapterId: it.chapterId!.toString(),
          topicId: it.topicId!.toString(),
          ebookName: it.ebookTitle.trim().isEmpty ? 'Ebook' : it.ebookTitle,
          subjectTitle: it.subjectTitle,
          chapterTitle: it.chapterTitle,
          topicTitle: it.topicTitle,
        ),
      ),
    );
  }

  void _openNoteSheet(SavedContentItem it) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final noteText = it.noteDetail.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.cardIconTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.sticky_note_2_rounded, color: AppColors.cardIconBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        it.contentTitle.trim().isEmpty ? 'My Note' : it.contentTitle.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_pathText(it).trim().isNotEmpty && _pathText(it) != '—') ...[
                  Text(
                    _pathText(it),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor.withOpacity(.15)),
                  ),
                  child: Text(
                    noteText.isEmpty ? 'No note text' : noteText,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        // ✅ ফিক্স: এখানে _openItem না, _openContentPage কল হবে
                        onPressed: it.canOpenContent
                            ? () {
                          Navigator.pop(context);
                          Future.microtask(() {
                            if (!mounted) return;
                            _openContentPage(it);
                          });
                        }
                            : null,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Content'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_ProductItem> get _filteredProducts {
    if (_query.isEmpty) return _products;
    return _products.where((p) => p.name.toLowerCase().contains(_query)).toList();
  }

  List<SavedContentItem> get _filteredItems {
    if (_query.isEmpty) return _items;

    if (widget.mode == SavedListMode.notes) {
      return _items.where((it) {
        final t = it.contentTitle.toLowerCase();
        final n = it.noteDetail.toLowerCase();
        return t.contains(_query) || n.contains(_query);
      }).toList();
    }

    return _items.where((it) => it.contentTitle.toLowerCase().contains(_query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _serverTitle.isNotEmpty ? _serverTitle : widget.title;

    return AppLayout(
      title: title,
      body: _selectedProduct == null ? _buildProductsView(theme) : _buildItemsView(theme),
    );
  }

  // ---------------- UI: products ----------------
  Widget _buildProductsView(ThemeData theme) {
    if (_loadingProducts) return const ShimmerListLoader(itemCount: 7);

    if (_errorProducts) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('লোড করা যায়নি', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(_errorProductsMsg, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final list = _filteredProducts;

    return Column(
      children: [
        _NiceSearchBar(controller: _search, hint: 'Search book...'),
        const SizedBox(height: 10),
        Row(
          children: [
            _CountChip(icon: _modeIcon, text: '${list.length} books'),
            const Spacer(),
            IconButton(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? Center(
            child: Text(
              'কোনো প্রোডাক্ট পাওয়া যায়নি',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          )
              : RefreshIndicator(
            onRefresh: _loadProducts,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final p = list[i];
                return _NiceSelectCard(
                  title: p.name,
                  subtitle: 'Product ID: ${p.id}',
                  leadingIcon: Icons.auto_stories_rounded,
                  trailingIcon: _modeIcon,
                  onTap: () => _loadItemsForProduct(p),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- UI: items ----------------
  Widget _buildItemsView(ThemeData theme) {
    final p = _selectedProduct!;
    final list = _filteredItems;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedProduct = null;
                  _items.clear();
                  _search.clear();
                  _query = '';
                  _loadingItems = false;
                  _errorItems = false;
                  _errorItemsMsg = '';
                });
              },
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                p.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              onPressed: _loadingItems ? null : () => _loadItemsForProduct(p),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _NiceSearchBar(
          controller: _search,
          hint: widget.mode == SavedListMode.notes ? 'Search note...' : 'Search question...',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _CountChip(icon: _modeIcon, text: '${list.length} $_countLabel'),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loadingItems
              ? const ShimmerListLoader(itemCount: 7)
              : _errorItems
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('লোড করা যায়নি', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(_errorItemsMsg, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _loadItemsForProduct(p),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
              : list.isEmpty
              ? Center(
            child: Text(
              widget.mode == SavedListMode.bookmarks
                  ? 'এই প্রোডাক্টে কোনো bookmark নেই'
                  : widget.mode == SavedListMode.flags
                  ? 'এই প্রোডাক্টে কোনো flag নেই'
                  : 'এই প্রোডাক্টে কোনো note নেই',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          )
              : RefreshIndicator(
            onRefresh: () => _loadItemsForProduct(p),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final it = list[i];

                final title = it.contentTitle.trim().isEmpty
                    ? 'Question #${it.contentId ?? '-'}'
                    : it.contentTitle.trim();

                String subtitle;
                if (widget.mode == SavedListMode.notes) {
                  final n = _excerpt(it.noteDetail);
                  final path = _pathText(it);
                  subtitle = n.isEmpty
                      ? (path == '—' ? 'Tap to view note' : path)
                      : (path == '—' ? n : '$n\n$path');
                } else {
                  subtitle = _pathText(it);
                }

                return _NiceItemCard(
                  title: title,
                  subtitle: subtitle,
                  icon: _modeIcon,
                  onTap: () => _openItem(it),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _pathText(SavedContentItem it) {
    final parts = <String>[];
    if (it.subjectTitle.trim().isNotEmpty) parts.add(it.subjectTitle.trim());
    if (it.chapterTitle.trim().isNotEmpty) parts.add(it.chapterTitle.trim());
    if (it.topicTitle.trim().isNotEmpty) parts.add(it.topicTitle.trim());
    if (parts.isNotEmpty) return parts.join('  ›  ');

    final ids = <String>[];
    if (it.subjectId != null) ids.add('S:${it.subjectId}');
    if (it.chapterId != null) ids.add('C:${it.chapterId}');
    if (it.topicId != null) ids.add('T:${it.topicId}');
    if (it.contentId != null) ids.add('Q:${it.contentId}');
    return ids.isEmpty ? '—' : ids.join('  ');
  }

  String _excerpt(String s) {
    final t = s.trim();
    if (t.isEmpty) return '';
    if (t.length <= 90) return t;
    return '${t.substring(0, 90)}...';
  }
}

// -----------------------------------------------------------------------------
// UI widgets
// -----------------------------------------------------------------------------
class _NiceSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _NiceSearchBar({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        filled: true,
        fillColor: cs.surface.withOpacity(.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary.withOpacity(.6)),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CountChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cardIconTint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardIconBlue.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.cardIconBlue),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NiceSelectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final IconData trailingIcon;
  final VoidCallback onTap;

  const _NiceSelectCard({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.trailingIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(.14)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cardIconTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(leadingIcon, color: AppColors.cardIconBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardIconTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardIconBlue.withOpacity(.20)),
                ),
                child: Row(
                  children: [
                    Icon(trailingIcon, size: 18, color: AppColors.cardIconBlue),
                    const SizedBox(width: 6),
                    Text(
                      "View",
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _NiceItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _NiceItemCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(.14)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.cardIconTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.cardIconBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle.isEmpty ? '—' : subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardIconTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardIconBlue.withOpacity(.20)),
                ),
                child: Icon(Icons.open_in_new, size: 18, color: AppColors.cardIconBlue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// helpers
// -----------------------------------------------------------------------------
class _ProductItem {
  final int id;
  final String name;

  const _ProductItem({required this.id, required this.name});
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}
