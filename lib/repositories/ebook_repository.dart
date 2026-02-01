import 'package:flutter/foundation.dart';

import '../models/ebook.dart';

class EbookRepository {
  EbookRepository._();

  static final EbookRepository instance = EbookRepository._();

  final ValueNotifier<List<Ebook>> ebooks = ValueNotifier<List<Ebook>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

  void setLoading(bool value) {
    isLoading.value = value;
  }

  void updateEbooks(List<Ebook> newList) {
    ebooks.value = List.unmodifiable(newList);
    isLoading.value = false;
  }
}
