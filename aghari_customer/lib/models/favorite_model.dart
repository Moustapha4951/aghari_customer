import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteModel {
  final String id;
  final String userId;
  final String propertyId;
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.createdAt,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json, String id) {
    return FavoriteModel(
      id: id,
      userId: json['userId'] ?? '',
      propertyId: json['propertyId'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'propertyId': propertyId,
      'createdAt': createdAt,
    };
  }
} 