import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property_request_model.dart';

class PropertyRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'propertyRequests';

  // إضافة طلب عقار جديد
  Future<String> addPropertyRequest(PropertyRequestModel request) async {
    try {
      print('بدء إضافة طلب عقار جديد');

      // التحقق من وجود البيانات الأساسية
      if (request.userId.isEmpty ||
          request.propertyType.isEmpty ||
          request.city.isEmpty) {
        throw 'بيانات الطلب غير مكتملة. الرجاء التأكد من إدخال جميع البيانات المطلوبة';
      }

      // تحضير بيانات العقار في هيكل ثابت متوافق مع تطبيق الإدارة
      Map<String, dynamic> propertyData = {
        'propertyType': request.propertyType,
        'city': request.city,
        'district': request.district,
        'minPrice': request.minPrice,
        'maxPrice': request.maxPrice,
        'minSpace': request.minSpace,
        'maxSpace': request.maxSpace,
        'bedrooms': request.bedrooms,
        'bathrooms': request.bathrooms,
        'additionalDetails': request.additionalDetails ?? '',
      };

      // إضافة الطلب إلى Firestore
      final docRef = await _firestore.collection(collectionName).add({
        'userId': request.userId,
        'userName': request.userName,
        'phone': request.phone,
        'propertyData': propertyData, // تخزين بيانات العقار في حقل منفصل
        'status': request.status.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('تم إضافة طلب العقار بنجاح، المعرف: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('خطأ في إضافة طلب العقار: $e');
      throw 'حدث خطأ أثناء إرسال طلب العقار: $e';
    }
  }

  // الحصول على طلبات العقارات الخاصة بمستخدم معين
  Future<List<PropertyRequestModel>> getUserRequests(String userId) async {
    try {
      print('جلب طلبات العقارات للمستخدم: $userId');
      final snapshot = await _firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      // طباعة معلومات الاستعلام للتشخيص
      print(
          'تم استرداد ${snapshot.docs.length} وثيقة من Firestore للمستخدم: $userId');

      if (snapshot.docs.isNotEmpty) {
        // طباعة محتوى أول وثيقة للتشخيص
        final firstData = snapshot.docs.first.data();
        print('نموذج بيانات طلب عقار:');
        firstData.forEach((key, value) {
          print('$key: ${value.runtimeType} = $value');
        });

        // طباعة معلومات أكثر تفصيلاً عن propertyData لتشخيص المشكلة
        if (firstData.containsKey('propertyData')) {
          print(
              'حقل propertyData موجود، النوع: ${firstData['propertyData'].runtimeType}');
          if (firstData['propertyData'] is Map) {
            print('محتويات propertyData:');
            (firstData['propertyData'] as Map).forEach((key, value) {
              print('  $key: ${value.runtimeType} = $value');
            });
          }
        } else {
          print('حقل propertyData غير موجود في البيانات');
        }
      }

      final requests = snapshot.docs.map((doc) {
        final data = doc.data();
        print('\n--- معالجة الوثيقة: ${doc.id} ---');

        // التحقق من وجود propertyData وتحويله بشكل صحيح
        Map<String, dynamic> propertyData = {};
        if (data.containsKey('propertyData')) {
          print(
              'الوثيقة تحتوي على حقل propertyData، النوع: ${data['propertyData'].runtimeType}');
          if (data['propertyData'] is Map) {
            propertyData = Map<String, dynamic>.from(data['propertyData']);
            print('تم تحويل propertyData إلى Map بنجاح');
          } else {
            print(
                'تحذير: propertyData ليس من نوع Map، النوع الفعلي: ${data['propertyData'].runtimeType}');
          }
        } else {
          print(
              'الوثيقة لا تحتوي على حقل propertyData، سيتم محاولة استخراج البيانات من الحقول المباشرة');
        }

        // طباعة بيانات نوع العقار للتشخيص
        print('معرف الطلب: ${doc.id}');
        print('نوع العقار في الجذر: ${data['propertyType']}');
        print('نوع العقار في propertyData: ${propertyData['propertyType']}');

        // طباعة بيانات أكثر تفصيلاً للتحقق من قيم الخصائص
        final keysToCheck = [
          'propertyType',
          'city',
          'district',
          'minPrice',
          'maxPrice',
          'status'
        ];
        print('قيم الخصائص الهامة:');
        for (final key in keysToCheck) {
          print('$key في الجذر: ${data[key]}');
          print('$key في propertyData: ${propertyData[key]}');
        }

        try {
          print('بدء تحويل البيانات إلى PropertyRequestModel');
          final request = PropertyRequestModel.fromMap(doc.data(), doc.id);
          print('تم التحويل بنجاح: ${request.propertyType}');
          return request;
        } catch (e) {
          print('خطأ أثناء تحويل البيانات: $e');
          rethrow;
        }
      }).toList();

      print('تم جلب ${requests.length} طلب');
      return requests;
    } catch (e) {
      print('خطأ في جلب طلبات العقارات: $e');
      throw 'حدث خطأ أثناء جلب طلبات العقارات: $e';
    }
  }

  // الحصول على تفاصيل طلب عقار بواسطة المعرف
  Future<PropertyRequestModel?> getRequestById(String requestId) async {
    try {
      final doc =
          await _firestore.collection(collectionName).doc(requestId).get();
      if (doc.exists) {
        return PropertyRequestModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب تفاصيل الطلب: $e');
      throw 'حدث خطأ أثناء جلب تفاصيل الطلب: $e';
    }
  }

  // حذف طلب عقار
  Future<void> cancelRequest(String requestId) async {
    try {
      // حذف الطلب نهائياً من قاعدة البيانات
      await _firestore.collection(collectionName).doc(requestId).delete();
      print('تم حذف الطلب بنجاح: $requestId');
    } catch (e) {
      print('خطأ في حذف الطلب: $e');
      throw 'حدث خطأ أثناء حذف الطلب: $e';
    }
  }

  Future<void> createPropertyRequest(PropertyRequestModel request) async {
    try {
      // تحويل البيانات إلى هيكل متوافق مع تطبيق الإدارة
      Map<String, dynamic> propertyData = {
        'propertyType': request.propertyType,
        'city': request.city,
        'district': request.district,
        'minPrice': request.minPrice,
        'maxPrice': request.maxPrice,
        'minSpace': request.minSpace,
        'maxSpace': request.maxSpace,
        'bedrooms': request.bedrooms,
        'bathrooms': request.bathrooms,
        'additionalDetails': request.additionalDetails,
      };

      await _firestore.collection('propertyRequests').add({
        'userId': request.userId,
        'userName': request.userName,
        'phone': request.phone, // تأكد من استخدام نفس اسم الحقل هنا
        'propertyData': propertyData, // إضافة البيانات في حقل منفصل
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('خطأ في إنشاء طلب العقار: $e');
      rethrow;
    }
  }

  // رفض طلب عقار محلياً
  Future<bool> rejectRequestLocally(
      PropertyRequestModel request, String rejectionReason) async {
    try {
      print('تم رفض الطلب محلياً فقط: ${request.id}');
      print('سبب الرفض: $rejectionReason');

      // ملاحظة: هذه الدالة لا تقوم بتحديث البيانات في Firestore
      // بل تستخدم فقط للعرض المحلي في واجهة المستخدم

      return true;
    } catch (e) {
      print('خطأ في رفض الطلب محلياً: $e');
      return false;
    }
  }
}
