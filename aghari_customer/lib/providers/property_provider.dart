import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_model.dart';
import '../models/property_approval_status.dart';
import '../services/property_service.dart';

class PropertyProvider with ChangeNotifier {
  final List<PropertyModel> _properties = [];
  final Set<String> _favorites = {};
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PropertyService _propertyService = PropertyService();

  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PropertyModel> get properties => [..._properties];
  List<PropertyModel> get favoriteProperties =>
      _properties.where((prop) => _favorites.contains(prop.id)).toList();

  set currentUserId(String? id) {
    _currentUserId = id;
    notifyListeners();
    if (id != null) {
      loadFavorites();
    } else {
      _favorites.clear();
      notifyListeners();
    }
  }

  String? get currentUserId => _currentUserId;

  // جلب عقار بواسطة المعرف
  PropertyModel? getPropertyById(String id) {
    try {
      return _properties.firstWhere((property) => property.id == id);
    } catch (e) {
      return null;
    }
  }

  // جلب عقار من قاعدة البيانات مباشرة
  Future<PropertyModel?> fetchPropertyById(String id) async {
    try {
      return await _propertyService.getPropertyById(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // التحقق ما إذا كان العقار مفضلاً
  bool isFavorite(String propertyId) {
    return _favorites.contains(propertyId);
  }

  // إضافة/إزالة عقار من المفضلة
  Future<void> toggleFavorite(String propertyId) async {
    print('🔄 محاولة تبديل حالة المفضلة للعقار: $propertyId');
    print('👤 معرف المستخدم الحالي: ${_currentUserId ?? 'غير محدد'}');

    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _error = 'يجب تسجيل الدخول لإضافة عقار للمفضلة';
      print('❌ خطأ: $_error');
      notifyListeners();
      return;
    }

    // حفظ الحالة السابقة في حالة وجود خطأ
    final previousFavorites = Set<String>.from(_favorites);
    final wasInFavorites = _favorites.contains(propertyId);

    print('ℹ️ العقار ${wasInFavorites ? 'موجود' : 'غير موجود'} في المفضلة');

    try {
      // تحديث الحالة محليًا أولاً للاستجابة السريعة
      if (wasInFavorites) {
        _favorites.remove(propertyId);
        print('🗑️ تمت إزالة العقار من المفضلة محلياً');
      } else {
        _favorites.add(propertyId);
        print('➕ تمت إضافة العقار للمفضلة محلياً');
      }
      notifyListeners();

      // ثم تحديث قاعدة البيانات
      print('🔄 تحديث البيانات في Firestore...');
      if (wasInFavorites) {
        await _db.collection('properties').doc(propertyId).update({
          'favoriteUserIds': FieldValue.arrayRemove([_currentUserId])
        });
        print('✅ تم حذف المستخدم من قائمة المفضلة في Firestore');
      } else {
        await _db.collection('properties').doc(propertyId).update({
          'favoriteUserIds': FieldValue.arrayUnion([_currentUserId])
        });
        print('✅ تم إضافة المستخدم إلى قائمة المفضلة في Firestore');
      }
    } catch (e) {
      // في حالة وجود خطأ، استعادة الحالة السابقة
      _favorites.clear();
      _favorites.addAll(previousFavorites);
      _error = e.toString();
      notifyListeners();
      print('❌ خطأ في تحديث المفضلة: $e');
    }
  }

  // إعادة تحميل المفضلة قسرياً
  Future<void> forceReloadFavorites(String userId) async {
    print('🔄 إعادة تحميل المفضلة قسرياً للمستخدم: $userId');

    // تأكد من تعيين معرف المستخدم أولاً
    _currentUserId = userId;

    try {
      final snapshot = await _db
          .collection('properties')
          .where('favoriteUserIds', arrayContains: userId)
          .get();

      _favorites.clear();
      for (var doc in snapshot.docs) {
        _favorites.add(doc.id);
      }

      print('✅ تم تحميل ${_favorites.length} عناصر في المفضلة بنجاح');
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في إعادة تحميل المفضلة: $e');
    }
  }

  // جلب جميع العقارات
  Future<void> fetchProperties() async {
    return loadProperties(ownerId: null);
  }

  // تحميل العقارات استناداً إلى المالك
  Future<void> loadProperties({String? ownerId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query query = _db.collection('properties');

      if (ownerId != null) {
        query = query.where('ownerId', isEqualTo: ownerId);
      } else {
        // عرض فقط العقارات التي تمت الموافقة عليها للمستخدمين العاديين
        query = query.where('approvalStatus', isEqualTo: 'approved');
      }

      final snapshot = await query.get();
      _properties.clear();

      for (var doc in snapshot.docs) {
        _properties.add(
            PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id));
      }
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      _error = error.toString();
      notifyListeners();
      print('Error fetching properties: $error');
    }
  }

  // تحميل العقارات المفضلة
  Future<void> loadFavorites() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      print('⚠️ لا يمكن تحميل المفضلة: معرف المستخدم غير موجود');
      return;
    }

    print('🔄 جاري تحميل المفضلة للمستخدم: $_currentUserId');

    try {
      final snapshot = await _db
          .collection('properties')
          .where('favoriteUserIds', arrayContains: _currentUserId)
          .get();

      _favorites.clear();
      for (var doc in snapshot.docs) {
        _favorites.add(doc.id);
      }

      print('✅ تم تحميل ${_favorites.length} عناصر في المفضلة');
      notifyListeners();
    } catch (e) {
      print('❌ خطأ في تحميل المفضلة: $e');
    }
  }

  // تطبيق الفلاتر على العقارات
  void applyFilters({
    PropertyType? type,
    String? cityId,
    PropertyStatus? status,
    double? minPrice,
    double? maxPrice,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query query = _db.collection('properties');

      // عرض فقط العقارات التي تمت الموافقة عليها
      query = query.where('approvalStatus', isEqualTo: 'approved');

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      if (cityId != null) {
        query = query.where('cityId', isEqualTo: cityId);
      }

      if (status != null) {
        query =
            query.where('status', isEqualTo: status.toString().split('.').last);
      }

      final snapshot = await query.get();
      _properties.clear();

      for (var doc in snapshot.docs) {
        final property =
            PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

        // تطبيق فلترة السعر بعد استرجاع البيانات (لا يمكن القيام بذلك مباشرة في Firestore)
        if (minPrice != null && property.price < minPrice) continue;
        if (maxPrice != null && property.price > maxPrice) continue;

        _properties.add(property);
      }

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      _error = error.toString();
      notifyListeners();
      print('Error applying filters: $error');
    }
  }

  // البحث عن العقارات
  void searchProperties(String query) async {
    if (query.isEmpty) {
      fetchProperties();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // البحث في Firestore محدود، لذا سنقوم بتنزيل العقارات ثم تصفيتها محليًا
      final snapshot = await _db
          .collection('properties')
          .where('approvalStatus', isEqualTo: 'approved')
          .get();
      _properties.clear();

      query = query.toLowerCase();

      for (var doc in snapshot.docs) {
        final property = PropertyModel.fromMap(doc.data(), doc.id);

        if (property.title.toLowerCase().contains(query) ||
            property.description.toLowerCase().contains(query) ||
            property.address.toLowerCase().contains(query)) {
          _properties.add(property);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      _error = error.toString();
      notifyListeners();
      print('Error searching properties: $error');
    }
  }

  // إضافة عقار جديد
  Future<String?> addProperty(PropertyModel property, List<File> images) async {
    try {
      print('PropertyProvider: بدء عملية إضافة عقار جديد');

      _isLoading = true;
      _error = null;
      notifyListeners();

      // التأكد من أن معرف المستخدم موجود
      if (_currentUserId == null || _currentUserId!.isEmpty) {
        print('خطأ: معرف المستخدم غير موجود');
        throw Exception(
            'لم يتم العثور على معرف المستخدم. يرجى تسجيل الدخول مرة أخرى.');
      }

      print('PropertyProvider: معرف المستخدم الحالي: $_currentUserId');

      // استخدام الطريقة المحسنة من خدمة العقارات
      final propertyId = await _propertyService.addProperty(property, images);
      print('PropertyProvider: تم إضافة العقار بمعرف: $propertyId');

      // تحديث قائمة العقارات إذا كان هناك معرف مستخدم حالي
      await fetchUserProperties(_currentUserId!);
      print('PropertyProvider: تم تحديث قائمة عقارات المستخدم');

      _isLoading = false;
      notifyListeners();
      return propertyId;
    } catch (e) {
      print('خطأ في مزود العقارات - إضافة عقار: $e');
      print('نوع الخطأ: ${e.runtimeType}');

      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      // إعادة رمي الخطأ ليتم معالجته في واجهة المستخدم
      rethrow;
    }
  }

  // إضافة عقار جديد بدون صور
  Future<String?> addPropertySimple(PropertyModel property) async {
    try {
      print('PropertyProvider: بدء عملية إضافة عقار جديد بدون صور');

      _isLoading = true;
      _error = null;
      notifyListeners();

      // التأكد من أن معرف المستخدم موجود
      if (_currentUserId == null || _currentUserId!.isEmpty) {
        print('خطأ: معرف المستخدم غير موجود');
        throw Exception(
            'لم يتم العثور على معرف المستخدم. يرجى تسجيل الدخول مرة أخرى.');
      }

      print('PropertyProvider: معرف المستخدم الحالي: $_currentUserId');

      // استخدام الطريقة المبسطة من خدمة العقارات
      final propertyId = await _propertyService.addPropertySimple(property);
      print('PropertyProvider: تم إضافة العقار (بدون صور) بمعرف: $propertyId');

      // تحديث قائمة العقارات إذا كان هناك معرف مستخدم حالي
      await fetchUserProperties(_currentUserId!);
      print('PropertyProvider: تم تحديث قائمة عقارات المستخدم');

      _isLoading = false;
      notifyListeners();
      return propertyId;
    } catch (e) {
      print('خطأ في مزود العقارات - إضافة عقار بدون صور: $e');
      print('نوع الخطأ: ${e.runtimeType}');

      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      // إعادة رمي الخطأ ليتم معالجته في واجهة المستخدم
      rethrow;
    }
  }

  // حذف عقار
  Future<bool> deleteProperty(String propertyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _propertyService.deleteProperty(propertyId);

      if (result) {
        _properties.removeWhere((property) => property.id == propertyId);
      }

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (error) {
      _isLoading = false;
      _error = error.toString();
      notifyListeners();
      print('Error deleting property: $error');
      return false;
    }
  }

  // جلب عقارات المستخدم
  Future<void> fetchUserProperties(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('properties')
          .where('ownerId', isEqualTo: userId)
          .get();

      _properties.clear();
      for (var doc in snapshot.docs) {
        final property =
            PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        _properties.add(property);

        // طباعة معلومات عن حالة الموافقة على العقار للتشخيص
        print(
            'عقار المستخدم: ${property.title} - حالة الموافقة: ${property.approvalStatus}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _isLoading = false;
      _error = error.toString();
      notifyListeners();
      print('Error fetching user properties: $error');
    }
  }

  // إضافة طريقة جديدة لجلب عقارات المستخدم مع عرض حالة الموافقة
  Future<Map<String, List<PropertyModel>>> fetchUserPropertiesByStatus(
      String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    Map<String, List<PropertyModel>> result = {
      'pending': [],
      'approved': [],
      'rejected': [],
    };

    try {
      final snapshot = await _db
          .collection('properties')
          .where('ownerId', isEqualTo: userId)
          .get();

      _properties.clear();
      for (var doc in snapshot.docs) {
        final property =
            PropertyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        _properties.add(property);

        // تصنيف العقارات حسب حالة الموافقة
        switch (property.approvalStatus) {
          case PropertyApprovalStatus.pending:
            result['pending']!.add(property);
            break;
          case PropertyApprovalStatus.approved:
            result['approved']!.add(property);
            break;
          case PropertyApprovalStatus.rejected:
            result['rejected']!.add(property);
            break;
        }
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (error) {
      _isLoading = false;
      _error = error.toString();
      notifyListeners();
      print('Error fetching user properties: $error');
      return result;
    }
  }
}
