import 'package:ebook_project/components/app_layout.dart';
import 'package:ebook_project/state/search_state.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: SearchState.query.value);
    _controller.addListener(_onChanged);
    SearchState.query.addListener(_syncFromState);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    SearchState.query.removeListener(_syncFromState);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final next = _controller.text.trim();
    if (SearchState.query.value == next) return;
    SearchState.query.value = next;
  }

  void _syncFromState() {
    final next = SearchState.query.value;
    if (_controller.text == next) return;
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  void _clear() {
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Search',
      showDrawer: false,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<String>(
              valueListenable: SearchState.query,
              builder: (context, q, _) {
                return TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search locally...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: q.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _clear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ValueListenableBuilder<List<SearchItem>>(
                valueListenable: SearchState.items,
                builder: (context, items, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: SearchState.query,
                    builder: (context, q, __) {
                      final query = q.trim().toLowerCase();
                      final filtered = query.isEmpty
                          ? items
                          : items
                              .where((e) =>
                                  e.title.toLowerCase().contains(query))
                              .toList();

                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            'No local data to search.',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                            ),
                          ),
                        );
                      }

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            'No results for "$q"',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0x11000000)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.menu_book_rounded, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                      if (item.subtitle != null &&
                                          item.subtitle!.isNotEmpty)
                                        Text(
                                          item.subtitle!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Colors.black45,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
