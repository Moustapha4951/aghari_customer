import 'package:cloud_firestore/cloud_firestore.dart';
import 'property_approval_status.dart';

enum PropertyType { house, villa, apartment, store, hall, studio, land, other }

enum PropertyStatus { forSale, forRent }

class PropertyModel {
  String id;
  final String title;
  final String description;
  final String address;
  final PropertyType type;
  final PropertyStatus status;
  final double price;
  final double area;
  final int bedrooms;
  final int bathrooms;
  final int parkingSpaces;
  final int floors;
  final bool hasPool;
  final bool hasGarden;
  final String cityId;
  String? districtId;
  String? districtName;
  List<String> images;
  final Map<String, bool> features;
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> favoriteUserIds;
  final String? districtDocument;
  final PropertyApprovalStatus approvalStatus;

  PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.type,
    required this.status,
    required this.price,
    required this.area,
    required this.bedrooms,
    required this.bathrooms,
    required this.cityId,
    this.districtId,
    this.districtName,
    required this.parkingSpaces,
    required this.floors,
    required this.hasPool,
    required this.hasGarden,
    required this.images,
    required this.features,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.createdAt,
    required this.updatedAt,
    required this.favoriteUserIds,
    this.districtDocument,
    this.approvalStatus = PropertyApprovalStatus.pending,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    Map<String, bool> featuresMap = {};

    if (json['features'] != null) {
      if (json['features'] is Map) {
        (json['features'] as Map).forEach((key, value) {
          featuresMap[key.toString()] = value == true;
        });
      } else if (json['features'] is List) {
        for (var feature in json['features']) {
          if (feature is String) {
            featuresMap[feature] = true;
          }
        }
      }
    }

    List<String> imagesList = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        imagesList = List<String>.from(json['images']);
      } else if (json['images'] is Map) {
        imagesList =
            (json['images'] as Map).values.map((e) => e.toString()).toList();
      }
    }

    return PropertyModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      type: _parsePropertyType(json['type'] as String?),
      status: _parsePropertyStatus(json['status'] as String?),
      price: (json['price'] ?? 0).toDouble(),
      area: (json['area'] ?? 0).toDouble(),
      bedrooms: json['bedrooms'] ?? 0,
      bathrooms: json['bathrooms'] ?? 0,
      parkingSpaces: json['parkingSpaces'] ?? 0,
      floors: json['floors'] ?? 1,
      hasPool: json['hasPool'] ?? false,
      hasGarden: json['hasGarden'] ?? false,
      cityId: json['cityId'] ?? '',
      districtId: json['districtId'],
      districtName: json['districtName'],
      images: imagesList,
      features: featuresMap,
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      ownerPhone: json['ownerPhone'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? json['createdAt'].toDate()
              : DateTime.parse(json['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is Timestamp
              ? json['updatedAt'].toDate()
              : DateTime.parse(json['updatedAt'].toString()))
          : DateTime.now(),
      favoriteUserIds: List<String>.from(json['favoriteUserIds'] ?? []),
      districtDocument: json['districtDocument'],
      approvalStatus: _parseApprovalStatus(json['approvalStatus'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'address': address,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'price': price,
      'area': area,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'parkingSpaces': parkingSpaces,
      'floors': floors,
      'hasPool': hasPool,
      'hasGarden': hasGarden,
      'cityId': cityId,
      'districtId': districtId,
      'districtName': districtName,
      'images': images,
      'features': features,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'favoriteUserIds': favoriteUserIds,
      'districtDocument': districtDocument,
      'approvalStatus': approvalStatus.toString().split('.').last,
    };
  }

  static PropertyType _parsePropertyType(String? type) {
    if (type == null) return PropertyType.apartment;

    switch (type) {
      case 'apartment':
        return PropertyType.apartment;
      case 'villa':
        return PropertyType.villa;
      case 'house':
        return PropertyType.house;
      case 'store':
        return PropertyType.store;
      case 'hall':
        return PropertyType.hall;
      case 'studio':
        return PropertyType.studio;
      case 'land':
        return PropertyType.land;
      default:
        return PropertyType.other;
    }
  }

  static PropertyStatus _parsePropertyStatus(String? status) {
    if (status == null) return PropertyStatus.forSale;

    switch (status) {
      case 'forSale':
        return PropertyStatus.forSale;
      case 'forRent':
        return PropertyStatus.forRent;
      case 'sale':
        return PropertyStatus.forSale;
      case 'rent':
        return PropertyStatus.forRent;
      default:
        return PropertyStatus.forSale;
    }
  }

  static PropertyApprovalStatus _parseApprovalStatus(String? status) {
    if (status == null) return PropertyApprovalStatus.pending;

    switch (status) {
      case 'approved':
        return PropertyApprovalStatus.approved;
      case 'rejected':
        return PropertyApprovalStatus.rejected;
      case 'pending':
      default:
        return PropertyApprovalStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  static PropertyModel fromMap(Map<String, dynamic> map, String id) {
    map['id'] = id;
    return PropertyModel.fromJson(map);
  }

  PropertyModel copyWith({
    String? id,
    String? title,
    String? description,
    String? address,
    PropertyType? type,
    PropertyStatus? status,
    double? price,
    double? area,
    int? bedrooms,
    int? bathrooms,
    String? cityId,
    String? districtId,
    String? districtName,
    int? parkingSpaces,
    int? floors,
    bool? hasPool,
    bool? hasGarden,
    List<String>? images,
    Map<String, bool>? features,
    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? favoriteUserIds,
    String? districtDocument,
    PropertyApprovalStatus? approvalStatus,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      type: type ?? this.type,
      status: status ?? this.status,
      price: price ?? this.price,
      area: area ?? this.area,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      cityId: cityId ?? this.cityId,
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      parkingSpaces: parkingSpaces ?? this.parkingSpaces,
      floors: floors ?? this.floors,
      hasPool: hasPool ?? this.hasPool,
      hasGarden: hasGarden ?? this.hasGarden,
      images: images ?? this.images,
      features: features ?? this.features,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      favoriteUserIds: favoriteUserIds ?? this.favoriteUserIds,
      districtDocument: districtDocument ?? this.districtDocument,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }

  static String getLocalizedType(
      PropertyType type, String Function(String) translate) {
    switch (type) {
      case PropertyType.house:
        return translate('property_type_house');
      case PropertyType.villa:
        return translate('property_type_villa');
      case PropertyType.apartment:
        return translate('property_type_apartment');
      case PropertyType.store:
        return translate('property_type_store');
      case PropertyType.hall:
        return translate('property_type_hall');
      case PropertyType.studio:
        return translate('property_type_studio');
      case PropertyType.land:
        return translate('property_type_land');
      case PropertyType.other:
      default:
        return translate('property_type_other');
    }
  }

  static String getLocalizedStatus(
      PropertyStatus status, String Function(String) translate) {
    switch (status) {
      case PropertyStatus.forSale:
        return translate('property_status_sale');
      case PropertyStatus.forRent:
        return translate('property_status_rent');
      default:
        return translate('property_status_unknown');
    }
  }
}
