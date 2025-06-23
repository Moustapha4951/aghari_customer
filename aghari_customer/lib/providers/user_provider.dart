import '../providers/property_purchase_provider.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../providers/property_request_provider.dart';
import '../services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  final _prefs = SharedPreferences.getInstance();
  final _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  get user => _currentUser;

  // تحقق من وجود جلسة مستخدم محفوظة
  Future<bool> checkUserSession() async {
    try {
      print('🔍 التحقق من جلسة المستخدم...');

      // استخدام التخزين المحلي فقط بدون Firebase Auth
      final prefs = await _prefs;
      final userId = prefs.getString('userId');

      print('💾 معرف المستخدم في التخزين المحلي: ${userId ?? 'غير موجود'}');

      if (userId == null || userId.isEmpty) {
        _currentUser = null;
        notifyListeners();
        return false;
      }

      // تحميل بيانات المستخدم من Firestore
      print('🔄 جلب بيانات المستخدم من Firestore...');
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        print('⚠️ وثيقة المستخدم غير موجودة في Firestore');
        _currentUser = null;
        notifyListeners();
        return false;
      }

      final userData = doc.data()!;
      print('✅ تم العثور على بيانات المستخدم: ${doc.id}');

      // تحديث المستخدم الحالي
      _currentUser = UserModel.fromJson({
        'id': doc.id,
        ...userData,
      });

      print('👤 تم تحميل بيانات المستخدم الحالي:');
      print('   - الاسم: ${_currentUser!.name}');
      print('   - الهاتف: ${_currentUser!.phone}');
      print('   - بائع: ${_currentUser!.isSeller ? 'نعم' : 'لا'}');

      // التحقق من وجود إشعار جديد للموافقة على البائع
      if (userData['hasNewSellerApproval'] == true) {
        print('🎉 تم اكتشاف موافقة جديدة على طلب البائع!');

        // حفظ المعلومات محلياً
        await prefs.setBool('is_seller_approved', true);

        // تشغيل الإشعار المحلي مباشرة
        final notificationService = NotificationService();
        await notificationService.showNotification(
          id: 12345,
          title: 'تهانينا! تم قبول طلبك كبائع',
          body: 'يمكنك الآن إضافة عقارات للبيع ونشرها على منصة عقاري',
          payload: 'seller_approval',
        );

        // إعادة تعيين الحقل في Firestore
        await _firestore.collection('users').doc(userId).update({
          'hasNewSellerApproval': false,
        });
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('❌ خطأ في التحقق من جلسة المستخدم: $e');
      _currentUser = null;
      notifyListeners();
      return false;
    }
  }

  // تحميل بيانات المستخدم من Firestore
  Future<bool> loadUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson({
          'id': doc.id,
          ...doc.data()!,
        });
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error loading user data: $e');
      return false;
    }
  }

  // تسجيل الدخول وحفظ الجلسة
  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔑 محاولة تسجيل الدخول للمستخدم: هاتف=$phone');

      final querySnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .where('password', isEqualTo: password)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final userId = querySnapshot.docs.first.id;

        print('✅ تم العثور على المستخدم: $userId');

        _currentUser = UserModel.fromJson({
          'id': userId,
          ...userData,
        });

        print('👤 معلومات المستخدم:');
        print('   - الاسم: ${_currentUser!.name}');
        print('   - الهاتف: ${_currentUser!.phone}');
        print('   - بائع: ${_currentUser!.isSeller ? 'نعم' : 'لا'}');

        // حفظ معرف المستخدم في التخزين المحلي
        final prefs = await _prefs;
        await prefs.setString('userId', userId);
        print('💾 تم حفظ معرف المستخدم في التخزين المحلي: $userId');

        notifyListeners();

        // تسجيل توكن الإشعارات للمستخدم
        await NotificationService().saveUserToken(_currentUser!.id);
        print('🔔 تم تسجيل توكن الإشعارات للمستخدم');

        _isLoading = false;
        notifyListeners();
        return true;
      }

      print('❌ فشل تسجيل الدخول: لم يتم العثور على المستخدم');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('❌ خطأ أثناء تسجيل الدخول: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // إضافة طريقة لتعيين معرف المستخدم في PropertyProvider و PropertyRequestProvider
  void setUserIdInProviders(BuildContext context) {
    try {
      if (_currentUser == null) {
        print('⚠️ تحذير: المستخدم الحالي فارغ في setUserIdInProviders');
        return;
      }

      final userId = _currentUser!.id;
      print('🔄 تعيين معرف المستخدم في المزودين: $userId');

      // PropertyProvider
      try {
        final propertyProvider =
            Provider.of<PropertyProvider>(context, listen: false);
        print('🔄 تعيين معرف المستخدم في PropertyProvider: $userId');
        propertyProvider.currentUserId = userId;

        // تأكد من تحميل المفضلة بعد التعيين مباشرة
        print('🔄 تحميل المفضلة بعد تعيين المستخدم');
        propertyProvider.loadFavorites();
      } catch (e) {
        print('❌ خطأ في تعيين userId في PropertyProvider: $e');
      }

      // PropertyRequestProvider
      try {
        final propertyRequestProvider =
            Provider.of<PropertyRequestProvider>(context, listen: false);
        propertyRequestProvider.setCurrentUserId(userId);
      } catch (e) {
        print('خطأ في تعيين userId في PropertyRequestProvider: $e');
      }

      // PropertyPurchaseProvider - مع معالجة أفضل للخطأ
      try {
        final purchaseProvider =
            Provider.of<PropertyPurchaseProvider>(context, listen: false);
        if (purchaseProvider != null) {
          // استدعاء الدالة بعد التأكد من وجودها في الملف
          purchaseProvider.setUserId(userId);
        }
      } catch (e) {
        print('خطأ في تعيين userId في PropertyPurchaseProvider: $e');
        // استمر رغم الخطأ
      }

      print('تم تعيين معرف المستخدم في جميع المزودين بنجاح');
    } catch (e) {
      print('❌ خطأ في setUserIdInProviders: $e');
    }
  }

  // دالة جديدة للتحقق من معرف المستخدم في جميع المزودين
  Future<void> verifyUserIdInProviders(BuildContext context) async {
    if (_currentUser == null) {
      print('⚠️ لا يوجد مستخدم حالي للتحقق من هويته');
      return;
    }

    print('🔍 التحقق من معرف المستخدم في المزودين...');

    try {
      // التحقق من PropertyProvider
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      final providerUserId = propertyProvider.currentUserId;

      print('👤 معرف المستخدم في UserProvider: ${_currentUser!.id}');
      print('👤 معرف المستخدم في PropertyProvider: $providerUserId');

      if (providerUserId != _currentUser!.id) {
        print('⚠️ عدم تطابق معرف المستخدم! إعادة تعيين المعرف...');
        propertyProvider.currentUserId = _currentUser!.id;
        await propertyProvider.loadFavorites();
      } else {
        print('✅ معرف المستخدم متطابق في PropertyProvider');
      }
    } catch (e) {
      print('❌ خطأ في التحقق من معرف المستخدم: $e');
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    try {
      // إلغاء تسجيل توكن الإشعارات
      if (_currentUser != null) {
        await NotificationService().removeUserToken(_currentUser!.id);
      }

      _currentUser = null;
      final prefs = await _prefs;
      await prefs.remove('userId');

      // يمكن إضافة منطق لإزالة معرف المستخدم من المزودات الأخرى هنا أيضًا

      notifyListeners();
    } catch (e) {
      print('خطأ في تسجيل الخروج: $e');
    }
  }

  // طلب أن تصبح بائعًا
  Future<void> requestToBeSeller() async {
    if (_currentUser == null) return;

    try {
      // إنشاء طلب جديد في Firestore
      await _firestore.collection('sellerRequests').add({
        'userId': _currentUser!.id,
        'userName': _currentUser!.name,
        'userPhone': _currentUser!.phone,
        'requestDate': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, approved, rejected
      });
    } catch (e) {
      print('خطأ في تقديم طلب أن تصبح بائعًا: $e');
      rethrow;
    }
  }

  // تحديث حالة البائع محليًا
  Future<void> setSellerStatus(bool isSeller) async {
    if (_currentUser == null) return;

    try {
      // تحديث في Firestore
      await _firestore.collection('users').doc(_currentUser!.id).update({
        'isSeller': isSeller,
      });

      // تحديث النموذج المحلي
      _currentUser = UserModel(
        id: _currentUser!.id,
        name: _currentUser!.name,
        phone: _currentUser!.phone,
        password: _currentUser!.password,
        imageUrl: _currentUser!.imageUrl,
        isSeller: isSeller,
      );

      notifyListeners();
    } catch (e) {
      print('خطأ في تحديث حالة البائع: $e');
      rethrow;
    }
  }

  // تعيين المستخدم الحالي بشكل مباشر (لإصلاح مشكلات تسجيل الدخول)
  Future<void> updateLocalUser(UserModel user) async {
    try {
      print('🔄 تعيين المستخدم الحالي مباشرة: ${user.id}');

      // تعيين المستخدم الحالي
      _currentUser = user;

      // حفظ معرف المستخدم في التخزين المحلي
      final prefs = await _prefs;
      await prefs.setString('userId', user.id);

      print('✅ تم تعيين المستخدم بنجاح:');
      print('   - الاسم: ${user.name}');
      print('   - الهاتف: ${user.phone}');
      print('   - بائع: ${user.isSeller ? 'نعم' : 'لا'}');

      notifyListeners();
    } catch (e) {
      print('❌ خطأ في تعيين المستخدم المحلي: $e');
      throw e;
    }
  }

  // إضافة دالة refreshUser للتحديث الصحيح لبيانات المستخدم
  Future<void> refreshUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('تحديث بيانات المستخدم: ${firebaseUser.uid}');

      // جلب بيانات المستخدم من Firestore
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        print('لم يتم العثور على بيانات المستخدم في Firestore');
        _currentUser = null;
      } else {
        final userData = userDoc.data()!;

        // تحويل البيانات إلى نموذج المستخدم
        _currentUser = UserModel(
          id: firebaseUser.uid,
          name: userData['name'] ?? firebaseUser.displayName ?? 'مستخدم',
          phone: userData['phone'] ?? firebaseUser.phoneNumber ?? '',
          imageUrl: userData['imageUrl'],
          isSeller: userData['isSeller'] ?? false,
          password: '',
        );

        print('تم تحديث بيانات المستخدم بنجاح: ${_currentUser!.name}');
      }
    } catch (e) {
      print('خطأ في تحديث بيانات المستخدم: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // إضافة دالة لتعيين بيانات المستخدم الحالي من خدمة المصادقة
  Future<void> setCurrentUser(Map<String, dynamic> userData) async { // Changed signature to Future<void>
    try {
      // تحويل البيانات إلى نموذج المستخدم
      _currentUser = UserModel(
        id: userData['id'],
        name: userData['name'] ?? '',
        phone: userData['phone'] ?? '',
        password: '', // لا تخزن كلمة المرور في الذاكرة
        imageUrl: userData['profileImageUrl'],
        isSeller: userData['isSeller'] ?? false,
      );

      // حفظ معرف المستخدم في التخزين المحلي
      final prefs = await _prefs;
      await prefs.setString('userId', _currentUser!.id);

      // تحديث واجهة المستخدم
      notifyListeners();

      // تسجيل توكن الإشعارات للمستخدم
      await NotificationService().saveUserToken(_currentUser!.id);

      print('تم تعيين المستخدم الحالي: ${_currentUser!.name}');
    } catch (e) {
      print('خطأ في تعيين المستخدم الحالي: $e');
      // في حالة حدوث خطأ، تأكد من عدم وجود مستخدم محلي
      _currentUser = null;
      notifyListeners();
    }
  }

  // إضافة دالة للتحقق إذا كان يجب عرض شاشة الترحيب
  Future<bool> shouldShowWelcomeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

    // إذا كان المستخدم قد سجل مؤخراً ولم يشاهد شاشة الترحيب بعد
    if (_currentUser != null && !hasSeenWelcome) {
      return true;
    }

    return false;
  }

  // إضافة دالة للتحقق مما إذا كان يجب عرض شاشة ترحيب البائعين
  Future<bool> shouldShowSellerWelcomeScreen() async {
    try {
      // لا نعرض شاشة الترحيب إذا لم يكن هناك مستخدم مسجل
      if (_currentUser == null) {
        return false;
      }

      // لا نعرض شاشة الترحيب إذا كان المستخدم بائعاً بالفعل
      if (_currentUser!.isSeller) {
        return false;
      }

      // تحقق مما إذا كان المستخدم قد رأى شاشة الترحيب من قبل
      final prefs = await SharedPreferences.getInstance();
      final hasSeenSellerWelcome =
          prefs.getBool('has_seen_seller_welcome') ?? false;

      // حساب الوقت المنقضي منذ آخر تسجيل دخول
      final lastLoginTime = prefs.getInt('last_login_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastLogin = currentTime - lastLoginTime;

      // عرض شاشة الترحيب إذا مر أكثر من 3 أيام منذ آخر تسجيل دخول
      // ولم يشاهد المستخدم شاشة الترحيب من قبل (أو مر وقت طويل منذ آخر مشاهدة)
      final threeDaysInMillis = 3 * 24 * 60 * 60 * 1000;

      if (!hasSeenSellerWelcome && timeSinceLastLogin > threeDaysInMillis) {
        return true;
      }

      return false;
    } catch (e) {
      print('خطأ في التحقق من شاشة ترحيب البائعين: $e');
      return false;
    }
  }

  // تحديث وقت آخر تسجيل دخول
  Future<void> updateLastLoginTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_login_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('خطأ في تحديث وقت آخر تسجيل دخول: $e');
    }
  }

  // تعيين مستخدم اختبار مباشرة (للحل السريع فقط)
  Future<bool> setTestUser() async {
    try {
      print('🔧 تعيين مستخدم اختبار مباشرة...');

      // استرجاع معرف المستخدم من التخزين المحلي
      final prefs = await _prefs;
      String userId = prefs.getString('userId') ?? '';

      // إذا لم يكن هناك معرف مستخدم، نستخدم قيمة افتراضية
      if (userId.isEmpty) {
        userId = '000test123456789';
        await prefs.setString('userId', userId);
        print('🔧 تم تعيين معرف مستخدم اختبار افتراضي: $userId');
      } else {
        print('🔧 تم استخدام معرف المستخدم الموجود: $userId');
      }

      // إنشاء مستخدم اختبار
      _currentUser = UserModel(
        id: userId,
        name: 'مستخدم اختبار',
        phone: '0500000000',
        password: '',
        imageUrl: '',
        isSeller: true,
      );

      print('✅ تم تعيين مستخدم اختبار بنجاح:');
      print('   - المعرف: ${_currentUser!.id}');
      print('   - الاسم: ${_currentUser!.name}');

      notifyListeners();
      return true;
    } catch (e) {
      print('❌ خطأ في تعيين مستخدم اختبار: $e');
      return false;
    }
  }
}
