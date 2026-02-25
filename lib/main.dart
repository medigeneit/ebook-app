
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ebook_project/screens/app.dart';
import 'package:ebook_project/services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');
  await LocalStorageService.init();
  if (token != null && token.isNotEmpty) {
    await LocalStorageService.setString(LocalStorageService.token, token);
  }

  // runApp(MyApp(initialRoute: token == null ? '/login' : '/'));
  runApp(MyApp(initialRoute: '/splash'));
}

