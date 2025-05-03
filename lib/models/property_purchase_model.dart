import 'package:cloud_firestore/cloud_firestore.dart';

enum PurchaseStatus {
  pending, // قيد الانتظار
  approved, // موافق عليه
  rejected, // مرفوض
  completed, // تم الشراء
  cancelled, // ملغي
}

class PropertyPurchaseModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String propertyId;
  final String propertyTitle;
  final double propertyPrice;
  final String propertyType;
  final String propertyStatus;
  final String city;
  final String district;
  final double propertyArea;
  final int bedrooms;
  final int bathrooms;
  final String notes;
  final String status;
  final DateTime purchaseDate;
  final DateTime? lastUpdated;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String? rejectionReason; // سبب الرفض
  final String? adminNotes; // ملاحظات الإدارة

  PropertyPurchaseModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyPrice,
    required this.propertyType,
    required this.propertyStatus,
    required this.city,
    required this.district,
    required this.propertyArea,
    required this.bedrooms,
    required this.bathrooms,
    required this.notes,
    required this.status,
    required this.purchaseDate,
    this.lastUpdated,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    this.rejectionReason,
    this.adminNotes,
  });

  factory PropertyPurchaseModel.fromMap(Map<String, dynamic> data, String id) {
    return PropertyPurchaseModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      propertyId: data['propertyId'] ?? '',
      propertyTitle: data['propertyTitle'] ?? '',
      propertyPrice: (data['propertyPrice'] ?? 0).toDouble(),
      propertyType: data['propertyType'] ?? '',
      propertyStatus: data['propertyStatus'] ?? '',
      city: data['city'] ?? '',
      district: data['district'] ?? '',
      propertyArea: (data['propertyArea'] ?? 0).toDouble(),
      bedrooms: data['bedrooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      notes: data['notes'] ?? '',
      status: data['status'] ?? 'pending',
      purchaseDate: data['purchaseDate'] != null
          ? (data['purchaseDate'] as Timestamp).toDate()
          : DateTime.now(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerPhone: data['ownerPhone'] ?? '',
      rejectionReason: data['rejectionReason'],
      adminNotes: data['adminNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'propertyPrice': propertyPrice,
      'propertyType': propertyType,
      'propertyStatus': propertyStatus,
      'city': city,
      'district': district,
      'propertyArea': propertyArea,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'notes': notes,
      'status': status,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'lastUpdated':
          lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'rejectionReason': rejectionReason,
      'adminNotes': adminNotes,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'propertyPrice': propertyPrice,
      'propertyType': propertyType,
      'propertyStatus': propertyStatus,
      'city': city,
      'district': district,
      'propertyArea': propertyArea,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'notes': notes,
      'status': status,
      'purchaseDate': purchaseDate.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'rejectionReason': rejectionReason,
      'adminNotes': adminNotes,
    };
  }

  factory PropertyPurchaseModel.fromJson(Map<String, dynamic> json) {
    return PropertyPurchaseModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhone: json['userPhone'] ?? '',
      propertyId: json['propertyId'] ?? '',
      propertyTitle: json['propertyTitle'] ?? '',
      propertyPrice: (json['propertyPrice'] ?? 0).toDouble(),
      propertyType: json['propertyType'] ?? '',
      propertyStatus: json['propertyStatus'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      propertyArea: (json['propertyArea'] ?? 0).toDouble(),
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'pending',
      purchaseDate: DateTime.fromMillisecondsSinceEpoch(
          json['purchaseDate'] ?? DateTime.now().millisecondsSinceEpoch),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastUpdated'])
          : null,
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      ownerPhone: json['ownerPhone'] ?? '',
      rejectionReason: json['rejectionReason'],
      adminNotes: json['adminNotes'],
    );
  }

  PropertyPurchaseModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? propertyId,
    String? propertyTitle,
    double? propertyPrice,
    String? propertyType,
    String? propertyStatus,
    String? city,
    String? district,
    double? propertyArea,
    int? bedrooms,
    int? bathrooms,
    String? notes,
    String? status,
    DateTime? purchaseDate,
    DateTime? lastUpdated,
    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    String? rejectionReason,
    String? adminNotes,
  }) {
    return PropertyPurchaseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyPrice: propertyPrice ?? this.propertyPrice,
      propertyType: propertyType ?? this.propertyType,
      propertyStatus: propertyStatus ?? this.propertyStatus,
      city: city ?? this.city,
      district: district ?? this.district,
      propertyArea: propertyArea ?? this.propertyArea,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}
