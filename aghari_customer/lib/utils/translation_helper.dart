import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class TranslationHelper {
  // دالة للحصول على ترجمة نص
  static String getTranslatedText(BuildContext context, String key) {
    return AppLocalizations.of(context).translate(key);
  }
  
  // دالة للحصول على ترجمة مع استبدال معلمات
  static String getTranslatedTextWithParams(
    BuildContext context, 
    String key, 
    Map<String, String> params
  ) {
    return AppLocalizations.of(context).translateWithParams(key, params);
  }
  
  // دالة للحصول على ترجمة حالة العقار
  static String getPropertyStatusText(BuildContext context, String status) {
    if (status == 'forSale' || status == 'sale') {
      return AppLocalizations.of(context).translate('property_status_sale');
    } else if (status == 'forRent' || status == 'rent') {
      return AppLocalizations.of(context).translate('property_status_rent');
    }
    return AppLocalizations.of(context).translate('property_status_unknown');
  }
  
  // دالة للحصول على ترجمة نوع العقار
  static String getPropertyTypeText(BuildContext context, String type) {
    String key = 'property_type_$type';
    return AppLocalizations.of(context).translate(key);
  }
  
  // دالة للحصول على ترجمة حالة الطلب
  static String getRequestStatusText(BuildContext context, String status) {
    String key = 'status_$status';
    return AppLocalizations.of(context).translate(key);
  }
} 