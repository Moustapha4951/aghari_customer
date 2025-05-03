import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> ensureCollectionsExist() async {
  final db = FirebaseFirestore.instance;
  
  // التحقق من وجود مجموعة الطلبات وإنشاؤها بوثيقة مؤقتة إذا لم تكن موجودة
  try {
    final requestsSnapshot = await db.collection('propertyRequests').limit(1).get();
    if (requestsSnapshot.docs.isEmpty) {
      // إنشاء وثيقة مؤقتة لإنشاء المجموعة
      final tempDoc = await db.collection('propertyRequests').add({
        'temp': true,
        'createdAt': FieldValue.serverTimestamp()
      });
      // حذف الوثيقة المؤقتة بعد إنشاء المجموعة
      await tempDoc.delete();
      print('تم إنشاء مجموعة الطلبات');
    }
  } catch (e) {
    print('خطأ أثناء التحقق من مجموعة الطلبات: $e');
  }
  
  // التحقق من وجود مجموعة المفضلات وإنشاؤها بوثيقة مؤقتة إذا لم تكن موجودة
  try {
    final favoritesSnapshot = await db.collection('favorites').limit(1).get();
    if (favoritesSnapshot.docs.isEmpty) {
      // إنشاء وثيقة مؤقتة لإنشاء المجموعة
      final tempDoc = await db.collection('favorites').add({
        'temp': true,
        'createdAt': FieldValue.serverTimestamp()
      });
      // حذف الوثيقة المؤقتة بعد إنشاء المجموعة
      await tempDoc.delete();
      print('تم إنشاء مجموعة المفضلات');
    }
  } catch (e) {
    print('خطأ أثناء التحقق من مجموعة المفضلات: $e');
  }
} 