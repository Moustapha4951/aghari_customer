import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/property_request.dart';

class PropertyRequestProvider with ChangeNotifier {
  final List<PropertyRequest> _requests = [];
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _userId;

  List<PropertyRequest> get requests => [..._requests];

  Future<void> fetchUserRequests() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await _db
        .collection('propertyRequests')
        .where('userId', isEqualTo: userId)
        .get();

    _requests.clear();
    for (var doc in snapshot.docs) {
      _requests.add(PropertyRequest.fromMap(doc.data(), doc.id));
    }
    notifyListeners();
  }

  Future<void> createRequest(String propertyId, {String? notes}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final request = PropertyRequest(
      id: '',
      propertyId: propertyId,
      userId: userId,
      status: 'pending',
      requestDate: DateTime.now(),
      notes: notes,
    );

    final docRef =
        await _db.collection('propertyRequests').add(request.toMap());
    _requests.add(PropertyRequest.fromMap(request.toMap(), docRef.id));
    notifyListeners();
  }

  Future<void> cancelRequest(String requestId) async {
    await _db.collection('propertyRequests').doc(requestId).delete();
    _requests.removeWhere((request) => request.id == requestId);
    notifyListeners();
  }

  void setCurrentUserId(String userId) {
    _userId = userId;
    notifyListeners();
    fetchUserRequests();
  }

  Future<void> fetchReceivedRequests(String ownerId) async {
    try {
      // 1. أولاً، استرجع كل عقارات المالك
      final propertySnapshot = await _db
          .collection('properties')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      // 2. استخرج معرفات العقارات
      List<String> propertyIds =
          propertySnapshot.docs.map((doc) => doc.id).toList();

      if (propertyIds.isEmpty) {
        _requests.clear();
        notifyListeners();
        return;
      }

      // 3. استرجع كل الطلبات المرتبطة بهذه العقارات
      // لأن Firestore لا يدعم "whereIn" مع أكثر من 10 قيم، نقسم القائمة إذا كانت كبيرة
      _requests.clear();

      for (int i = 0; i < propertyIds.length; i += 10) {
        int end = (i + 10 < propertyIds.length) ? i + 10 : propertyIds.length;
        List<String> batch = propertyIds.sublist(i, end);

        final requestsSnapshot = await _db
            .collection('propertyRequests')
            .where('propertyId', whereIn: batch)
            .get();

        for (var doc in requestsSnapshot.docs) {
          _requests.add(PropertyRequest.fromMap(doc.data(), doc.id));
        }
      }

      notifyListeners();
    } catch (e) {
      print('خطأ في استرجاع الطلبات المستلمة: $e');
      rethrow;
    }
  }
}
