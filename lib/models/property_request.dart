class PropertyRequest {
  final String id;
  final String propertyId;
  final String userId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime requestDate;
  final String? notes;

  PropertyRequest({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.status,
    required this.requestDate,
    this.notes,
  });

  factory PropertyRequest.fromMap(Map<String, dynamic> map, String id) {
    return PropertyRequest(
      id: id,
      propertyId: map['propertyId'],
      userId: map['userId'],
      status: map['status'],
      requestDate: DateTime.parse(map['requestDate']),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'userId': userId,
      'status': status,
      'requestDate': requestDate.toIso8601String(),
      'notes': notes,
    };
  }
}