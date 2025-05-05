import 'package:cloud_firestore/cloud_firestore.dart';
import 'property_model.dart';

enum RequestStatus {
  pending, // قيد الانتظار
  approved, // موافق عليه
  completed, // مكتمل
  rejected, // مرفوض
}

class PropertyRequestModel {
  final String? id;
  final String userId;
  final String userName;
  final String phone;
  final String propertyType;
  final String city;
  final String district;
  final PropertyStatus propertyStatus;
  final double? minPrice;
  final double? maxPrice;
  final double? minSpace;
  final double? maxSpace;
  final int? bedrooms;
  final int? bathrooms;
  final String? additionalDetails;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PropertyRequestModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.phone,
    required this.propertyType,
    required this.city,
    required this.district,
    required this.propertyStatus,
    this.minPrice,
    this.maxPrice,
    this.minSpace,
    this.maxSpace,
    this.bedrooms,
    this.bathrooms,
    this.additionalDetails,
    this.status = RequestStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  factory PropertyRequestModel.fromMap(Map<String, dynamic> map, String id) {
    print('بدء تحويل طلب العقار من Map لمعرف: $id');

    // استخراج بيانات العقار من حقل propertyData إذا كان موجودًا
    Map<String, dynamic> propertyData = {};
    if (map['propertyData'] != null && map['propertyData'] is Map) {
      print(
          'استخراج بيانات العقار من حقل propertyData، النوع: ${map['propertyData'].runtimeType}');
      propertyData = Map<String, dynamic>.from(map['propertyData']);
    } else {
      print(
          'تحذير: حقل propertyData غير موجود أو ليس من نوع Map، سيتم استخدام البيانات الرئيسية فقط');
    }

    // استخراج قيم العناصر الأساسية وطباعتها للتشخيص
    final String userId = map['userId'] ?? '';
    final String userName = map['userName'] ?? '';
    final String phone = map['phone'] ?? '';
    final String propertyType =
        propertyData['propertyType'] ?? map['propertyType'] ?? '';
    final String city = propertyData['city'] ?? map['city'] ?? '';
    final String district = propertyData['district'] ?? map['district'] ?? '';

    print('تشخيص: userId = $userId, userName = $userName, phone = $phone');
    print(
        'تشخيص: propertyType = $propertyType, city = $city, district = $district');

    // معالجة الأسعار
    double? minPrice;
    if (propertyData['minPrice'] != null) {
      if (propertyData['minPrice'] is double) {
        minPrice = propertyData['minPrice'];
      } else if (propertyData['minPrice'] is int) {
        minPrice = propertyData['minPrice'].toDouble();
      } else if (propertyData['minPrice'] is String) {
        try {
          minPrice = double.parse(propertyData['minPrice']);
        } catch (e) {
          print(
              'خطأ في تحويل minPrice (propertyData): ${propertyData['minPrice']}');
        }
      }
    } else if (map['minPrice'] != null) {
      if (map['minPrice'] is double) {
        minPrice = map['minPrice'];
      } else if (map['minPrice'] is int) {
        minPrice = map['minPrice'].toDouble();
      } else if (map['minPrice'] is String) {
        try {
          minPrice = double.parse(map['minPrice']);
        } catch (e) {
          print('خطأ في تحويل minPrice (map): ${map['minPrice']}');
        }
      }
    }

    double? maxPrice;
    if (propertyData['maxPrice'] != null) {
      if (propertyData['maxPrice'] is double) {
        maxPrice = propertyData['maxPrice'];
      } else if (propertyData['maxPrice'] is int) {
        maxPrice = propertyData['maxPrice'].toDouble();
      } else if (propertyData['maxPrice'] is String) {
        try {
          maxPrice = double.parse(propertyData['maxPrice']);
        } catch (e) {
          print(
              'خطأ في تحويل maxPrice (propertyData): ${propertyData['maxPrice']}');
        }
      }
    } else if (map['maxPrice'] != null) {
      if (map['maxPrice'] is double) {
        maxPrice = map['maxPrice'];
      } else if (map['maxPrice'] is int) {
        maxPrice = map['maxPrice'].toDouble();
      } else if (map['maxPrice'] is String) {
        try {
          maxPrice = double.parse(map['maxPrice']);
        } catch (e) {
          print('خطأ في تحويل maxPrice (map): ${map['maxPrice']}');
        }
      }
    }

    print('تشخيص: minPrice = $minPrice, maxPrice = $maxPrice');

    // استخراج حالة العقار
    PropertyStatus propertyStatus;
    if (propertyData['propertyStatus'] != null) {
      propertyStatus =
          _getPropertyStatusFromString(propertyData['propertyStatus']);
      print(
          'تم استخراج propertyStatus من propertyData: ${propertyData['propertyStatus']} -> $propertyStatus');
    } else if (map['propertyStatus'] != null) {
      propertyStatus = _getPropertyStatusFromString(map['propertyStatus']);
      print(
          'تم استخراج propertyStatus من map: ${map['propertyStatus']} -> $propertyStatus');
    } else {
      propertyStatus = PropertyStatus.forSale;
      print(
          'لم يتم العثور على propertyStatus، تم استخدام القيمة الافتراضية: $propertyStatus');
    }

    return PropertyRequestModel(
      id: id,
      userId: userId,
      userName: userName,
      phone: phone,
      propertyType: propertyType,
      city: city,
      district: district,
      propertyStatus: propertyStatus,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minSpace: _extractDoubleOrNull(propertyData, map, 'minSpace'),
      maxSpace: _extractDoubleOrNull(propertyData, map, 'maxSpace'),
      bedrooms: _extractIntOrNull(propertyData, map, 'bedrooms'),
      bathrooms: _extractIntOrNull(propertyData, map, 'bathrooms'),
      additionalDetails:
          propertyData['additionalDetails'] ?? map['additionalDetails'] ?? '',
      status: _getStatusFromString(map['status'] ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // استخراج قيمة double من propertyData أو map
  static double? _extractDoubleOrNull(
      Map<String, dynamic> propertyData, Map<String, dynamic> map, String key) {
    if (propertyData[key] != null) {
      if (propertyData[key] is double) {
        return propertyData[key];
      } else if (propertyData[key] is int) {
        return propertyData[key].toDouble();
      } else if (propertyData[key] is String) {
        try {
          return double.parse(propertyData[key]);
        } catch (e) {
          print('خطأ في تحويل $key (propertyData): ${propertyData[key]}');
        }
      }
    } else if (map[key] != null) {
      if (map[key] is double) {
        return map[key];
      } else if (map[key] is int) {
        return map[key].toDouble();
      } else if (map[key] is String) {
        try {
          return double.parse(map[key]);
        } catch (e) {
          print('خطأ في تحويل $key (map): ${map[key]}');
        }
      }
    }
    return null;
  }

  // استخراج قيمة int من propertyData أو map
  static int? _extractIntOrNull(
      Map<String, dynamic> propertyData, Map<String, dynamic> map, String key) {
    if (propertyData[key] != null) {
      if (propertyData[key] is int) {
        return propertyData[key];
      } else if (propertyData[key] is double) {
        return propertyData[key].toInt();
      } else if (propertyData[key] is String) {
        try {
          return int.parse(propertyData[key]);
        } catch (e) {
          print('خطأ في تحويل $key (propertyData): ${propertyData[key]}');
        }
      }
    } else if (map[key] != null) {
      if (map[key] is int) {
        return map[key];
      } else if (map[key] is double) {
        return map[key].toInt();
      } else if (map[key] is String) {
        try {
          return int.parse(map[key]);
        } catch (e) {
          print('خطأ في تحويل $key (map): ${map[key]}');
        }
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'phone': phone,
      'propertyType': propertyType,
      'city': city,
      'district': district,
      'propertyStatus': propertyStatus.toString().split('.').last,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minSpace': minSpace,
      'maxSpace': maxSpace,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'additionalDetails': additionalDetails,
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static RequestStatus _getStatusFromString(String status) {
    switch (status) {
      case 'approved':
        return RequestStatus.approved;
      case 'completed':
        return RequestStatus.completed;
      case 'rejected':
        return RequestStatus.rejected;
      case 'pending':
      default:
        return RequestStatus.pending;
    }
  }

  static PropertyStatus _getPropertyStatusFromString(String status) {
    switch (status) {
      case 'forRent':
      case 'rent':
        return PropertyStatus.forRent;
      case 'forSale':
      case 'sale':
      default:
        return PropertyStatus.forSale;
    }
  }
}
