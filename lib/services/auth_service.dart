import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // دالة تسجيل الدخول باستخدام رقم الهاتف وكلمة المرور
  Future<Map<String, dynamic>?> login(String phone, String password) async {
    try {
      // البحث عن المستخدم في Firestore حسب رقم الهاتف
      final querySnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      // التحقق من وجود نتائج
      if (querySnapshot.docs.isEmpty) {
        throw 'لم يتم العثور على حساب بهذا الرقم';
      }

      // الحصول على بيانات المستخدم
      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();

      // التحقق من كلمة المرور
      if (userData['password'] != password) {
        throw 'كلمة المرور غير صحيحة';
      }

      // حفظ معرف المستخدم في التخزين المحلي
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userDoc.id);
      await prefs.setString('userName', userData['name'] ?? '');
      await prefs.setString('userPhone', phone);

      // طباعة رسالة نجاح التسجيل
      print('تم تسجيل الدخول بنجاح: ${userDoc.id}');

      // إرجاع بيانات المستخدم
      return {
        'id': userDoc.id,
        'name': userData['name'],
        'phone': userData['phone'],
        'isSeller': userData['isSeller'] ?? false,
        'profileImageUrl': userData['profileImageUrl'],
      };
    } catch (e) {
      print('خطأ في تسجيل الدخول: $e');
      throw e.toString();
    }
  }

  // دالة للتحقق من حالة تسجيل الدخول
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        return null;
      }

      // الحصول على بيانات المستخدم الحالي من Firestore
      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (!docSnapshot.exists) {
        // إذا لم يعد المستخدم موجودًا، نقوم بتسجيل الخروج
        await logout();
        return null;
      }

      final userData = docSnapshot.data()!;

      return {
        'id': docSnapshot.id,
        'name': userData['name'],
        'phone': userData['phone'],
        'isSeller': userData['isSeller'] ?? false,
        'profileImageUrl': userData['profileImageUrl'],
      };
    } catch (e) {
      print('خطأ في الحصول على المستخدم الحالي: $e');
      return null;
    }
  }

  // دالة تسجيل الخروج
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
