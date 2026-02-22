import 'package:flutter/foundation.dart';

class SearchItem {
  final String title;
  final String? subtitle;

  const SearchItem({required this.title, this.subtitle});
}

class SearchState {
  static final ValueNotifier<String> query = ValueNotifier<String>('');
  static final ValueNotifier<List<SearchItem>> items =
      ValueNotifier<List<SearchItem>>(<SearchItem>[]);

  static void setItems(List<SearchItem> next) {
    items.value = next;
  }
}
