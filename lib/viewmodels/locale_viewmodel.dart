import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

// save the chosen interface language on this device
class LocaleViewModel extends ChangeNotifier {
  static const _key = 'interface_language';

  Locale? _locale;
  Locale? get locale => _locale;

  // restore the saved language when the app starts
  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final code = preferences.getString(_key);
    if (code == 'en' || code == 'zh') _locale = Locale(code!);
    notifyListeners();
  }

  // update the app first and then save the choice
  Future<void> select(Locale locale) async {
    if (_locale?.languageCode == locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, locale.languageCode);
  }
}
