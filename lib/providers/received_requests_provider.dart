import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/property_purchase_model.dart';

class ReceivedRequestsProvider with ChangeNotifier {
  List<PropertyPurchaseModel> _receivedRequests = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _error;

  List<PropertyPurchaseModel> get receivedRequests => [..._receivedRequests];
  bool get isLoading => _isLoading;
  String? get error => _error;

  // إنشاء دالة مساعدة لجلب الطلبات بناءً على معرفات العقارات
  Future<List<PropertyPurchaseModel>> _fetchPurchasesForProperties(
      List<String> propertyIds) async {
    List<PropertyPurchaseModel> purchases = [];

    for (var i = 0; i < propertyIds.length; i += 10) {
      final batch = propertyIds.sublist(
        i,
        i + 10 > propertyIds.length ? propertyIds.length : i + 10,
      );

      final purchaseSnapshot = await _db
          .collection('propertyPurchases')
          .where('propertyId', whereIn: batch)
          .get();

      for (var doc in purchaseSnapshot.docs) {
        try {
          final purchaseData = doc.data();

          // جلب بيانات المستخدم بشكل أفضل
          if (purchaseData['userId'] != null) {
            await _enrichUserData(purchaseData);
          }

          // إذا لم يتم العثور على رقم الهاتف بالطرق السابقة، جرب جلبه من جدول الهاتف المباشر
          if (purchaseData['userPhone'] == null ||
              purchaseData['userPhone'] == '') {
            try {
              final phoneDoc = await _db
                  .collection('userPhones')
                  .doc(purchaseData['userId'])
                  .get();

              if (phoneDoc.exists && phoneDoc.data() != null) {
                final phoneData = phoneDoc.data()!;
                if (phoneData['phone'] != null &&
                    phoneData['phone'].toString().isNotEmpty) {
                  purchaseData['userPhone'] = phoneData['phone'];
                  print(
                      'تم جلب رقم الهاتف من جدول userPhones: ${purchaseData['userPhone']}');
                }
              }
            } catch (e) {
              print('خطأ في جلب رقم الهاتف من جدول userPhones: $e');
            }
          }

          // جلب معلومات المستخدم بكطرق إضافية إذا لم يتم العثور على الرقم
          if (purchaseData['userPhone'] == null ||
              purchaseData['userPhone'] == '') {
            try {
              final authUser = FirebaseAuth.instance.currentUser;
              if (authUser != null && authUser.uid == purchaseData['userId']) {
                purchaseData['userPhone'] = authUser.phoneNumber ?? '';
                print(
                    'تم جلب رقم الهاتف من المستخدم الحالي: ${purchaseData['userPhone']}');
              }
            } catch (e) {
              print('خطأ في جلب معلومات المستخدم الحالي: $e');
            }
          }

          print(
              'معلومات المستخدم النهائية - الاسم: ${purchaseData['userName'] ?? 'غير متوفر'}, الهاتف: ${purchaseData['userPhone'] ?? 'غير متوفر'}');

          purchases.add(PropertyPurchaseModel.fromMap(purchaseData, doc.id));
        } catch (e) {
          print('خطأ في معالجة طلب ${doc.id}: $e');
        }
      }
    }

    return purchases;
  }

  // دالة مساعدة لإثراء بيانات المستخدم من مصادر متعددة
  Future<void> _enrichUserData(Map<String, dynamic> purchaseData) async {
    final userId = purchaseData['userId'];
    bool hasUserPhone = false;

    // محاولة 1: جلب البيانات من جدول users
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        purchaseData['userName'] =
            userData['name'] ?? purchaseData['userName'] ?? 'مستخدم';

        if (userData['phone'] != null &&
            userData['phone'].toString().isNotEmpty) {
          purchaseData['userPhone'] = userData['phone'];
          hasUserPhone = true;
          print(
              'تم جلب رقم الهاتف من جدول users: ${purchaseData['userPhone']}');
        }
      }
    } catch (e) {
      print('خطأ في جلب بيانات المستخدم من جدول users: $e');
    }

    // محاولة 2: جلب البيانات من جدول userProfiles إذا لم نجد رقم الهاتف
    if (!hasUserPhone) {
      try {
        final profileDoc =
            await _db.collection('userProfiles').doc(userId).get();
        if (profileDoc.exists) {
          final profileData = profileDoc.data()!;

          if (!purchaseData.containsKey('userName') ||
              purchaseData['userName'] == null ||
              purchaseData['userName'] == '') {
            purchaseData['userName'] = profileData['name'] ?? 'مستخدم';
          }

          if (profileData['phone'] != null &&
              profileData['phone'].toString().isNotEmpty) {
            purchaseData['userPhone'] = profileData['phone'];
            hasUserPhone = true;
            print(
                'تم جلب رقم الهاتف من جدول userProfiles: ${purchaseData['userPhone']}');
          }
        }
      } catch (e) {
        print('خطأ في جلب بيانات المستخدم من جدول userProfiles: $e');
      }
    }

    // محاولة 3: جلب البيانات من جدول phoneAuth
    if (!hasUserPhone) {
      try {
        final phoneAuthQuery = await _db
            .collection('phoneAuth')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (phoneAuthQuery.docs.isNotEmpty) {
          final phoneData = phoneAuthQuery.docs.first.data();
          if (phoneData['phoneNumber'] != null &&
              phoneData['phoneNumber'].toString().isNotEmpty) {
            purchaseData['userPhone'] = phoneData['phoneNumber'];
            hasUserPhone = true;
            print(
                'تم جلب رقم الهاتف من جدول phoneAuth: ${purchaseData['userPhone']}');
          }
        }
      } catch (e) {
        print('خطأ في جلب بيانات المستخدم من جدول phoneAuth: $e');
      }
    }

    // محاولة 4: جلب البيانات من جدول auth
    if (!hasUserPhone) {
      try {
        final authQuery = await _db
            .collection('auth')
            .where('uid', isEqualTo: userId)
            .limit(1)
            .get();

        if (authQuery.docs.isNotEmpty) {
          final authData = authQuery.docs.first.data();
          if (authData['phoneNumber'] != null &&
              authData['phoneNumber'].toString().isNotEmpty) {
            purchaseData['userPhone'] = authData['phoneNumber'];
            hasUserPhone = true;
            print(
                'تم جلب رقم الهاتف من جدول auth: ${purchaseData['userPhone']}');
          }
        }
      } catch (e) {
        print('خطأ في جلب بيانات المستخدم من جدول auth: $e');
      }
    }

    // إذا لم نجد رقم الهاتف بأي طريقة، نستخدم القيمة الافتراضية أو الفارغة
    if (!hasUserPhone) {
      purchaseData['userPhone'] = purchaseData['userPhone'] ?? '';
    }
  }

  Future<void> fetchReceivedRequests(String ownerPhone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('❇️ بدء جلب الطلبات للبائع (رقم الهاتف): $ownerPhone');
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      print('🔑 معرف المستخدم الحالي: ${currentUser.uid}');

      List<PropertyPurchaseModel> allPurchases = [];

      // طريقة 1: البحث المباشر عن جميع طلبات الشراء في النظام والتي تتعلق بالمستخدم الحالي
      print('🔍 جلب طلبات شراء العقارات بطرق متعددة...');

      // 1.1 جلب عقارات البائع الحالي أولاً
      final ownedPropertiesQuery = await _db
          .collection('properties')
          .where('ownerId', isEqualTo: currentUser.uid)
          .get();

      print(
          '🏠 عدد العقارات المملوكة للمستخدم الحالي: ${ownedPropertiesQuery.docs.length}');

      // طباعة تفاصيل العقارات المملوكة
      for (var doc in ownedPropertiesQuery.docs) {
        final data = doc.data();
        print(
            '  🏢 العقار: ${doc.id} - ${data['title'] ?? 'بدون عنوان'} - الهاتف: ${data['ownerPhone'] ?? 'غير متوفر'}');
      }

      // جمع معرفات العقارات المملوكة للمستخدم
      final ownedPropertyIds =
          ownedPropertiesQuery.docs.map((doc) => doc.id).toList();

      // 1.2 محاولة البحث عن جميع الطلبات ثم فلترتها محلياً للعقارات المملوكة فقط
      print('📋 جلب جميع طلبات الشراء للفلترة المحلية...');
      final allPurchasesQuery = await _db
          .collection('propertyPurchases')
          .orderBy('purchaseDate', descending: true)
          .limit(100) // البحث عن آخر 100 طلب كحد أقصى
          .get();

      print(
          '📊 إجمالي طلبات الشراء في النظام (حتى 100): ${allPurchasesQuery.docs.length}');

      // فلترة الطلبات للعقارات المملوكة فقط
      for (var doc in allPurchasesQuery.docs) {
        try {
          final purchaseData = doc.data();
          final propertyId = purchaseData['propertyId'] as String?;

          if (propertyId != null && ownedPropertyIds.contains(propertyId)) {
            // إذا كان العقار مملوكاً للمستخدم، أضف الطلب
            if (purchaseData['userId'] != null) {
              await _enrichUserData(purchaseData);
            }

            final purchase =
                PropertyPurchaseModel.fromMap(purchaseData, doc.id);
            allPurchases.add(purchase);
            print(
                '  ✅ تم العثور على طلب للعقار المملوك: ${doc.id} - العقار: $propertyId');
          } else {
            print('  ❌ طلب لعقار غير مملوك: ${doc.id} - العقار: $propertyId');
          }
        } catch (e) {
          print('  ⚠️ خطأ في معالجة الطلب ${doc.id}: $e');
        }
      }

      // 1.3 طريقة 2: البحث المباشر عبر معرف العقار في المجموعات
      if (ownedPropertyIds.isNotEmpty) {
        print('🔍 البحث عن الطلبات عبر معرفات العقارات...');

        // نقسم المعرفات لمجموعات لتجنب حدود Firestore
        for (var i = 0; i < ownedPropertyIds.length; i += 10) {
          final batchIds = ownedPropertyIds.sublist(
            i,
            i + 10 > ownedPropertyIds.length ? ownedPropertyIds.length : i + 10,
          );

          print(
              '  🔢 البحث عن الطلبات للمجموعة ${i ~/ 10 + 1} (${batchIds.length} عقار)');

          final purchasesQuery = await _db
              .collection('propertyPurchases')
              .where('propertyId', whereIn: batchIds)
              .get();

          print(
              '  📝 عدد الطلبات في المجموعة ${i ~/ 10 + 1}: ${purchasesQuery.docs.length}');

          for (var doc in purchasesQuery.docs) {
            try {
              // تجنب التكرارات
              if (!allPurchases.any((p) => p.id == doc.id)) {
                final purchaseData = doc.data();

                // جلب معلومات المستخدم المرسل للطلب
                if (purchaseData['userId'] != null) {
                  await _enrichUserData(purchaseData);
                }

                allPurchases
                    .add(PropertyPurchaseModel.fromMap(purchaseData, doc.id));
                print('  ✅ تم إضافة الطلب من المجموعة: ${doc.id}');
              }
            } catch (e) {
              print('  ⚠️ خطأ في معالجة طلب ${doc.id}: $e');
            }
          }
        }
      }

      // 1.4 طريقة 3: البحث بناءً على رقم الهاتف
      print('📱 البحث عن الطلبات بناءً على رقم الهاتف: $ownerPhone');
      final directPhoneQuery = await _db
          .collection('propertyPurchases')
          .where('ownerPhone', isEqualTo: ownerPhone)
          .get();

      print('📞 عدد الطلبات حسب رقم الهاتف: ${directPhoneQuery.docs.length}');

      for (var doc in directPhoneQuery.docs) {
        try {
          if (!allPurchases.any((p) => p.id == doc.id)) {
            final purchaseData = doc.data();

            if (purchaseData['userId'] != null) {
              await _enrichUserData(purchaseData);
            }

            allPurchases
                .add(PropertyPurchaseModel.fromMap(purchaseData, doc.id));
            print('  ✅ تم إضافة الطلب عن طريق رقم الهاتف: ${doc.id}');
          }
        } catch (e) {
          print('  ⚠️ خطأ في معالجة طلب ${doc.id}: $e');
        }
      }

      // 1.5 طريقة 4: البحث بناءً على معرف المالك
      print('🆔 البحث عن الطلبات بناءً على معرف المالك: ${currentUser.uid}');
      final directIdQuery = await _db
          .collection('propertyPurchases')
          .where('ownerId', isEqualTo: currentUser.uid)
          .get();

      print(
          '🔢 عدد الطلبات بناءً على معرف المالك: ${directIdQuery.docs.length}');

      for (var doc in directIdQuery.docs) {
        try {
          if (!allPurchases.any((p) => p.id == doc.id)) {
            final purchaseData = doc.data();

            if (purchaseData['userId'] != null) {
              await _enrichUserData(purchaseData);
            }

            allPurchases
                .add(PropertyPurchaseModel.fromMap(purchaseData, doc.id));
            print('  ✅ تم إضافة الطلب عن طريق معرف المالك: ${doc.id}');
          }
        } catch (e) {
          print('  ⚠️ خطأ في معالجة طلب ${doc.id}: $e');
        }
      }

      // تحديث القائمة مع إزالة التكرارات
      final uniquePurchases = <String, PropertyPurchaseModel>{};
      for (var purchase in allPurchases) {
        if (purchase.id != null) {
          uniquePurchases[purchase.id!] = purchase;
        }
      }

      _receivedRequests = uniquePurchases.values.toList();
      print(
          '✨ إجمالي الطلبات المستلمة بعد إزالة التكرارات: ${_receivedRequests.length}');

      if (_receivedRequests.isEmpty) {
        print(
            '⚠️ لم يتم العثور على أي طلبات! مراجعة حالة المستخدم والعقارات...');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في جلب الطلبات المستلمة: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // الموافقة على طلب
  Future<bool> approveRequest(String requestId) async {
    try {
      await _db.collection('propertyPurchases').doc(requestId).update({
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // تحديث الحالة محلياً أيضاً
      final index = _receivedRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        // استخدام copyWith للحفاظ على كل البيانات الحالية مع تغيير الحالة فقط
        _receivedRequests[index] = _receivedRequests[index].copyWith(
          status: 'approved',
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('خطأ في الموافقة على الطلب: $e');
      return false;
    }
  }

  // رفض طلب
  Future<bool> rejectRequest(String requestId,
      {String? rejectionReason}) async {
    try {
      // تحديث الحالة محلياً فقط (بدون تحديث قاعدة البيانات)
      final index = _receivedRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        // استخدام copyWith للحفاظ على كل البيانات الحالية مع تغيير الحالة وسبب الرفض محلياً فقط
        _receivedRequests[index] = _receivedRequests[index].copyWith(
          status: 'rejected',
          rejectionReason: rejectionReason,
          lastUpdated: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('خطأ في رفض الطلب محلياً: $e');
      return false;
    }
  }

  // جلب طلب واحد بواسطة المعرف
  PropertyPurchaseModel? getRequestById(String requestId) {
    try {
      return _receivedRequests.firstWhere((request) => request.id == requestId);
    } catch (e) {
      return null;
    }
  }

  // تعيين طلبات محددة مسبقاً (مفيد للتحميل من التخزين المحلي)
  void setReceivedRequests(List<PropertyPurchaseModel> requests) {
    _receivedRequests.clear();
    _receivedRequests.addAll(requests);
    notifyListeners();
  }
}
