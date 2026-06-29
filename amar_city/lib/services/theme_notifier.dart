// ThemeNotifier — Dark/Light mode toggle এর জন্য singleton ChangeNotifier
// Singleton pattern ব্যবহার করা হয়েছে যাতে পুরো app এ একটাই instance থাকে

import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  // Singleton — factory constructor প্রতিবার same instance return করে
  static final ThemeNotifier _instance = ThemeNotifier._internal();
  factory ThemeNotifier() => _instance;
  ThemeNotifier._internal();

  // বর্তমান theme state — false মানে light mode (default)
  bool _isDark = false;
  bool get isDark => _isDark;

  // Dark ও Light mode এর মধ্যে toggle করার function
  // Call হলে সব listener কে notify করা হয় → MaterialApp rebuild হয়
  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
