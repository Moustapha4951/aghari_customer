import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  final String id;
  final String title;
  final String description;
  final double discount;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? propertyId;
  final String? propertyTitle;
  final DateTime createdAt;
  final String createdBy;

  OfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.discount,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.propertyId,
    this.propertyTitle,
    required this.createdAt,
    required this.createdBy,
  });

  factory OfferModel.fromMap(Map<String, dynamic> map, String id) {
    print('بدء تحويل بيانات العرض: $id');
    try {
      // معالجة عنوان العرض
      final title = map['title'] is String ? map['title'] : '';
      if (title.isEmpty) {
        print('تحذير: عنوان العرض $id فارغ');
      }

      // معالجة وصف العرض
      final description =
          map['description'] is String ? map['description'] : '';

      // معالجة قيمة الخصم
      double discount = 0;
      try {
        if (map['discount'] != null) {
          if (map['discount'] is int) {
            discount = (map['discount'] as int).toDouble();
          } else if (map['discount'] is double) {
            discount = map['discount'] as double;
          } else if (map['discount'] is String) {
            discount = double.tryParse((map['discount'] as String)) ?? 0;
          }
        }
      } catch (e) {
        print(
            'خطأ في تحويل قيمة الخصم للعرض $id: $e، تم استخدام 0 كقيمة افتراضية');
      }

      // معالجة رابط الصورة
      final imageUrl = map['imageUrl'] is String ? map['imageUrl'] : '';

      // معالجة تاريخ البداية
      DateTime startDate = DateTime.now();
      try {
        if (map['startDate'] != null) {
          if (map['startDate'] is Timestamp) {
            startDate = (map['startDate'] as Timestamp).toDate();
          } else if (map['startDate'] is DateTime) {
            startDate = map['startDate'] as DateTime;
          } else if (map['startDate'] is String) {
            startDate = DateTime.parse(map['startDate']);
          } else if (map['startDate'] is Map) {
            // في حالة وجود تنسيق تاريخ مخصص
            final seconds = (map['startDate']['_seconds'] ?? 0) as int;
            final nanoseconds = (map['startDate']['_nanoseconds'] ?? 0) as int;
            startDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          }
        }
      } catch (e) {
        print(
            'خطأ في تحويل تاريخ البداية للعرض $id: $e، تم استخدام التاريخ الحالي');
      }

      // معالجة تاريخ الانتهاء
      DateTime endDate = DateTime.now().add(const Duration(days: 30));
      try {
        if (map['endDate'] != null) {
          if (map['endDate'] is Timestamp) {
            endDate = (map['endDate'] as Timestamp).toDate();
          } else if (map['endDate'] is DateTime) {
            endDate = map['endDate'] as DateTime;
          } else if (map['endDate'] is String) {
            endDate = DateTime.parse(map['endDate']);
          } else if (map['endDate'] is Map) {
            // في حالة وجود تنسيق تاريخ مخصص
            final seconds = (map['endDate']['_seconds'] ?? 0) as int;
            final nanoseconds = (map['endDate']['_nanoseconds'] ?? 0) as int;
            endDate = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          }
        }
      } catch (e) {
        print(
            'خطأ في تحويل تاريخ الانتهاء للعرض $id: $e، تم استخدام تاريخ بعد 30 يوم');
      }

      // معالجة حالة النشاط
      bool isActive = true;
      if (map['isActive'] is bool) {
        isActive = map['isActive'];
      }

      // معالجة معرف العقار المرتبط
      final propertyId = map['propertyId'] is String ? map['propertyId'] : null;

      // معالجة عنوان العقار المرتبط
      final propertyTitle =
          map['propertyTitle'] is String ? map['propertyTitle'] : null;

      // معالجة تاريخ الإنشاء
      DateTime createdAt = DateTime.now();
      try {
        if (map['createdAt'] != null) {
          if (map['createdAt'] is Timestamp) {
            createdAt = (map['createdAt'] as Timestamp).toDate();
          } else if (map['createdAt'] is DateTime) {
            createdAt = map['createdAt'] as DateTime;
          } else if (map['createdAt'] is String) {
            createdAt = DateTime.parse(map['createdAt']);
          } else if (map['createdAt'] is Map) {
            // في حالة وجود تنسيق تاريخ مخصص
            final seconds = (map['createdAt']['_seconds'] ?? 0) as int;
            final nanoseconds = (map['createdAt']['_nanoseconds'] ?? 0) as int;
            createdAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          }
        }
      } catch (e) {
        print(
            'خطأ في تحويل تاريخ الإنشاء للعرض $id: $e، تم استخدام التاريخ الحالي');
      }

      // معالجة الشخص المنشئ
      final createdBy = map['createdBy'] is String ? map['createdBy'] : '';

      final offer = OfferModel(
        id: id,
        title: title,
        description: description,
        discount: discount,
        imageUrl: imageUrl,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
        propertyId: propertyId,
        propertyTitle: propertyTitle,
        createdAt: createdAt,
        createdBy: createdBy,
      );

      print('تم تحويل بيانات العرض بنجاح: ${offer.title}');
      return offer;
    } catch (e) {
      print('خطأ في تحويل بيانات العرض $id: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'discount': discount,
      'imageUrl': imageUrl,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'createdAt': createdAt,
      'createdBy': createdBy,
    };
  }

  // نسخة محدثة من الكائن
  OfferModel copyWith({
    String? id,
    String? title,
    String? description,
    double? discount,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? propertyId,
    String? propertyTitle,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return OfferModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      discount: discount ?? this.discount,
      imageUrl: imageUrl ?? this.imageUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
