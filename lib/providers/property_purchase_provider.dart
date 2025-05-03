import 'package:flutter/foundation.dart';
import '../services/property_purchase_service.dart';
import '../models/property_purchase_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PropertyPurchaseProvider with ChangeNotifier {
  final PropertyPurchaseService _purchaseService = PropertyPurchaseService();
  List<PropertyPurchaseModel> _purchases = [];
  bool _isLoading = false;
  String _userId = '';
  String? _error;
  Timer? _timer;

  List<PropertyPurchaseModel> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // جلب عمليات الشراء للمستخدم الحالي
  Future<void> fetchUserPurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔄 بدء جلب طلبات الشراء للمستخدم...');
      final startTime = DateTime.now();

      // التأكد من وجود معرف مستخدم
      if (_userId.isEmpty) {
        // محاولة الحصول على معرف المستخدم من المستخدم الحالي
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          _userId = currentUser.uid;
          print('👤 تم استخدام معرف المستخدم المسجل الدخول: $_userId');
        } else {
          // محاولة الحصول على معرف المستخدم من التخزين المحلي
          final prefs = await SharedPreferences.getInstance();
          final storedUserId = prefs.getString('userId');

          if (storedUserId != null && storedUserId.isNotEmpty) {
            _userId = storedUserId;
            print('👤 تم جلب معرف المستخدم من التخزين المحلي: $_userId');
          } else {
            print('⚠️ لم يتم العثور على معرف المستخدم في أي مكان');

            // محاولة استخدام التخزين المحلي في حالة عدم وجود معرف مستخدم
            final localPurchases = await LocalStorageService.getPurchases();
            if (localPurchases.isNotEmpty) {
              print(
                  '📋 تم العثور على ${localPurchases.length} طلب في التخزين المحلي');
              _purchases = localPurchases;
              _isLoading = false;
              notifyListeners();
              return;
            }

            print('❌ لا يمكن العثور على طلبات بدون معرف مستخدم');
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
      }

      print('🔥 جلب طلبات الشراء للمستخدم: $_userId');

      // محاولة جلب الطلبات من Firebase باستخدام معرف المستخدم
      final firestore = FirebaseFirestore.instance;
      final purchasesSnapshot = await firestore
          .collection('propertyPurchases')
          .where('userId', isEqualTo: _userId)
          .orderBy('purchaseDate', descending: true)
          .get();

      final fetchDuration = DateTime.now().difference(startTime).inMilliseconds;
      print('⏱️ استغرق جلب البيانات من Firestore: $fetchDuration مللي ثانية');

      if (purchasesSnapshot.docs.isEmpty) {
        print('⚠️ لم يتم العثور على طلبات شراء للمستخدم $_userId في Firestore');

        // محاولة استخدام التخزين المحلي
        _purchases = await LocalStorageService.getPurchases();
        if (_purchases.isEmpty) {
          print('📭 لا توجد طلبات في التخزين المحلي أيضاً');
      } else {
          print('📋 تم استخدام ${_purchases.length} طلب من التخزين المحلي');
        }

        _isLoading = false;
        notifyListeners();
        return;
      }

      print(
          '✅ تم العثور على ${purchasesSnapshot.docs.length} طلب شراء في Firestore');

      // تحويل المستندات إلى نماذج
      _purchases = [];
      for (var doc in purchasesSnapshot.docs) {
        try {
          final data = doc.data();
          final purchase = PropertyPurchaseModel.fromMap(data, doc.id);
          _purchases.add(purchase);
          print(
              '📄 طلب: ${doc.id}, العنوان: ${purchase.propertyTitle}, الحالة: ${purchase.status}');
        } catch (e) {
          print('❌ خطأ في معالجة طلب: ${doc.id}, الخطأ: $e');
        }
      }

      // حفظ الطلبات محلياً
      if (_purchases.isNotEmpty) {
        await LocalStorageService.savePurchases(_purchases);
        print('💾 تم حفظ ${_purchases.length} طلب في التخزين المحلي');
      }

      final totalDuration = DateTime.now().difference(startTime).inMilliseconds;
      print('⏱️ إجمالي وقت العملية: $totalDuration مللي ثانية');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في جلب طلبات الشراء: $e');
      
      // استخدام التخزين المحلي في حالة حدوث خطأ
      _purchases = await LocalStorageService.getPurchases();
      print(
          '🚨 فشل التحميل من الخادم، تم استرداد ${_purchases.length} طلب من التخزين المحلي');

    _isLoading = false;
    notifyListeners();
    }
  }

  // تعيين قائمة الطلبات المحلية
  void setLocalPurchases(List<PropertyPurchaseModel> purchases) {
    _purchases = purchases;
    notifyListeners();
    print('تم تعيين ${purchases.length} طلب محلي في المزود');
  }

  // إضافة طلب شراء محلي واحد
  void addLocalPurchase(PropertyPurchaseModel purchase) {
    _purchases.insert(0, purchase);
    notifyListeners();
    print('تمت إضافة طلب شراء محلي إلى المزود');
  }

  // إنشاء طلب شراء جديد
  Future<String> createPurchase(String propertyId, {String? notes}) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔥 بدء إنشاء طلب شراء جديد...');

      // التأكد من وجود معرف مستخدم
      if (_userId.isEmpty) {
        // محاولة الحصول على معرف المستخدم من التخزين المحلي
        final prefs = await SharedPreferences.getInstance();
        final storedUserId = prefs.getString('userId');

        if (storedUserId != null && storedUserId.isNotEmpty) {
          _userId = storedUserId;
          print('🔄 تم جلب معرف المستخدم من التخزين المحلي: $_userId');
        } else {
          throw 'لم يتم العثور على معرف المستخدم، يرجى تسجيل الدخول أولاً';
        }
      }

      // إنشاء معرف محلي مؤقت قبل الاتصال بالخادم
      final tempLocalId = 'local_temp_${DateTime.now().millisecondsSinceEpoch}';

      // جلب بيانات العقار أولاً حتى لو فشل الاتصال لاحقاً
      final propertyDoc = await FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .get();
      
      if (!propertyDoc.exists) {
        throw 'العقار غير موجود أو تم حذفه';
      }

        final propertyData = propertyDoc.data()!;
      print('🔥 بيانات العقار: ${propertyData.toString()}');

      // جلب بيانات المستخدم من Firestore
      String userName = '';
      String userPhone = '';

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        userName = userData['name'] ?? 'المستخدم';
        userPhone = userData['phone'] ?? '';
        print('👤 بيانات المستخدم: $userName, $userPhone');
      } else {
        userName = 'المستخدم';
        print('⚠️ لم يتم العثور على بيانات المستخدم، استخدام القيم الافتراضية');
      }

      // إنشاء نموذج الطلب المؤقت مع البيانات المحدثة
      final tempPurchase = PropertyPurchaseModel(
        id: tempLocalId,
        userId: _userId,
        userName: userName,
        userPhone: userPhone,
          propertyId: propertyId,
          propertyTitle: propertyData['title'] ?? 'عقار',
          propertyPrice: (propertyData['price'] ?? 0).toDouble(),
          ownerName: propertyData['ownerName'] ?? '',
          ownerPhone: propertyData['ownerPhone'] ?? '',
          purchaseDate: DateTime.now(),
        status: 'pending',
        notes: notes ?? '',
        propertyType: propertyData['type'] ?? '',
        propertyStatus: propertyData['status'] ?? '',
        city: propertyData['city'] ?? '',
        district: propertyData['district'] ?? '',
        propertyArea: (propertyData['area'] ?? 0).toDouble(),
        bedrooms: propertyData['bedrooms'] ?? 0,
        bathrooms: propertyData['bathrooms'] ?? 0,
        ownerId: propertyData['ownerId'] ?? '',
      );

      print('🔥 نموذج الطلب المؤقت: ${tempPurchase.toMap()}');

      // إضافة الطلب المؤقت إلى القائمة المحلية فوراً
      _purchases.insert(0, tempPurchase);
      await LocalStorageService.addPurchase(tempPurchase);
      notifyListeners();

      // محاولة إرسال الطلب إلى Firestore
      String? serverPurchaseId;
      try {
        serverPurchaseId =
            await _purchaseService.createPurchaseRequest(tempPurchase);
        print('✅ تم إنشاء طلب شراء على السيرفر بنجاح: $serverPurchaseId');

        // تحديث معرف الطلب المحلي بالمعرف من السيرفر
        if (serverPurchaseId != null) {
          final index = _purchases.indexWhere((p) => p.id == tempLocalId);
          if (index != -1) {
            final updatedPurchase =
                _purchases[index].copyWith(id: serverPurchaseId);
            _purchases[index] = updatedPurchase;
          await LocalStorageService.savePurchases(_purchases);
          }
        }
      } catch (serverError) {
        print(
            '⚠️ فشل إرسال الطلب إلى السيرفر، لكن تم حفظه محلياً: $serverError');
      }
      
      _isLoading = false;
      notifyListeners();
      
      return serverPurchaseId ?? tempLocalId;
    } catch (e) {
      print('❌ خطأ في إنشاء طلب الشراء: $e');
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // إلغاء طلب شراء
  Future<void> cancelPurchase(String purchaseId) async {
    try {
      print('بدء عملية إلغاء الطلب: $purchaseId');

      // تحديث الطلب محلياً أولاً لتسريع الواجهة
      int purchaseIndex = _purchases.indexWhere((p) => p.id == purchaseId);
      if (purchaseIndex != -1) {
        // تغيير حالة الطلب محلياً بدلاً من حذفه
        _purchases[purchaseIndex] =
            _purchases[purchaseIndex].copyWith(status: 'cancelled');
        notifyListeners();
      }
      
      // محاولة إلغاء الطلب من قاعدة البيانات
      await _purchaseService.cancelPurchase(purchaseId);
      
      // تخزين التحديثات في التخزين المحلي
      await LocalStorageService.savePurchases(_purchases);
      
      print('تم إلغاء الطلب بنجاح: $purchaseId');
      return;
    } catch (e) {
      print('خطأ في إلغاء طلب الشراء: $e');
      
      // في حالة الفشل، إذا كان الطلب محليًا، قم بإلغائه محليًا فقط
      if (purchaseId.startsWith('local_')) {
        print('الطلب محلي، سيتم تغيير حالته محليًا فقط');
        int localIndex = _purchases.indexWhere((p) => p.id == purchaseId);
        if (localIndex != -1) {
          _purchases[localIndex] =
              _purchases[localIndex].copyWith(status: 'cancelled');
        notifyListeners();
        }
        
        // تحديث التخزين المحلي
        await LocalStorageService.savePurchases(_purchases);
        return;
      }

      // إعادة تحميل البيانات في حال الفشل
      await fetchUserPurchases();
      
      // إعادة رمي الخطأ للتعامل معه في واجهة المستخدم
      rethrow;
    }
  }

  // دالة للتحقق من تحديثات الطلبات
  Future<bool> checkForStatusUpdates({bool forceUpdate = false}) async {
    print('🔄 جاري التحقق من تحديثات حالة الطلبات (forceUpdate: $forceUpdate)');
    bool updatesFound = false;
    final startTime = DateTime.now();

    try {
      // التحقق من وجود معرف المستخدم
      final currentUser = FirebaseAuth.instance.currentUser;
      final userId = currentUser?.uid ?? _userId;

      if (userId == null || userId.isEmpty) {
        print('⚠️ معرف المستخدم غير متوفر، لا يمكن التحقق من التحديثات');
        return false;
      }

      print('👤 التحقق من تحديثات الطلبات للمستخدم: $userId');

      // التحقق من وجود طلبات محلية
      List<PropertyPurchaseModel> localPurchases = [..._purchases];
      print('📱 عدد الطلبات المحلية: ${localPurchases.length}');

      // جلب التحديثات من Firebase مباشرة
      print('☁️ جلب التحديثات من Firebase...');
      List<PropertyPurchaseModel> remoteUpdates = [];

      try {
        final QuerySnapshot purchasesSnapshot = await FirebaseFirestore.instance
            .collection('propertyPurchases')
            .where('userId', isEqualTo: userId)
            .orderBy('purchaseDate', descending: true)
            .get(const GetOptions(
                source: Source.server)); // إجبار الطلب من السيرفر

        print('📊 تم استرداد ${purchasesSnapshot.docs.length} طلب من Firebase');

        // تحويل المستندات إلى نماذج
        for (var doc in purchasesSnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;

            // طباعة تشخيصية مفصلة عن الطلب
            print('📄 معالجة وثيقة ${doc.id}:');
            print('   حالة الطلب: ${data['status']}');

            // إنشاء نموذج من البيانات
            final purchase = PropertyPurchaseModel.fromMap(data, doc.id);
            remoteUpdates.add(purchase);

            print('✅ تمت إضافة وثيقة ${doc.id} بحالة ${purchase.status}');
          } catch (docError) {
            print('❌ خطأ في معالجة الوثيقة ${doc.id}: $docError');
            print('❌ بيانات الوثيقة: ${doc.data()}');
          }
        }
      } catch (fetchError) {
        print('❌ خطأ في جلب بيانات Firebase: $fetchError');
        // استخدام دالة الخدمة للحصول على الطلبات في حالة فشل الطريقة المباشرة
        try {
          remoteUpdates = await _purchaseService.getUserPurchasesFromFirebase();
        } catch (serviceError) {
          print('❌ خطأ في استخدام خدمة جلب البيانات: $serviceError');
          return false;
        }
      }

      print(
          '☁️ عدد الطلبات التي تم جلبها من Firebase: ${remoteUpdates.length}');
      
      if (remoteUpdates.isEmpty) {
        print('⚠️ لم يتم العثور على أي طلبات في Firebase');
        return false;
      }

      // إنشاء خريطة للوصول السريع إلى الطلبات المحلية عن طريق المعرف
      Map<String, PropertyPurchaseModel> localPurchasesMap = {
        for (var p in localPurchases) p.id: p
      };

      // متغير لتتبع ما إذا كان هناك أي تغييرات في حالة الطلبات
      bool hasChanges = false;

      // التحقق من وجود أي تغييرات في حالة الطلبات
      for (var remotePurchase in remoteUpdates) {
        print(
            '🔍 فحص الطلب ${remotePurchase.id} (حالة: ${remotePurchase.status})');

        // التحقق مما إذا كان الطلب موجودًا محليًا
        if (localPurchasesMap.containsKey(remotePurchase.id)) {
          PropertyPurchaseModel localPurchase =
              localPurchasesMap[remotePurchase.id]!;

          print('🔄 مقارنة حالة طلب ${remotePurchase.id}:');
          print('   - محلي: ${localPurchase.status}');
          print('   - بعيد: ${remotePurchase.status}');

          // مقارنة الحالة بتنسيق موحد (تحويل كل شيء إلى أحرف صغيرة)
          if (localPurchase.status.toLowerCase() !=
              remotePurchase.status.toLowerCase()) {
            print(
                '⚠️ تم العثور على اختلاف في الحالة للطلب ${remotePurchase.id}!');
            print('   - محلي: ${localPurchase.status}');
            print('   - بعيد: ${remotePurchase.status}');

            // تحديث الطلب المحلي بالحالة الجديدة
            int index = _purchases.indexWhere((p) => p.id == remotePurchase.id);
            if (index != -1) {
              print(
                  '✏️ تحديث حالة الطلب المحلي ${remotePurchase.id} إلى ${remotePurchase.status}');
              _purchases[index] = remotePurchase;
              hasChanges = true;
              updatesFound = true;
            } else {
              print(
                  '❌ الطلب ${remotePurchase.id} غير موجود في قائمة الطلبات المحلية');
            }
          } else {
            // التحقق من وجود تغييرات أخرى في الطلب (مثل ملاحظات المسؤول)
            if (localPurchase.adminNotes != remotePurchase.adminNotes) {
              print('📝 تم تحديث ملاحظات المسؤول للطلب ${remotePurchase.id}');
              int index =
                  _purchases.indexWhere((p) => p.id == remotePurchase.id);
              if (index != -1) {
                _purchases[index] = remotePurchase;
                hasChanges = true;
                updatesFound = true;
              }
            }
          }
        } else {
          // هذا طلب جديد غير موجود محليًا، إضافته إلى القائمة المحلية
          print(
              '➕ تم العثور على طلب جديد (${remotePurchase.id}) بحالة ${remotePurchase.status}');
          _purchases.add(remotePurchase);
          hasChanges = true;
          updatesFound = true;
        }
      }

      // حفظ التغييرات في التخزين المحلي إذا وجدت تغييرات
      if (hasChanges) {
        print('💾 حفظ التغييرات في التخزين المحلي');
        await _savePurchasesToLocalStorage();

        // إعلام المستمعين بالتغييرات
        print('🔔 إعلام المستمعين بالتغييرات في الطلبات');
        notifyListeners();
      } else {
        print('ℹ️ لم يتم العثور على أي تغييرات في حالة الطلبات');
      }

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      print('⏱️ استغرق التحقق من التحديثات: $duration مللي ثانية');

      return updatesFound;
    } catch (e) {
      print('❌ خطأ أثناء التحقق من تحديثات الحالة: $e');
      return false;
    }
  }

  // تحسين دالة بدء التحديث الدوري
  void startPeriodicFetch(BuildContext context) {
    print('🔄 بدء جدولة الفحص الدوري للتحديثات');

    // إلغاء المؤقت السابق إذا كان موجودًا
    _timer?.cancel();

    // إجراء فحص أولي بعد 3 ثوانٍ
    Future.delayed(const Duration(seconds: 3), () {
      print('⏰ جاري تنفيذ الفحص الأولي للتحديثات...');
      checkForStatusUpdates(forceUpdate: true).then((updatesFound) {
        if (updatesFound) {
          print('✅ تم العثور على تحديثات في الفحص الأولي!');
          // إعلام المستمعين بالتغييرات
          notifyListeners();
        } else {
          print('ℹ️ لم يتم العثور على تحديثات في الفحص الأولي');
        }
      });
    });

    // جدولة فحص دوري كل 10 ثوانٍ
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      print('⏰ جاري تنفيذ الفحص الدوري #${timer.tick} للتحديثات...');
      checkForStatusUpdates(forceUpdate: true).then((updatesFound) {
        if (updatesFound) {
          print('✅ تم العثور على تحديثات في الفحص الدوري #${timer.tick}!');
          // إعلام المستمعين بالتغييرات
          notifyListeners();
      } else {
          print('ℹ️ لم يتم العثور على تحديثات في الفحص الدوري #${timer.tick}');
      }
      });
    });
  }

  // إضافة الطريقة إذا كانت غير موجودة
  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  // إضافة هذه الطريقة في PropertyPurchaseProvider
  void removePurchaseLocally(String purchaseId) {
    // تغيير حالة الطلب إلى "cancelled" بدلاً من حذفه
    int index = _purchases.indexWhere((purchase) => purchase.id == purchaseId);
    if (index != -1) {
      _purchases[index] = _purchases[index].copyWith(status: 'cancelled');
    notifyListeners();
    }
    
    // تحديث التخزين المحلي أيضاً
    LocalStorageService.savePurchases(_purchases);
  }

  // إعادة تحميل جميع الطلبات بتجاهل التخزين المؤقت
  Future<void> reloadPurchases() async {
    _isLoading = true;
    notifyListeners();

    try {
      // الحصول على مرجع المستخدم الحالي
      final currentUser = FirebaseAuth.instance.currentUser;
      String userId = '';

      if (currentUser == null) {
        if (_userId.isEmpty) {
          print('❌ المستخدم غير مسجل دخول ولا يوجد معرف محلي');
          throw 'المستخدم غير مسجل دخول';
        } else {
          userId = _userId;
          print('🔄 استخدام معرف المستخدم المخزن محلياً: $userId');
        }
      } else {
        userId = currentUser.uid;
        print('👤 تم العثور على مستخدم مسجل الدخول: $userId');
      }

      print('🔄 إعادة تحميل طلبات الشراء للمستخدم: $userId');

      // تفريغ المشتريات المخزنة مؤقتًا
      _purchases = [];

      // جلب المشتريات مباشرة من Firestore
      final startTime = DateTime.now();
      final purchasesSnapshot = await FirebaseFirestore.instance
          .collection('propertyPurchases')
          .where('userId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .get();

      final fetchDuration = DateTime.now().difference(startTime).inMilliseconds;
      print('⏱️ استغرق جلب البيانات من Firestore: $fetchDuration مللي ثانية');
      print(
          '📊 تم العثور على ${purchasesSnapshot.docs.length} طلب في Firestore');

      // تحويل وثائق Firestore إلى نماذج
      for (var doc in purchasesSnapshot.docs) {
        try {
          final data = doc.data();
          final purchase = PropertyPurchaseModel.fromMap(data, doc.id);
          _purchases.add(purchase);

          print(
              '➕ تمت إضافة طلب: ${doc.id}, العنوان: ${purchase.propertyTitle}, الحالة: ${purchase.status}');
        } catch (e) {
          print('❌ خطأ في معالجة طلب: ${doc.id}, الخطأ: $e');
        }
      }

      // حفظ الطلبات المحدثة محليًا
      if (_purchases.isNotEmpty) {
        await LocalStorageService.savePurchases(_purchases);
        print('💾 تم حفظ ${_purchases.length} طلب في التخزين المحلي');
      } else {
        print('⚠️ لم يتم العثور على طلبات، محاولة استخدام التخزين المحلي...');
        _purchases = await LocalStorageService.getPurchases();

        if (_purchases.isEmpty) {
          print('📭 لا توجد طلبات في التخزين المحلي أيضًا');
        } else {
          print('🗃️ تم استرداد ${_purchases.length} طلب من التخزين المحلي');
        }
      }
    } catch (e) {
      print('❌ خطأ في إعادة تحميل الطلبات: $e');

      // استخدام البيانات المحلية في حالة الفشل
      _purchases = await LocalStorageService.getPurchases();
      print(
          '🚨 فشل التحميل من الخادم، تم استرداد ${_purchases.length} طلب من التخزين المحلي');
    }

    _isLoading = false;
    notifyListeners();
  }

  // إنشاء طلب اختباري للتحقق من عرض الطلبات
  Future<void> _createDummyPurchaseIfNeeded() async {
    try {
      if (_purchases.isEmpty) {
        print('إنشاء طلب اختباري للتحقق من عمل الشاشة');

        final dummyPurchase = PropertyPurchaseModel(
          id: 'dummy_test_${DateTime.now().millisecondsSinceEpoch}',
          userId: FirebaseAuth.instance.currentUser?.uid ?? 'test_user',
          userName: FirebaseAuth.instance.currentUser?.displayName ??
              'مستخدم اختباري',
          userPhone: '0500000000',
          propertyId: 'test_property',
          propertyTitle: 'عقار اختباري للتحقق من العرض',
          propertyPrice: 1000000,
          ownerName: 'مالك العقار',
          ownerPhone: '0500000000',
          purchaseDate: DateTime.now(),
          status: 'pending',
          notes: 'طلب اختباري للتحقق من عمل الشاشة',
          propertyType: 'house',
          propertyStatus: 'for_sale',
          city: 'nouakchott',
          district: 'teyarett',
          propertyArea: 100.0,
          bedrooms: 3,
          bathrooms: 2,
          ownerId: 'test_owner',
        );

        _purchases.add(dummyPurchase);
        await LocalStorageService.savePurchases(_purchases);
        print('تم إنشاء طلب اختباري وحفظه محلياً');
      }
    } catch (e) {
      print('خطأ في إنشاء الطلب الاختباري: $e');
    }
  }

  // تحديث إلزامي للتخزين المحلي
  Future<void> forceLocalStorage() async {
    try {
      await LocalStorageService.savePurchases(_purchases);
      print('تم حفظ ${_purchases.length} طلب في التخزين المحلي بشكل إلزامي');
    } catch (e) {
      print('خطأ في الحفظ الإلزامي: $e');
    }
  }

  // التحقق من حالة طلب محدد (يمكن استدعاؤها يدوياً)
  Future<void> checkSpecificPurchase(String purchaseId) async {
    try {
      print('فحص حالة الطلب: $purchaseId');
      
      // الحصول على الطلب مباشرة من Firebase
      final docSnapshot = await FirebaseFirestore.instance
          .collection('propertyPurchases')
          .doc(purchaseId)
          .get();
      
      if (!docSnapshot.exists) {
        print('الطلب غير موجود في قاعدة البيانات: $purchaseId');
        return;
      }
      
      // طباعة بيانات الطلب
      print('بيانات الطلب من Firebase:');
      final data = docSnapshot.data();
      data?.forEach((key, value) {
        print('$key: $value (${value.runtimeType})');
      });
      
      // تحويل البيانات إلى نموذج طلب
      final remotePurchase =
          PropertyPurchaseModel.fromMap(docSnapshot.data()!, purchaseId);
      print('حالة الطلب من Firebase: ${remotePurchase.status}');
      
      // البحث عن الطلب في القائمة المحلية
      final index = _purchases.indexWhere((p) => p.id == purchaseId);
      if (index != -1) {
        print('الطلب موجود محلياً: ${_purchases[index].status}');
        
        // تحديث الطلب إذا كانت الحالة مختلفة
        if (_purchases[index].status != remotePurchase.status) {
          print('تحديث حالة الطلب محلياً');
          _purchases[index] = remotePurchase;
          notifyListeners();
          
          // تحديث التخزين المحلي
          await LocalStorageService.savePurchases(_purchases);
        }
      } else {
        print('الطلب غير موجود في القائمة المحلية');
      }
    } catch (e) {
      print('خطأ في فحص حالة الطلب: $e');
    }
  }

  // تحميل الطلبات بشكل أكثر ذكاءً وقوة
  Future<void> loadPurchasesSmartly() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final List<PropertyPurchaseModel> remotePurchases = [];
      final List<PropertyPurchaseModel> localPurchases = [];

      // جلب الطلبات المحلية أولاً (للتحميل السريع)
      try {
        localPurchases.addAll(await LocalStorageService.getPurchases());
        // استخدم النسخة المحلية مبدئياً
        if (localPurchases.isNotEmpty) {
          _purchases = localPurchases;
          notifyListeners();
        }
      } catch (localError) {
        print('خطأ في جلب الطلبات المحلية: $localError');
      }

      // ثم محاولة جلب الطلبات من السيرفر
      try {
        remotePurchases.addAll(await _purchaseService.getUserPurchases());
      } catch (remoteError) {
        print('خطأ في جلب الطلبات من السيرفر: $remoteError');

        // إذا فشل، محاولة جلب جميع الطلبات (للتشخيص)
        try {
          final allPurchases = await _purchaseService.getAllPurchases();
          if (allPurchases.isNotEmpty && currentUser != null) {
            print(
                'محاولة فلترة الطلبات باستخدام معرف المستخدم: ${currentUser.uid}');

            // مطابقة الطلبات التي تنتمي للمستخدم الحالي
            final matchingPurchases =
                allPurchases.where((p) => p.userId == currentUser.uid).toList();

            if (matchingPurchases.isNotEmpty) {
              remotePurchases.addAll(matchingPurchases);
              print(
                  'تم العثور على ${matchingPurchases.length} طلب تنتمي للمستخدم الحالي');
            }
          }
        } catch (allError) {
          print('فشل جلب جميع الطلبات: $allError');
        }
      }

      // دمج الطلبات المحلية والبعيدة باستخدام خوارزمية متقدمة
      final Map<String, PropertyPurchaseModel> mergedPurchases = {};

      // إضافة الطلبات البعيدة أولاً (لها الأولوية)
      for (var purchase in remotePurchases) {
        if (purchase.id != null) {
          mergedPurchases[purchase.id!] = purchase;
        }
      }

      // إضافة الطلبات المحلية التي ليس لها نظير بعيد
      for (var purchase in localPurchases) {
        if (purchase.id != null &&
            purchase.id!.startsWith('local_') &&
            !mergedPurchases.containsKey(purchase.id)) {
          mergedPurchases[purchase.id!] = purchase;
        }
      }

      // تحويل النتيجة إلى قائمة وترتيبها حسب التاريخ
      _purchases = mergedPurchases.values.toList()
        ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

      // تحديث التخزين المحلي بالبيانات المدمجة
      await LocalStorageService.savePurchases(_purchases);

      print('تم دمج الطلبات بنجاح: ${_purchases.length} طلب في المجموع');
    } catch (e) {
      print('خطأ في loadPurchasesSmartly: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _savePurchasesToLocalStorage() async {
    await LocalStorageService.savePurchases(_purchases);
  }
}
