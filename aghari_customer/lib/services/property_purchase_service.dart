import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/property_purchase_model.dart';
import '../services/local_storage_service.dart';
import '../utils/firebase_collections.dart';

class PropertyPurchaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String collectionName = FirebaseCollections.propertyPurchases;

  Future<Map<String, String>> _getUserInfo(String userId) async {
    String userName = '';
    String userPhone = '';

    try {
      // 1. محاولة جلب البيانات من جدول users
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        userName = userData['name'] ?? '';
        userPhone = userData['phone'] ?? '';
        print(
            'تم جلب البيانات من users - الاسم: $userName، الهاتف: $userPhone');
      }

      // 2. إذا لم نجد البيانات، نحاول من userProfiles
      if (userName.isEmpty || userPhone.isEmpty) {
        final profileDoc =
            await _firestore.collection('userProfiles').doc(userId).get();
        if (profileDoc.exists) {
          final profileData = profileDoc.data()!;
          if (userName.isEmpty) userName = profileData['name'] ?? '';
          if (userPhone.isEmpty) userPhone = profileData['phone'] ?? '';
          print(
              'تم جلب البيانات من userProfiles - الاسم: $userName، الهاتف: $userPhone');
        }
      }

      // 3. إذا لم نجد، نأخذ من معلومات المستخدم الأساسية
      if (userName.isEmpty) {
        final currentUser = FirebaseAuth.instance.currentUser;
        userName = currentUser?.displayName ?? 'مستخدم';
      }

      print('البيانات النهائية - الاسم: $userName، الهاتف: $userPhone');
      return {'name': userName, 'phone': userPhone};
    } catch (e) {
      print('خطأ في جلب بيانات المستخدم: $e');
      return {'name': 'مستخدم', 'phone': ''};
    }
  }

  // إضافة طلب شراء عقار جديد
  Future<String> createPurchaseRequest(PropertyPurchaseModel purchase) async {
    try {
      print('🔥 بدء عملية إنشاء طلب شراء جديد...');

      print('🔥 معرف المستخدم في طلب الشراء: ${purchase.userId}');
      print('🔥 معرف العقار: ${purchase.propertyId}');
      print('🔥 معرف المالك: ${purchase.ownerId}');
      print('🔥 اسم المالك: ${purchase.ownerName}');
      print('🔥 هاتف المالك: ${purchase.ownerPhone}');

      // تحويل النموذج إلى خريطة مع التحقق من القيم
      final Map<String, dynamic> purchaseData = {
        'userId': purchase.userId,
        'userName': purchase.userName,
        'userPhone': purchase.userPhone,
        'propertyId': purchase.propertyId,
        'propertyTitle': purchase.propertyTitle,
        'propertyPrice': purchase.propertyPrice,
        'propertyType': purchase.propertyType,
        'propertyStatus': purchase.propertyStatus,
        'city': purchase.city,
        'district': purchase.district,
        'propertyArea': purchase.propertyArea,
        'bedrooms': purchase.bedrooms,
        'bathrooms': purchase.bathrooms,
        'notes': purchase.notes,
        'status': purchase.status,
        'purchaseDate': FieldValue.serverTimestamp(),
        'ownerId': purchase.ownerId,
        'ownerName': purchase.ownerName,
        'ownerPhone': purchase.ownerPhone,
      };

      print('🔥 بيانات الطلب للإضافة:');
      purchaseData.forEach((key, value) {
        print('$key: $value (${value.runtimeType})');
      });

      // إضافة طلب الشراء في مجموعة propertyPurchases
      final docRef = await FirebaseFirestore.instance
          .collection('propertyPurchases')
          .add(purchaseData);

      print(
          '✅ تم إضافة الطلب في مجموعة propertyPurchases بنجاح! معرف الوثيقة: ${docRef.id}');

      // إضافة نفس الطلب إلى مجموعة sellerRequests للظهور في شاشة طلبات البائع
      try {
        // تجهيز البيانات لمجموعة sellerRequests
        final sellerRequestData = {
          'userId': purchase.userId,
          'userName': purchase.userName,
          'phone': purchase.userPhone, // مهم: استخدام phone وليس userPhone
          'propertyId': purchase.propertyId,
          'propertyTitle': purchase.propertyTitle,
          'status': purchase.status,
          'createdAt': FieldValue.serverTimestamp(),
          'message': purchase.notes,
          'sellerId': purchase.ownerId, // مهم: إضافة معرف البائع صراحة
          'sellerPhone':
              purchase.ownerPhone, // مهم: إضافة رقم هاتف البائع صراحة
        };

        print('🔥 بيانات طلب البائع للإضافة:');
        sellerRequestData.forEach((key, value) {
          print('$key: $value (${value.runtimeType})');
        });

        // إضافة في مجموعة sellerRequests
        final sellerDocRef = await FirebaseFirestore.instance
            .collection('sellerRequests')
            .add(sellerRequestData);

        print(
            '✅ تم إضافة الطلب في مجموعة sellerRequests بنجاح! معرف الوثيقة: ${sellerDocRef.id}');
      } catch (sellerRequestError) {
        print(
            '⚠️ خطأ أثناء إضافة الطلب إلى مجموعة sellerRequests: $sellerRequestError');
        // نستمر حتى لو فشلت هذه العملية، لأن الطلب تم إضافته بالفعل في propertyPurchases
      }

      // التحقق من وجود الوثيقة مباشرة بعد إنشائها
      final addedDoc = await FirebaseFirestore.instance
          .collection('propertyPurchases')
          .doc(docRef.id)
          .get();

      if (addedDoc.exists) {
        print(
            '✅✅ تم التأكد من وجود الوثيقة في مجموعة propertyPurchases بنجاح!');
        print('✅✅ بيانات الوثيقة المضافة: ${addedDoc.data()}');
      } else {
        print('⚠️ تم إنشاء المعرف لكن الوثيقة غير موجودة!');
      }
      
      return docRef.id;
    } catch (e) {
      print('❌ خطأ في إنشاء طلب الشراء: $e');
      rethrow;
    }
  }

  // الحصول على معرف فريد للجهاز
  Future<String> _getDeviceId() async {
    try {
      // يمكن استخدام مكتبة device_info_plus للحصول على معرف فريد للجهاز
      // لكن للتبسيط سنستخدم تاريخ ووقت الطلب
      return DateTime.now().millisecondsSinceEpoch.toString();
    } catch (e) {
      return DateTime.now().toString();
    }
  }

  // جلب طلبات المستخدم من Firebase
  Future<List<PropertyPurchaseModel>> getUserPurchases() async {
    List<PropertyPurchaseModel> purchases = [];
    try {
      // الحصول على معرف المستخدم الحالي
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      print('جلب طلبات المستخدم بالمعرف: $userId');

      if (userId == null) {
        print('لا يوجد مستخدم مسجل الدخول حاليًا');
        return [];
      }

      // جلب الطلبات من Firebase
      final QuerySnapshot purchasesSnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .get();

      print('تم جلب ${purchasesSnapshot.docs.length} طلب من Firebase');

      // تحويل المستندات إلى نماذج
      for (var doc in purchasesSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // طباعة بيانات الطلب للتشخيص
          print(
              'معرف الطلب: ${doc.id}, بيانات: ${data.toString().substring(0, min(50, data.toString().length))}...');

          final purchase = PropertyPurchaseModel.fromMap(data, doc.id);
          purchases.add(purchase);
        } catch (docError) {
          print('خطأ في تحويل وثيقة Firestore: $docError');
        }
      }
    } catch (e) {
      print('خطأ في جلب طلبات المستخدم: $e');
      throw e;
    }
    return purchases;
  }

  // جلب جميع طلبات المستخدم (بغض النظر عن المعرف) - للاختبار
  Future<List<PropertyPurchaseModel>> getAllPurchases() async {
    List<PropertyPurchaseModel> purchases = [];
    try {
      print('جلب جميع طلبات الشراء من Firebase للاختبار');

      // جلب الطلبات من Firebase
      final QuerySnapshot purchasesSnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy('purchaseDate', descending: true)
          .limit(20) // جلب أحدث 20 طلب فقط
          .get();

      print('تم جلب ${purchasesSnapshot.docs.length} طلب من Firebase');

      // تحويل المستندات إلى نماذج
      for (var doc in purchasesSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final purchase = PropertyPurchaseModel.fromMap(data, doc.id);
          print(
              'معرف المستخدم: ${purchase.userId}, معرف الطلب: ${purchase.id}');
          purchases.add(purchase);
        } catch (docError) {
          print('خطأ في تحويل وثيقة Firestore: $docError');
        }
      }
    } catch (e) {
      print('خطأ في جلب جميع الطلبات: $e');
    }
    return purchases;
  }

  // وظيفة getUserPurchasesFromFirebase للتحقق من تحديثات الحالة
  Future<List<PropertyPurchaseModel>> getUserPurchasesFromFirebase() async {
    try {
      print('🔄 بدء جلب طلبات المستخدم مباشرة من Firebase...');
      final startTime = DateTime.now();

      // الحصول على معرف المستخدم الحالي
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      print('👤 الجلب للمستخدم: $userId');

      if (userId == null) {
        print(
            '⚠️ لا يوجد مستخدم مسجل الدخول، محاولة جلب جميع الطلبات للاختبار');
        return await getAllPurchases();
      }

      // جلب الطلبات من Firebase مع طلب التحديثات الأخيرة
      print(
          '🔥 استعلام: collection=$collectionName, userId=$userId, orderBy=purchaseDate (desc)');
      final QuerySnapshot purchasesSnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .get(const GetOptions(
              source: Source.server)); // إجبار طلب البيانات من الخادم

      final fetchDuration = DateTime.now().difference(startTime).inMilliseconds;
      print('⏱️ استغرق استعلام Firebase: $fetchDuration مللي ثانية');
      print('📊 عدد النتائج: ${purchasesSnapshot.docs.length} وثيقة');

      // تحويل المستندات إلى نماذج
      List<PropertyPurchaseModel> purchases = [];
      for (var doc in purchasesSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // طباعة بيانات الطلب للتشخيص
          final status = data['status'] ?? 'unknown';
          print('📄 بيانات الطلب ${doc.id}: الحالة=$status');

          // إنشاء نموذج من البيانات
          final purchase = PropertyPurchaseModel.fromMap(data, doc.id);
          purchases.add(purchase);

          // طباعة تشخيصية للتحقق من الحقول المهمة
          print(
              '📌 تم إضافة طلب: ${purchase.id}, الحالة: ${purchase.status}, العنوان: ${purchase.propertyTitle}');
          if (data.containsKey('adminNotes') && data['adminNotes'] != null) {
            print(
                '📝 الطلب ${purchase.id} يحتوي على ملاحظات إدارية: ${data['adminNotes']}');
          }
        } catch (docError) {
          print('❌ خطأ في معالجة وثيقة Firestore: ${doc.id}, الخطأ: $docError');
          print('❌ البيانات التي سببت الخطأ: ${doc.data()}');
        }
      }

      final totalDuration = DateTime.now().difference(startTime).inMilliseconds;
      print(
          '✅ تم جلب وتحويل ${purchases.length} طلب في $totalDuration مللي ثانية');

      // ترتيب الطلبات حسب التاريخ (من الأحدث للأقدم)
      purchases.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

      return purchases;
    } catch (e) {
      print('❌ خطأ في جلب تحديثات الطلبات من Firebase: $e');
      return [];
    }
  }

  // إلغاء طلب شراء
  Future<void> cancelPurchase(String purchaseId) async {
    try {
      // تخطي الطلبات المحلية التي تبدأ بـ 'local_'
      if (purchaseId.startsWith('local_')) {
        print('طلب محلي، لا يلزم حذفه من Firebase');
        return;
      }
      
      print('جاري إلغاء الطلب من Firestore: $purchaseId');
      
      // تحديث حالة الطلب إلى 'cancelled' بدلاً من حذفه
      await _firestore.collection(collectionName).doc(purchaseId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('تم تحديث حالة الطلب إلى ملغى بنجاح');
    } catch (e) {
      print('خطأ في إلغاء الطلب من Firestore: $e');
      throw 'فشل إلغاء الطلب: $e';
    }
  }

  // دالة لاختبار الاتصال بقاعدة البيانات وإضافة وثيقة اختبار
  Future<bool> testFirestoreConnection() async {
    try {
      print('🧪 بدء اختبار الاتصال بـ Firestore...');

      // بيانات اختبار بسيطة
      final testData = {
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'اختبار الاتصال بـ Firestore',
      };

      print('🧪 محاولة إضافة بيانات اختبار إلى مجموعة propertyPurchases...');

      // محاولة إضافة وثيقة اختبار
      final docRef = await FirebaseFirestore.instance
          .collection('propertyPurchases')
          .add(testData);

      print('✅ تم إضافة وثيقة الاختبار بنجاح! المعرف: ${docRef.id}');

      // التحقق من وجود الوثيقة
      final addedDoc = await FirebaseFirestore.instance
          .collection('propertyPurchases')
          .doc(docRef.id)
          .get();
      
      if (addedDoc.exists) {
        print('✅ تم التأكد من وجود وثيقة الاختبار!');

        // حذف وثيقة الاختبار بعد التأكد من نجاح العملية
        await FirebaseFirestore.instance
            .collection('propertyPurchases')
            .doc(docRef.id)
            .delete();

        print('🗑️ تم حذف وثيقة الاختبار');
        return true;
      } else {
        print('⚠️ لم يتم العثور على وثيقة الاختبار!');
        return false;
      }
    } catch (e) {
      print('❌ خطأ في اختبار الاتصال بـ Firestore: $e');
      return false;
    }
  }
} 
