import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  // اللغة العربية هي الافتراضية
  Locale _locale = const Locale('ar', 'SA');
  Locale get locale => _locale;

  LanguageProvider() {
    print('تهيئة LanguageProvider - اللغة الافتراضية: ${_locale.languageCode}');
    _loadSavedLanguage();
  }

  // تحميل اللغة المحفوظة من التخزين المحلي
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('language_code');
      final savedCountry = prefs.getString('country_code');

      print('اللغة المحفوظة: $savedLanguage, البلد المحفوظ: $savedCountry');

      if (savedLanguage != null) {
        _locale = Locale(savedLanguage,
            savedCountry ?? (savedLanguage == 'ar' ? 'SA' : 'FR'));
        print(
            'تم تعيين اللغة المحفوظة: ${_locale.languageCode}_${_locale.countryCode}');
        notifyListeners();
      } else {
        // إذا لم يتم تخزين لغة سابقاً، قم بتخزين اللغة الافتراضية (العربية)
        await changeLanguage('ar');
        print('لم يتم العثور على لغة محفوظة، تم تعيين العربية كلغة افتراضية');
      }
    } catch (e) {
      print('خطأ في تحميل اللغة المحفوظة: $e');
      // الاستمرار باللغة الافتراضية (العربية)
    }
  }

  // تغيير اللغة
  Future<void> changeLanguage(String languageCode) async {
    String countryCode = languageCode == 'ar' ? 'SA' : 'FR';

    print('تغيير اللغة إلى: $languageCode, البلد: $countryCode');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);
      await prefs.setString('country_code', countryCode);

      _locale = Locale(languageCode, countryCode);
      print(
          'تم تغيير اللغة بنجاح إلى: ${_locale.languageCode}_${_locale.countryCode}');
      notifyListeners();
    } catch (e) {
      print('خطأ في حفظ اللغة: $e');
    }
  }

  // إعادة تعيين اللغة إلى الإعدادات الافتراضية (العربية)
  Future<void> resetToDefaultLanguage() async {
    print('إعادة تعيين اللغة إلى الافتراضية (العربية)');
    await changeLanguage('ar');
  }

  // التحقق من اللغة الحالية
  bool isArabic() => _locale.languageCode == 'ar';
  bool isFrench() => _locale.languageCode == 'fr';

  // الحصول على اسم اللغة الحالية
  String getCurrentLanguageName() {
    return isArabic() ? 'العربية' : 'Français';
  }
}
