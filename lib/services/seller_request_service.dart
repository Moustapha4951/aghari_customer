import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/seller_request_model.dart';

class SellerRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // إرسال طلب بائع جديد مع الصور
  Future<void> submitSellerRequest({
    required String userId,
    required String userName,
    required String userPhone,
    required File idCardImage,
    required File licenseImage,
    String? notes,
  }) async {
    try {
      print('بدء إرسال طلب بائع جديد للمستخدم: $userId');

      // تحميل الصور إلى التخزين
      final idCardImageUrl =
          await _uploadImage(idCardImage, 'seller_requests/$userId/id_card');
      final licenseImageUrl =
          await _uploadImage(licenseImage, 'seller_requests/$userId/license');

      // إنشاء نموذج الطلب
      final request = SellerRequestModel(
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        status: SellerRequestStatus.pending,
        requestDate: DateTime.now(),
        idCardImageUrl: idCardImageUrl,
        licenseImageUrl: licenseImageUrl,
        notes: notes,
      );

      // حفظ الطلب في Firestore
      await _firestore.collection('sellerRequests').add(request.toMap());

      print('تم إرسال طلب البائع بنجاح');
    } catch (e) {
      print('خطأ في إرسال طلب البائع: $e');
      rethrow;
    }
  }

  // إضافة دالة عامة للاستخدام من خارج الخدمة
  Future<bool> uploadImage(File image, String path) async {
    try {
      // استدعاء الدالة الخاصة للتنفيذ الفعلي
      final imageUrl = await _uploadImage(image, path);
      // إذا وصلنا إلى هنا، فقد نجحت عملية الرفع
      return true;
    } catch (e) {
      print('فشل في عملية رفع الصورة: $e');
      return false;
    }
  }

  // الدالة الخاصة لتنفيذ رفع الصورة
  Future<String> _uploadImage(File image, String path) async {
    try {
      // إنشاء مرجع لملف الصورة في Firebase Storage
      final ref = _storage.ref().child(path);

      // تعيين خيارات الرفع لتجنب أي مشاكل
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      // رفع الصورة
      print('بدء رفع الصورة إلى المسار: $path');
      final uploadTask = ref.putFile(image, metadata);

      // مراقبة حالة الرفع للتشخيص
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('تقدم رفع الصورة: ${progress.toStringAsFixed(2)}%');
      });

      // انتظار انتهاء عملية الرفع
      final TaskSnapshot snapshot =
          await uploadTask.whenComplete(() => print('اكتمل رفع الصورة'));

      // الحصول على رابط الصورة
      final String imageUrl = await snapshot.ref.getDownloadURL();
      print('تم الحصول على رابط الصورة: $imageUrl');

      return imageUrl;
    } catch (e) {
      print('خطأ في رفع الصورة: $e');
      throw Exception('فشل في رفع الصورة: $e');
    }
  }

  // الحصول على طلبات البائع الخاصة بمستخدم معين
  Future<List<SellerRequestModel>> getUserSellerRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('sellerRequests')
          .where('userId', isEqualTo: userId)
          .orderBy('requestDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SellerRequestModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('خطأ في جلب طلبات البائع: $e');
      return [];
    }
  }

  // إضافة دالة للتحقق من وجود طلب نشط
  Future<bool> hasActiveRequest(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('sellerRequests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('خطأ في التحقق من وجود طلب نشط: $e');
      return false;
    }
  }
}
