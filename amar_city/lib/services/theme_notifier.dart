// Flutter material design import
import 'package:flutter/material.dart';

// ThemeNotifier — Dark/Light mode toggle এর জন্য singleton class
class ThemeNotifier extends ChangeNotifier {
  // Singleton pattern — পুরো app এ একটাই instance থাকবে
  static final ThemeNotifier _instance = ThemeNotifier._internal();
  factory ThemeNotifier() => _instance;
  ThemeNotifier._internal();

  // বর্তমানে dark mode চালু আছে কিনা — শুরুতে false (light mode)
  bool _isDark = false;
  bool get isDark => _isDark;

  // Dark/Light mode switch করার function
  // toggle() call করলে mode পরিবর্তন হবে এবং listeners notify হবে
  void toggle() {
    _isDark = !_isDark;
    // সব listener কে জানানো হচ্ছে যে theme পরিবর্তন হয়েছে
    notifyListeners();
  }
}
