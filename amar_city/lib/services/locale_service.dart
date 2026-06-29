// LocaleService — app এর language (locale) পরিবর্তন ও সংরক্ষণের জন্য service
// shared_preferences ব্যবহার করে selected language app restart এর পরেও মনে থাকে

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  // Default locale — English দিয়ে শুরু হবে
  Locale _locale = const Locale('en');

  // বর্তমান locale return করে
  Locale get locale => _locale;

  // বাংলা selected আছে কিনা check করার helper
  bool get isBangla => _locale.languageCode == 'bn';

  LocaleService() {
    // Constructor এ saved locale load করা হচ্ছে
    _loadSaved();
  }

  // SharedPreferences থেকে previously saved locale load করা
  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale') ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  // Locale code disk এ save করা — app restart এ কাজে আসবে
  Future<void> _save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', code);
  }

  // English এ switch করা
  void setEnglish() {
    _locale = const Locale('en');
    _save('en');
    notifyListeners();
  }

  // বাংলায় switch করা
  void setBangla() {
    _locale = const Locale('bn');
    _save('bn');
    notifyListeners();
  }

  // English ও বাংলার মধ্যে toggle করা
  void toggle() {
    _locale = isBangla ? const Locale('en') : const Locale('bn');
    _save(_locale.languageCode);
    notifyListeners();
  }
}

// Global singleton instance — যেকোনো file থেকে localeService.toggle() call করা যাবে
final localeService = LocaleService();
