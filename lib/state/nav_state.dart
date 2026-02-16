import 'package:flutter/foundation.dart';

/// 0 = Home, 1 = My Ebooks, 2 = Profile
class NavState {
  static final ValueNotifier<int> index = ValueNotifier<int>(0);
}
