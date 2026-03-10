import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _langKey = 'language';
  static Map<String, String> _localizedStrings = {};
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('ta'));

  static Future<void> load(Locale locale) async {
    final ByteData data = await rootBundle.load('assets/lang/${locale.languageCode}.json');
    final String jsonString = utf8.decode(data.buffer.asUint8List());
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  static String tr(String key) {
    return _localizedStrings[key] ?? key;
  }

  static bool get isTamil => localeNotifier.value.languageCode == 'ta';



  static String pickTaEn(String ta, String en) {
    final taTrim = ta.trim();
    final enTrim = en.trim();
    if (isTamil) {
      if (taTrim.isNotEmpty) return taTrim;
      if (enTrim.isNotEmpty) return enTrim;
    } else {
      if (enTrim.isNotEmpty) return enTrim;
      if (taTrim.isNotEmpty) return taTrim;
    }
    return taTrim.isNotEmpty ? taTrim : enTrim;
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_langKey) ?? 'ta';
    localeNotifier.value = Locale(savedLang);
    await load(localeNotifier.value);
  }

  static Future<void> changeLocale(String languageCode) async {
    final locale = Locale(languageCode);
    await load(locale);
    localeNotifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, languageCode);
  }
}
