import 'package:cloud_firestore/cloud_firestore.dart';

enum SellerRequestStatus {
  pending,   // قيد الانتظار
  approved,  // تمت الموافقة
  rejected,  // مرفوض
}

class SellerRequestModel {
  final String? id;
  final String userId;
  final String userName;
  final String userPhone;
  final SellerRequestStatus status;
  final DateTime requestDate;
  final DateTime? processedDate;
  final String? processedBy;
  final String? idCardImageUrl;   // صورة بطاقة الهوية (جديد)
  final String? licenseImageUrl;  // صورة الترخيص/التسجيل (جديد)
  final String? notes;

  SellerRequestModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.status,
    required this.requestDate,
    this.processedDate,
    this.processedBy,
    this.idCardImageUrl,
    this.licenseImageUrl,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'status': status.toString().split('.').last,
      'requestDate': FieldValue.serverTimestamp(),
      'processedDate': processedDate,
      'processedBy': processedBy,
      'idCardImageUrl': idCardImageUrl,  // جديد
      'licenseImageUrl': licenseImageUrl,  // جديد
      'notes': notes,
    };
  }

  factory SellerRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return SellerRequestModel(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      status: _getStatusFromString(map['status'] ?? 'pending'),
      requestDate: (map['requestDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedDate: (map['processedDate'] as Timestamp?)?.toDate(),
      processedBy: map['processedBy'],
      idCardImageUrl: map['idCardImageUrl'],  // جديد
      licenseImageUrl: map['licenseImageUrl'],  // جديد
      notes: map['notes'],
    );
  }

  static SellerRequestStatus _getStatusFromString(String status) {
    switch (status) {
      case 'approved':
        return SellerRequestStatus.approved;
      case 'rejected':
        return SellerRequestStatus.rejected;
      case 'pending':
      default:
        return SellerRequestStatus.pending;
    }
  }
} 