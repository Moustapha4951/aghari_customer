import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/property_model.dart';
import '../models/property_approval_status.dart';

class PropertyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<PropertyModel?> getPropertyById(String propertyId) async {
    try {
      final doc = await _db.collection('properties').doc(propertyId).get();
      if (doc.exists) {
        return PropertyModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب تفاصيل العقار: $e');
      return null;
    }
  }

  Future<String?> addProperty(PropertyModel property, List<File> images) async {
    DocumentReference propertyRef = _db.collection('properties').doc();
    String propertyId = propertyRef.id;

    try {
      print('1. بدء عملية إضافة العقار: ${property.title}');
      print('- تم إنشاء معرف للعقار: $propertyId');

      // تعيين المعرف وحالة الموافقة
      final propertyWithPendingStatus = property.copyWith(
        id: propertyId,
        approvalStatus: PropertyApprovalStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // إعداد بيانات العقار للإضافة إلى Firestore
      final Map<String, dynamic> propertyData =
          propertyWithPendingStatus.toMap();

      // تأكد من وجود حقل صور فارغ
      propertyData['images'] = [];

      // تسجيل أخطاء الصور للعقار
      List<String> errorMessages = [];

      print('2. حفظ بيانات العقار الأساسية في Firestore...');
      // حفظ العقار بدون صور أولاً
      await propertyRef.set(propertyData);
      print('- تم حفظ بيانات العقار الأساسية بنجاح!');

      // رفع الصور إلى Firebase Storage
      List<String> uploadedImageUrls = [];
      if (images.isNotEmpty) {
        print('3. بدء رفع ${images.length} صور للعقار');

        for (int i = 0; i < images.length; i++) {
          try {
            // التحقق من وجود الملف
            if (!await images[i].exists()) {
              print('- خطأ: الملف غير موجود: ${images[i].path}');
              errorMessages.add('الصورة ${i + 1}: الملف غير موجود');
              continue;
            }

            // التحقق من حجم الملف
            final fileSize = await images[i].length();
            if (fileSize == 0) {
              print('- خطأ: الصورة ${i + 1} فارغة');
              errorMessages.add('الصورة ${i + 1}: الملف فارغ');
              continue;
            }

            final fileSizeMB = fileSize / (1024 * 1024);
            print(
                '- حجم الصورة ${i + 1}: ${fileSizeMB.toStringAsFixed(2)} ميجابايت');

            // إنشاء اسم فريد للملف
            final String fileName = 'property_${propertyId}_${i + 1}.jpg';
            final Reference storageRef =
                _storage.ref().child('properties/$propertyId/$fileName');

            print('- جاري رفع الصورة ${i + 1}/${images.length}...');

            // إضافة معلومات وصفية للملف
            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'propertyId': propertyId,
                'uploadedAt': DateTime.now().toString(),
                'originalFileName': images[i].path.split('/').last,
              },
            );

            // بدء عملية الرفع مع المعلومات الوصفية
            final UploadTask uploadTask =
                storageRef.putFile(images[i], metadata);

            // مراقبة تقدم الرفع
            uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
              final progress =
                  (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
              print(
                  '- تقدم رفع الصورة ${i + 1}: ${progress.toStringAsFixed(1)}%');
            });

            try {
              // الانتظار حتى اكتمال الرفع مع وقت انتظار محدد
              final TaskSnapshot snapshot = await uploadTask.timeout(
                Duration(minutes: 2),
                onTimeout: () {
                  print('- تجاوز وقت رفع الصورة ${i + 1}');
                  errorMessages.add('الصورة ${i + 1}: تجاوز وقت الرفع');
                  uploadTask.cancel();
                  throw TimeoutException('تجاوز وقت رفع الصورة');
                },
              );

              // الحصول على رابط التنزيل
              final String downloadUrl = await snapshot.ref.getDownloadURL();

              uploadedImageUrls.add(downloadUrl);
              print('- تم رفع الصورة ${i + 1} بنجاح: $downloadUrl');
            } catch (uploadError) {
              print('- فشل في إكمال رفع الصورة ${i + 1}: $uploadError');

              if (uploadError.toString().contains('permission-denied')) {
                errorMessages.add('الصورة ${i + 1}: خطأ في صلاحيات الوصول');
                print('  سبب الخطأ: ليس لديك صلاحيات كافية للرفع');
                print('  يرجى التحقق من قواعد التخزين في Firebase Storage');
              } else if (uploadError.toString().contains('canceled')) {
                errorMessages.add('الصورة ${i + 1}: تم إلغاء الرفع');
                print('  سبب الخطأ: تم إلغاء عملية الرفع');
              } else if (uploadError.toString().contains('network')) {
                errorMessages.add('الصورة ${i + 1}: خطأ في الشبكة');
                print('  سبب الخطأ: مشكلة في اتصال الشبكة');
              } else {
                errorMessages.add(
                    'الصورة ${i + 1}: ${uploadError.toString().substring(0, 50)}...');
                print('  سبب الخطأ: ${uploadError.toString()}');
              }
            }
          } catch (e) {
            errorMessages.add(
                'الصورة ${i + 1}: خطأ عام - ${e.toString().substring(0, 30)}...');
            print('- خطأ عام في تحضير الصورة ${i + 1}: $e');
          }
        }

        print(
            '- تم رفع ${uploadedImageUrls.length} صور من أصل ${images.length}');

        // تحديث العقار بالصور التي تم رفعها
        if (uploadedImageUrls.isNotEmpty) {
          print('4. تحديث العقار بالصور التي تم رفعها');
          try {
            await propertyRef.update({'images': uploadedImageUrls});
            print('- تم تحديث العقار بالصور بنجاح');
          } catch (updateError) {
            print('- خطأ في تحديث العقار بالصور: $updateError');
            errorMessages.add('فشل تحديث العقار بالصور: $updateError');
          }
        } else {
          print('- تحذير: لم يتم رفع أي صورة بنجاح، العقار سيكون بدون صور');
          errorMessages.add('لم يتم رفع أي صورة بنجاح');
        }

        // إضافة سجل بالأخطاء إذا كانت هناك أخطاء
        if (errorMessages.isNotEmpty) {
          try {
            await propertyRef.update({
              'imageUploadErrors': errorMessages,
              'lastErrorUpdate': FieldValue.serverTimestamp(),
            });
            print('- تم تسجيل أخطاء رفع الصور');
          } catch (e) {
            print('- خطأ في تسجيل أخطاء رفع الصور: $e');
          }
        }
      } else {
        print('- لا توجد صور للرفع');
      }

      print('5. اكتملت عملية إضافة العقار بنجاح!');
      return propertyId;
    } catch (e) {
      print('خطأ في إضافة العقار: $e');
      print('نوع الخطأ: ${e.runtimeType}');
      print('تفاصيل الخطأ: ${e.toString()}');

      // في حالة حدوث خطأ، نحاول تسجيل الخطأ في قاعدة البيانات
      try {
        await propertyRef.update({
          'hasError': true,
          'errorMessage': e.toString(),
          'errorTimestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // تجاهل أي خطأ هنا - هذا مجرد للتسجيل
      }

      return propertyId; // نعيد معرف العقار حتى لو كان هناك خطأ في رفع الصور
    }
  }

  Future<String?> addPropertySimple(PropertyModel property) async {
    try {
      print('إضافة عقار بدون صور: ${property.title}');

      final propertyWithStatus = property.copyWith(
        approvalStatus: PropertyApprovalStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final Map<String, dynamic> propertyData = propertyWithStatus.toMap();
      if (propertyData.containsKey('id') && propertyData['id'] == '') {
        propertyData.remove('id');
      }

      // تأكد من وجود حقل الصور حتى لو كان فارغًا لتجنب المشاكل في تطبيق الإدارة
      propertyData['images'] = [];
      propertyData['approvalStatus'] =
          PropertyApprovalStatus.pending.toString().split('.').last;

      final docRef = await _db.collection('properties').add(propertyData);

      await _db
          .collection('properties')
          .doc(docRef.id)
          .update({'id': docRef.id});

      print('تم إضافة العقار بدون صور بحالة معلقة. المعرف: ${docRef.id}');
      return docRef.id;
    } catch (error) {
      print('خطأ في إضافة العقار البسيط: $error');
      throw Exception('فشل في إضافة العقار: $error');
    }
  }

  Future<bool> deleteProperty(String propertyId) async {
    try {
      await _db.collection('properties').doc(propertyId).delete();

      final storageRef = _storage.ref().child('properties/$propertyId');
      try {
        final listResult = await storageRef.listAll();
        for (var item in listResult.items) {
          await item.delete();
        }
      } catch (e) {
        print('خطأ في حذف الصور: $e');
      }

      return true;
    } catch (e) {
      print('خطأ في حذف العقار: $e');
      return false;
    }
  }

  Future<bool> updatePropertyApprovalStatus(
      String propertyId, PropertyApprovalStatus status) async {
    try {
      await _db.collection('properties').doc(propertyId).update({
        'approvalStatus': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('خطأ في تحديث حالة العقار: $e');
      return false;
    }
  }

  Future<List<PropertyModel>> getPropertiesByApprovalStatus(
      PropertyApprovalStatus status) async {
    try {
      final snapshot = await _db
          .collection('properties')
          .where('approvalStatus', isEqualTo: status.toString().split('.').last)
          .get();

      return snapshot.docs
          .map((doc) => PropertyModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('خطأ في جلب العقارات حسب الحالة: $e');
      return [];
    }
  }
}

// استثناء تجاوز الوقت
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
