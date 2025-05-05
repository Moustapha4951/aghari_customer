import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offer_model.dart';

class OfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // جلب جميع العروض النشطة
  Future<List<OfferModel>> getActiveOffers() async {
    try {
      print('جاري جلب العروض النشطة من كولكشن offers...');

      // تحقق من وجود كولكشن العروض
      try {
        final collections =
            await _firestore.collection('offers').limit(1).get();
        print(
            'حالة كولكشن العروض: ${collections.docs.isEmpty ? "فارغ" : "يحتوي على بيانات"}');
      } catch (e) {
        print('خطأ في التحقق من وجود كولكشن العروض: $e');
      }

      // الحصول على جميع العروض النشطة بدون التحقق من التاريخ هنا
      final snapshot = await _firestore
          .collection('offers')
          .where('isActive', isEqualTo: true)
          .get();

      print('تم العثور على ${snapshot.docs.length} عرض من Firestore');

      if (snapshot.docs.isEmpty) {
        // تحقق من وجود أي عروض (حتى غير النشطة) للتشخيص
        final allOffersSnapshot =
            await _firestore.collection('offers').limit(5).get();

        if (allOffersSnapshot.docs.isEmpty) {
          print('لا توجد أي عروض في كولكشن offers - الكولكشن فارغ تماماً');
        } else {
          print(
              'يوجد ${allOffersSnapshot.docs.length} عرض، ولكن بدون عروض نشطة (isActive = true)');
          // طباعة نموذج للعروض الموجودة للتشخيص
          for (var doc in allOffersSnapshot.docs) {
            print('معرف العرض: ${doc.id}');
            print(
                'حالة النشاط: ${doc.data().containsKey('isActive') ? doc.data()['isActive'] : 'غير محدد'}');
            print('---');
          }
        }
        return [];
      }

      // طباعة مثال لبيانات العرض الأول للتشخيص
      if (snapshot.docs.isNotEmpty) {
        print('مثال بيانات العرض الأول: ${snapshot.docs.first.data()}');

        // طباعة معلومات عن وجود عقارات مرتبطة بالعروض
        int offersWithProperty = 0;
        for (var doc in snapshot.docs) {
          if (doc.data().containsKey('propertyId') &&
              doc.data()['propertyId'] != null) {
            offersWithProperty++;
            print('العرض ${doc.id} مرتبط بالعقار: ${doc.data()['propertyId']}');
          }
        }
        print(
            'إجمالي العروض المرتبطة بعقارات: $offersWithProperty من أصل ${snapshot.docs.length}');
      }

      // تحويل البيانات إلى كائنات OfferModel مع معالجة الأخطاء لكل عنصر
      final List<OfferModel> offers = [];

      for (var doc in snapshot.docs) {
        try {
          print('جاري تحويل العرض ${doc.id}...');
          print('بيانات العرض: ${doc.data()}');

          final offer = OfferModel.fromMap(doc.data(), doc.id);

          // تحقق فقط من أن العرض لم ينته بعد
          final now = DateTime.now();
          if (offer.endDate.isAfter(now) ||
              offer.endDate.isAtSameMomentAs(now)) {
            offers.add(offer);
            print('تمت إضافة العرض: ${offer.title}');
            if (offer.propertyId != null) {
              print(
                  'تمت إضافة عرض مرتبط بالعقار ${offer.propertyId}: ${offer.title}');
            }
          } else {
            print(
                'تم استبعاد العرض ${doc.id} لأنه منتهي الصلاحية (${offer.endDate})');
          }
        } catch (e) {
          print('خطأ في تحويل العرض ${doc.id}: $e');
          // تجاهل العروض التي تسبب أخطاء في التحويل
          continue;
        }
      }

      print('تم تحويل ${offers.length} عرض بنجاح');

      // ترتيب العروض: أولاً العروض المرتبطة بالعقارات، ثم حسب تاريخ الانتهاء (الأقرب للانتهاء أولاً)
      offers.sort((a, b) {
        // إذا كان أحدهما فقط مرتبط بعقار، ضعه في المقدمة
        if (a.propertyId != null && b.propertyId == null) return -1;
        if (a.propertyId == null && b.propertyId != null) return 1;

        // إذا كان كلاهما مرتبط بعقار أو كلاهما غير مرتبط، رتب حسب تاريخ الانتهاء
        return a.endDate.compareTo(b.endDate);
      });

      return offers;
    } catch (e) {
      print('خطأ في جلب العروض: $e');
      // إرجاع قائمة فارغة بدلاً من رمي خطأ لتجنب فشل تحميل الشاشة
      return [];
    }
  }

  // جلب العروض الخاصة بعقار معين
  Future<List<OfferModel>> getOffersForProperty(String propertyId) async {
    try {
      // جلب العروض المرتبطة بعقار معين بدون شرط التاريخ أولاً
      final snapshot = await _firestore
          .collection('offers')
          .where('propertyId', isEqualTo: propertyId)
          .where('isActive', isEqualTo: true)
          .get();

      // تحويل البيانات إلى كائنات OfferModel
      final List<OfferModel> offers = [];

      for (var doc in snapshot.docs) {
        try {
          final offer = OfferModel.fromMap(doc.data(), doc.id);
          // فلترة العروض غير المنتهية
          if (!offer.endDate.isBefore(DateTime.now())) {
            offers.add(offer);
          }
        } catch (e) {
          print('خطأ في تحويل عرض العقار ${doc.id}: $e');
          continue;
        }
      }

      return offers;
    } catch (e) {
      print('خطأ في جلب عروض العقار: $e');
      return [];
    }
  }

  // جلب تفاصيل عرض محدد
  Future<OfferModel?> getOfferById(String offerId) async {
    try {
      final doc = await _firestore.collection('offers').doc(offerId).get();

      if (!doc.exists) {
        print('لم يتم العثور على العرض بالمعرف: $offerId');
        return null;
      }

      try {
        return OfferModel.fromMap(doc.data()!, doc.id);
      } catch (e) {
        print('خطأ في تحويل بيانات العرض $offerId: $e');
        return null;
      }
    } catch (e) {
      print('خطأ في جلب تفاصيل العرض: $e');
      return null;
    }
  }
}
