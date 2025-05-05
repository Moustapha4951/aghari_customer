import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property_purchase_model.dart';

class LocalStorageService {
  // مفتاح التخزين
  static const String _purchasesKey = 'localPurchases';

  // حفظ طلبات الشراء محلياً
  static Future<void> savePurchases(
      List<PropertyPurchaseModel> purchases) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // إزالة التكرار - الاحتفاظ بالطلبات الفريدة فقط، وعدم استبدال الطلبات القديمة
      List<PropertyPurchaseModel> existingPurchases = await getPurchases();
      Map<String, PropertyPurchaseModel> uniquePurchases = {};

      // إضافة الطلبات الموجودة أولاً
      for (var purchase in existingPurchases) {
        if (purchase.id != null && purchase.id!.isNotEmpty) {
          uniquePurchases[purchase.id!] = purchase;
        }
      }

      // ثم إضافة أو تحديث الطلبات الجديدة
      for (var purchase in purchases) {
        if (purchase.id != null && purchase.id!.isNotEmpty) {
          uniquePurchases[purchase.id!] = purchase;
        }
      }

      print('عدد الطلبات الفريدة بعد الدمج: ${uniquePurchases.length}');

      List<String> jsonList = uniquePurchases.values
          .map((purchase) => json.encode(purchase.toJson()))
          .toList();

      await prefs.setStringList('user_purchases', jsonList);
    } catch (e) {
      print('خطأ في حفظ الطلبات: $e');
    }
  }

  // استرجاع طلبات الشراء المحلية
  static Future<List<PropertyPurchaseModel>> getPurchases() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // استرجاع قائمة JSON من SharedPreferences
      final jsonList = prefs.getStringList('user_purchases') ?? [];

      print('تم العثور على ${jsonList.length} طلب في التخزين المحلي');

      if (jsonList.isEmpty) {
        print('التخزين المحلي فارغ - لا توجد طلبات محفوظة');
        return [];
      }

      // طباعة عينة من البيانات المخزنة
      if (jsonList.isNotEmpty) {
        print(
            'عينة من البيانات المخزنة محلياً: ${jsonList[0].substring(0, min(100, jsonList[0].length))}...');
      }

      // تحويل كل عنصر JSON إلى نموذج طلب
      final purchases = jsonList
          .map((jsonString) {
            try {
              final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
              return PropertyPurchaseModel.fromJson(jsonMap);
            } catch (e) {
              print('خطأ في تحويل طلب محلي: $e');
              return null;
            }
          })
          .where((p) => p != null)
          .cast<PropertyPurchaseModel>()
          .toList();

      print('تم تحويل البيانات بنجاح - ${purchases.length} طلب صالح');

      // طباعة تفاصيل أكثر عن الطلبات المسترجعة
      for (var purchase in purchases) {
        print(
            'معرف الطلب: ${purchase.id}, العنوان: ${purchase.propertyTitle}, الحالة: ${purchase.status}');
      }

      return purchases;
    } catch (e) {
      print('خطأ في استرجاع الطلبات المحلية: $e');
      return [];
    }
  }

  // إضافة طلب جديد إلى التخزين المحلي
  static Future<void> addPurchase(PropertyPurchaseModel purchase) async {
    try {
      // جلب الطلبات الحالية
      List<PropertyPurchaseModel> purchases = await getPurchases();

      // التحقق من عدم وجود الطلب مسبقاً في قائمة الطلبات
      bool isDuplicate = purchases.any((p) =>
          p.id == purchase.id ||
          (p.propertyId == purchase.propertyId &&
              DateTime.now().difference(p.purchaseDate).inMinutes < 2));

      // إذا لم يكن هناك تكرار، أضف الطلب
      if (!isDuplicate) {
        purchases.add(purchase);
        await savePurchases(purchases);
      } else {
        print('تم تجاهل الطلب المكرر: ${purchase.id}');
      }
    } catch (e) {
      print('خطأ في إضافة طلب محلي: $e');
      throw 'فشل حفظ الطلب محلياً: $e';
    }
  }

  // مسح التخزين المحلي واستبداله بطلبات معينة
  static Future<void> resetAndSetPurchases(
      List<PropertyPurchaseModel> purchases) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // مسح الطلبات المخزنة
      await prefs.remove('user_purchases');
      print('تم مسح جميع الطلبات من التخزين المحلي');

      // حفظ الطلبات الجديدة
      List<String> jsonList =
          purchases.map((purchase) => json.encode(purchase.toJson())).toList();

      await prefs.setStringList('user_purchases', jsonList);
      print('تم حفظ ${jsonList.length} طلب جديد في التخزين المحلي');
    } catch (e) {
      print('خطأ في إعادة تعيين التخزين المحلي: $e');
    }
  }
}
