import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Future<bool> load() async {
    try {
      // تحميل ملفات الترجمة من الأصول
      String jsonString = await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
      
      print('تم تحميل ملف اللغة: ${locale.languageCode}');
      return true;
    } catch (e) {
      print('خطأ في تحميل ملفات اللغة: $e');
      
      // في حالة الفشل، استخدم اللغة العربية كاحتياطي
      if (locale.languageCode != 'ar') {
        try {
          String jsonString = await rootBundle.loadString('assets/lang/ar.json');
          Map<String, dynamic> jsonMap = json.decode(jsonString);
          
          _localizedStrings = jsonMap.map((key, value) {
            return MapEntry(key, value.toString());
          });
          
          print('تم تحميل اللغة الاحتياطية (العربية)');
          return true;
        } catch (e) {
          print('فشل تحميل اللغة الاحتياطية: $e');
          _localizedStrings = {};
          return false;
        }
      }
      
      _localizedStrings = {};
      return false;
    }
  }

  String translate(String key) {
    if (!_localizedStrings.containsKey(key)) {
      print('مفتاح غير مترجم: $key');
    }
    return _localizedStrings[key] ?? key;
  }

  bool isArabic() {
    return locale.languageCode == 'ar';
  }

  bool isFrench() {
    return locale.languageCode == 'fr';
  }

  String translateWithParams(String key, Map<String, String> params) {
    String text = translate(key);
    params.forEach((paramKey, paramValue) {
      text = text.replaceAll('{$paramKey}', paramValue);
    });
    return text;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // اللغات المدعومة
    return ['ar', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
} 