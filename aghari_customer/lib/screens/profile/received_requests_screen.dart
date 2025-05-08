import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../localization/app_localizations.dart';
import 'dart:math' as math; // إضافة مكتبة الرياضيات
import 'package:shared_preferences/shared_preferences.dart'; // إضافة SharedPreferences
import 'dart:convert'; // إضافة مكتبة تحويل JSON

class ReceivedRequestsScreen extends StatefulWidget {
  const ReceivedRequestsScreen({Key? key}) : super(key: key);

  @override
  State<ReceivedRequestsScreen> createState() => _ReceivedRequestsScreenState();
}

class _ReceivedRequestsScreenState extends State<ReceivedRequestsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabController;
  List<Map<String, dynamic>> _generalPropertyRequests = [];
  List<Map<String, dynamic>> _sellerPropertyRequests = [];
  // متغير جديد لتخزين حالات الطلبات المحفوظة محلياً
  Map<String, Map<String, dynamic>> _savedRequestStates = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedRequestStates();
    _loadAllRequests();
  }

  // دالة جديدة لتحميل حالات الطلبات المحفوظة
  Future<void> _loadSavedRequestStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStatesJson = prefs.getString('saved_request_states');

      if (savedStatesJson != null) {
        final Map<String, dynamic> savedData =
            Map<String, dynamic>.from(jsonDecode(savedStatesJson) as Map);

        setState(() {
          _savedRequestStates = savedData.map((key, value) =>
              MapEntry(key, Map<String, dynamic>.from(value as Map)));
        });

        print('تم تحميل ${_savedRequestStates.length} حالة طلب محفوظة محلياً');
      }
    } catch (e) {
      print('خطأ في تحميل حالات الطلبات المحفوظة: $e');
    }
  }

  // دالة جديدة لحفظ حالات الطلبات
  Future<void> _saveRequestStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'saved_request_states', jsonEncode(_savedRequestStates));
      print('تم حفظ ${_savedRequestStates.length} حالة طلب محلياً');
    } catch (e) {
      print('خطأ في حفظ حالات الطلبات: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAllRequests();
  }

  Future<void> _loadAllRequests() async {
    await _loadSellerRequests();
    await _loadGeneralRequests();
  }

  Future<void> _loadSellerRequests() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _sellerPropertyRequests = [];
    });

    try {
      // الحصول على معرف المستخدم الحالي
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        print('المستخدم غير مسجل دخول');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('تحميل طلبات البائع للمستخدم: ${user.id}');
      print('رقم هاتف المستخدم: ${user.phone}');

      // أولاً: تحميل جميع العقارات الخاصة بالبائع
      final propertiesSnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .where('ownerId', isEqualTo: user.id)
          .get();

      final propertyIds = propertiesSnapshot.docs.map((doc) => doc.id).toList();
      print('تم العثور على ${propertyIds.length} عقار للبائع');

      // طباعة معرفات العقارات للتشخيص
      if (propertyIds.isNotEmpty) {
        print('معرفات العقارات: $propertyIds');
      } else {
        print('لا توجد عقارات مرتبطة بهذا المستخدم');
        // التحقق من أن معرف المالك مخزن بشكل صحيح في العقارات
        print('التحقق من العقارات باستخدام استعلام مختلف...');

        final checkPropertiesSnapshot =
            await FirebaseFirestore.instance.collection('properties').get();

        print('إجمالي عدد العقارات في النظام: ${checkPropertiesSnapshot.size}');

        for (var doc in checkPropertiesSnapshot.docs) {
          final data = doc.data();
          print('عقار: ${doc.id} - المالك: ${data['ownerId']}');
        }
      }

      // محاولة ثانية باستخدام رقم الهاتف
      if (propertyIds.isEmpty) {
        print('محاولة البحث باستخدام رقم الهاتف بدلاً من معرف المستخدم...');

        final phonePropertiesSnapshot = await FirebaseFirestore.instance
            .collection('properties')
            .where('ownerPhone', isEqualTo: user.phone)
            .get();

        print(
            'تم العثور على ${phonePropertiesSnapshot.size} عقار باستخدام رقم الهاتف');

        if (phonePropertiesSnapshot.size > 0) {
          final phonePropertyIds =
              phonePropertiesSnapshot.docs.map((doc) => doc.id).toList();
          propertyIds.addAll(phonePropertyIds);
          print('معرفات العقارات المحدثة: $propertyIds');
        }
      }

      if (propertyIds.isEmpty) {
        // لا توجد عقارات للبائع
        print(
            'لم يتم العثور على أي عقارات للبائع. التحقق من الطلبات المباشرة...');
      }

      // محاولة مباشرة للتحقق من وجود طلبات للبائع
      print('محاولة التحقق من طلبات البائع بشكل مباشر...');

      // استعلام للتحقق المباشر من طلبات البائع
      final directRequestsSnapshot = await FirebaseFirestore.instance
          .collection('sellerRequests')
          .where('sellerId', isEqualTo: user.id)
          .get();

      print(
          'تم العثور على ${directRequestsSnapshot.size} طلب باستخدام معرف البائع المباشر');

      // محاولة أخرى باستخدام رقم الهاتف
      final phoneRequestsSnapshot = await FirebaseFirestore.instance
          .collection('sellerRequests')
          .where('sellerPhone', isEqualTo: user.phone)
          .get();

      print(
          'تم العثور على ${phoneRequestsSnapshot.size} طلب باستخدام رقم هاتف البائع');

      // تحميل جميع طلبات العقارات (بدون فلترة مسبقة)
      final requestsSnapshot =
          await FirebaseFirestore.instance.collection('sellerRequests').get();

      print('تم استلام ${requestsSnapshot.docs.length} طلبات من Firebase');

      // طباعة هيكل البيانات للطلب الأول للتشخيص
      if (requestsSnapshot.docs.isNotEmpty) {
        print('بيانات أول طلب في المجموعة:');
        final firstRequest = requestsSnapshot.docs.first.data();
        firstRequest.forEach((key, value) {
          print('$key: $value');
        });
      }

      // تصفية الطلبات يدويًا في التطبيق بدلاً من القيام بذلك في قاعدة البيانات
      final List<Map<String, dynamic>> requests = [];

      for (var doc in requestsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String propertyId = data['propertyId'] ?? '';

        // طباعة تفاصيل الطلب للتشخيص
        print('-----');
        print('فحص الطلب: ${doc.id}');
        print('معرف العقار في الطلب: $propertyId');

        // التحقق من وجود معرف بائع مباشر
        final String? sellerId = data['sellerId'];
        final String? sellerPhone = data['sellerPhone'];

        bool isSellerRequest = false;

        if (sellerId != null && sellerId == user.id) {
          print('هذا الطلب مرتبط مباشرة بمعرف البائع!');
          isSellerRequest = true;
        }

        if (sellerPhone != null && sellerPhone == user.phone) {
          print('هذا الطلب مرتبط مباشرة برقم هاتف البائع!');
          isSellerRequest = true;
        }

        // تحقق مما إذا كان هذا الطلب لأحد عقارات البائع
        if (propertyIds.contains(propertyId)) {
          print('تطابق: هذا الطلب ينتمي لعقار هذا البائع');
          isSellerRequest = true;
        }

        if (isSellerRequest) {
          requests.add({
            'id': doc.id,
            'userId': data['userId'] ?? '',
            'userName': data['userName'] ?? '',
            'userPhone': data['phone'] ?? '',
            'propertyId': propertyId,
            'propertyTitle': data['propertyTitle'] ?? '',
            'status': data['status'] ?? 'pending',
            'createdAt': data['createdAt'],
            'message': data['message'] ?? '',
          });
        } else {
          print('لا تطابق: هذا الطلب لا ينتمي لهذا البائع');
        }
        print('-----');
      }

      // ترتيب الطلبات حسب التاريخ (الأحدث أولاً)
      requests.sort((a, b) {
        final aCreatedAt = a['createdAt'] as Timestamp?;
        final bCreatedAt = b['createdAt'] as Timestamp?;

        if (aCreatedAt == null || bCreatedAt == null) return 0;
        return bCreatedAt.compareTo(aCreatedAt);
      });

      if (mounted) {
        setState(() {
          _sellerPropertyRequests = requests;
          _isLoading = false;
        });
        print('تم تحميل ${requests.length} طلب بائع بنجاح');

        // عرض ملخص للطلبات المحملة
        if (requests.isNotEmpty) {
          print('ملخص الطلبات المحملة:');
          for (int i = 0; i < requests.length; i++) {
            print(
                'طلب ${i + 1}: العقار ${requests[i]['propertyTitle']} - الحالة: ${requests[i]['status']}');
          }
        }
      }
    } catch (e) {
      print('خطأ في تحميل طلبات البائع: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل طلبات البائع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadGeneralRequests() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _generalPropertyRequests = [];
    });

    try {
      print('بدء تحميل الطلبات العامة...');

      // جلب معلومات المستخدم الحالي
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        print('المستخدم غير مسجل دخول لتحميل الطلبات العامة');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('تحميل الطلبات العامة للمستخدم: ${user.id}');
      print('رقم هاتف المستخدم: ${user.phone}');

      // جلب الطلبات العامة من Firebase
      print('استعلام مجموعة propertyRequests...');

      final requestsSnapshot = await FirebaseFirestore.instance
          .collection('propertyRequests')
          .orderBy('createdAt', descending: true)
          .get();

      print('تم استلام ${requestsSnapshot.docs.length} طلب عام');

      // طباعة نموذج من أول طلب للتشخيص إذا وجد
      if (requestsSnapshot.docs.isNotEmpty) {
        print('بيانات أول طلب عام:');
        final firstDoc = requestsSnapshot.docs.first;
        final firstData = firstDoc.data();
        firstData.forEach((key, value) {
          print('$key: $value');
        });
      }

      // جمع الطلبات العامة في قائمة
      final List<Map<String, dynamic>> requests = [];

      for (var doc in requestsSnapshot.docs) {
        try {
          final data = doc.data();
          // استخراج propertyData إذا كان موجوداً
          final propertyData =
              data['propertyData'] as Map<String, dynamic>? ?? {};

          // تحديد نوع العقار بشكل صحيح
          String propertyType = '';

          // أولاً التحقق من حقل propertyType في الجذر
          if (data['propertyType'] != null &&
              data['propertyType'].toString().isNotEmpty) {
            propertyType = data['propertyType'].toString();
          }
          // ثم التحقق من حقل type في الجذر
          else if (data['type'] != null && data['type'].toString().isNotEmpty) {
            propertyType = data['type'].toString();
          }
          // أخيراً التحقق من propertyData
          else if (propertyData['type'] != null &&
              propertyData['type'].toString().isNotEmpty) {
            propertyType = propertyData['type'].toString();
          } else if (propertyData['propertyType'] != null &&
              propertyData['propertyType'].toString().isNotEmpty) {
            propertyType = propertyData['propertyType'].toString();
          }

          // طباعة نوع العقار لفحص البيانات المسترجعة
          print('نوع العقار المسترجع للطلب ${doc.id}: $propertyType');

          final request = {
            'id': doc.id,
            'userId': data['userId'] ?? '',
            'userName': data['userName'] ?? '',
            'userPhone': data['phone'] ?? '',
            'createdAt': data['createdAt'] ?? Timestamp.now(),
            'status': data['status'] ?? 'pending',

            // معلومات نوع العقار والحالة
            'propertyType': propertyType,
            'propertyStatus':
                propertyData['status'] ?? data['propertyStatus'] ?? 'forSale',

            // معلومات الموقع
            'city': propertyData['city'] ?? data['city'] ?? '',
            'district': propertyData['district'] ?? data['district'] ?? '',

            // معلومات السعر والمساحة
            'minPrice': propertyData['minPrice'] ?? data['minPrice'],
            'maxPrice': propertyData['maxPrice'] ?? data['maxPrice'],
            'minSpace': propertyData['minSpace'] ?? data['minSpace'],
            'maxSpace': propertyData['maxSpace'] ?? data['maxSpace'],

            // معلومات الغرف والحمامات
            'bedrooms': propertyData['bedrooms'] ?? data['bedrooms'],
            'bathrooms': propertyData['bathrooms'] ?? data['bathrooms'],

            // معلومات إضافية
            'additionalDetails': propertyData['additionalDetails'] ??
                data['additionalDetails'] ??
                '',

            // إذا كان يستخدم النموذج الجديد للطلبات
            'type': data['type'] ?? propertyData['type'] ?? propertyType,
            'area': data['area'] ?? propertyData['area'] ?? 0,
            'budget': data['budget'] ?? propertyData['budget'] ?? 0,
            'location': data['location'] ?? propertyData['location'] ?? '',
            'description':
                data['description'] ?? propertyData['description'] ?? '',
          };

          print('إضافة طلب عام: ${doc.id}');
          requests.add(request);
        } catch (e) {
          print('خطأ في معالجة طلب عام: ${doc.id}, الخطأ: $e');
        }
      }

      // ترتيب الطلبات حسب التاريخ (الأحدث أولاً)
      requests.sort((a, b) {
        final aCreatedAt = a['createdAt'] as Timestamp?;
        final bCreatedAt = b['createdAt'] as Timestamp?;

        if (aCreatedAt == null || bCreatedAt == null) return 0;
        return bCreatedAt.compareTo(aCreatedAt);
      });

      if (mounted) {
        setState(() {
          _generalPropertyRequests = requests;

          // تطبيق الحالات المحفوظة محلياً على الطلبات المحملة
          for (int i = 0; i < _generalPropertyRequests.length; i++) {
            final requestId = _generalPropertyRequests[i]['id'];
            if (_savedRequestStates.containsKey(requestId)) {
              _generalPropertyRequests[i]['status'] =
                  _savedRequestStates[requestId]!['status'];
              _generalPropertyRequests[i]['rejectionReason'] =
                  _savedRequestStates[requestId]!['rejectionReason'];
              _generalPropertyRequests[i]['actionDate'] =
                  _savedRequestStates[requestId]!['actionDate'];
              _generalPropertyRequests[i]['localChange'] = true;
            }
          }

          _isLoading = false;
        });

        print('تم تحميل ${requests.length} طلب عام بنجاح');
        print('ملخص البيانات:');
        print('- عدد طلبات البائع: ${_sellerPropertyRequests.length}');
        print('- عدد الطلبات العامة: ${_generalPropertyRequests.length}');

        // طباعة أنواع العقارات المطلوبة
        if (requests.isNotEmpty) {
          print('أنواع العقارات المطلوبة:');
          for (int i = 0; i < requests.length; i++) {
            print(
                'طلب ${i + 1}: النوع: ${requests[i]['propertyType']}, الحالة: ${requests[i]['propertyStatus']}');
          }
        }
      }
    } catch (e) {
      print('خطأ في تحميل الطلبات العامة: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل الطلبات العامة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isFrench = localizations.isFrench();

    return Scaffold(
      appBar: AppBar(
        title: Text(isFrench
            ? localizations.translate('property_requests_title')
            : 'طلبات العقارات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
                text: isFrench
                    ? localizations.translate('direct_requests')
                    : 'طلبات مباشرة'),
            Tab(
                text: isFrench
                    ? localizations.translate('general_requests')
                    : 'طلبات عامة'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('تحديث قائمة الطلبات...');
              _loadAllRequests();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(isFrench
                        ? localizations.translate('updating_data')
                        : 'جاري تحديث البيانات...')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSellerRequestsList(isFrench, localizations),
                _buildGeneralRequestsList(isFrench, localizations),
              ],
            ),
    );
  }

  Widget _buildGeneralRequestsList(
      bool isFrench, AppLocalizations localizations) {
    print('بناء قائمة الطلبات العامة (${_generalPropertyRequests.length} طلب)');
    if (_generalPropertyRequests.isEmpty) {
      print('القائمة فارغة! جاري عرض رسالة عدم وجود طلبات');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isFrench
                  ? localizations.translate('no_general_requests')
                  : 'لا توجد طلبات عامة حالياً',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(
                isFrench
                    ? localizations.translate('refresh_requests')
                    : 'تحديث الطلبات',
              ),
              onPressed: () {
                print('إعادة تحميل الطلبات العامة...');
                _loadGeneralRequests();
              },
            ),
          ],
        ),
      );
    }

    print('عرض قائمة الطلبات العامة...');
    // طباعة تفاصيل بعض الطلبات للتشخيص
    final minValue = math.min(3, _generalPropertyRequests.length);
    for (int i = 0; i < minValue; i++) {
      print(
          'طلب ${i + 1}: معرف=${_generalPropertyRequests[i]['id']}, نوع=${_generalPropertyRequests[i]['propertyType']}, حالة=${_generalPropertyRequests[i]['status']}');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _generalPropertyRequests.length,
      itemBuilder: (context, index) {
        final request = _generalPropertyRequests[index];
        return _buildGeneralRequestCard(request, isFrench, localizations);
      },
    );
  }

  Widget _buildGeneralRequestCard(Map<String, dynamic> request, bool isFrench,
      AppLocalizations localizations) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final createdAt = request['createdAt'] != null
        ? (request['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    return InkWell(
      onTap: () => _showGeneralRequestDetails(request, isFrench, localizations),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس البطاقة مع نوع العقار والحالة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.home,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              _getArabicPropertyType(request['propertyType']),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              request['propertyStatus'] == 'forRent'
                                  ? Icons.key
                                  : Icons.sell,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              request['propertyStatus'] == 'forRent'
                                  ? 'للإيجار'
                                  : 'للبيع',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(
                      request['status'] ?? 'pending', isFrench, localizations),
                ],
              ),
              const SizedBox(height: 12),

              // معلومات الغرف والحمامات
              if (request['bedrooms'] != null || request['bathrooms'] != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (request['bedrooms'] != null) ...[
                        Icon(Icons.bed, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${request['bedrooms']} غرف',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                      if (request['bedrooms'] != null &&
                          request['bathrooms'] != null)
                        const SizedBox(width: 16),
                      if (request['bathrooms'] != null) ...[
                        Icon(Icons.bathtub, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${request['bathrooms']} حمام',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // تفاصيل الموقع
              if (request['city'] != null &&
                  request['city'].toString().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_getArabicCity(request['city'])}${request['district'] != null && request['district'].toString().isNotEmpty ? ' - ${_getArabicDistrict(request['district'])}' : ''}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else if (request['location'] != null &&
                  request['location'].toString().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${request['location']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // تفاصيل السعر والمساحة
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (request['minPrice'] != null ||
                        request['maxPrice'] != null)
                      Row(
                        children: [
                          Icon(Icons.monetization_on, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _buildPriceRange(request['minPrice'],
                                  request['maxPrice'], isFrench, localizations),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (request['budget'] != null && request['budget'] > 0)
                      Row(
                        children: [
                          Icon(Icons.monetization_on, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'الميزانية: ${request['budget']} أوقية',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (request['minSpace'] != null ||
                        request['maxSpace'] != null) ...[
                      if (request['minPrice'] != null ||
                          request['maxPrice'] != null ||
                          (request['budget'] != null && request['budget'] > 0))
                        const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.square_foot, color: Colors.brown[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _buildAreaRange(request['minSpace'],
                                  request['maxSpace'], isFrench, localizations),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else if (request['area'] != null &&
                        request['area'] > 0) ...[
                      if (request['minPrice'] != null ||
                          request['maxPrice'] != null ||
                          (request['budget'] != null && request['budget'] > 0))
                        const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.square_foot, color: Colors.brown[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'المساحة: ${request['area']} م²',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // وصف الطلب
              if (request['description'] != null &&
                  request['description'].toString().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            'الوصف:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request['description'],
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              if (request['description'] != null &&
                  request['description'].toString().isNotEmpty)
                const SizedBox(height: 16),

              // معلومات المشتري
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          request['userName'] ?? 'مستخدم غير معروف',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          dateFormat.format(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (request['userPhone'] != null &&
                        request['userPhone'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _callCustomer(request['userPhone']),
                        child: Row(
                          children: [
                            Icon(Icons.phone, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Text(
                              request['userPhone'],
                              style: TextStyle(
                                color: Colors.green[700],
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // أزرار الإجراءات للطلبات المعلقة
              if ((request['status'] ?? 'pending').toLowerCase() ==
                  'pending') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveRequest(request['id']),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('قبول'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectRequest(request['id']),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('رفض'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(
      String status, bool isFrench, AppLocalizations localizations) {
    final statusText = _getTranslatedStatus(status, isFrench, localizations);
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _getTranslatedStatus(
      String status, bool isFrench, AppLocalizations localizations) {
    if (isFrench) {
      switch (status.toLowerCase()) {
        case 'approved':
          return localizations.translate('status_approved');
        case 'rejected':
          return localizations.translate('status_rejected');
        case 'completed':
          return localizations.translate('status_completed');
        case 'pending':
        default:
          return localizations.translate('status_pending');
      }
    } else {
      switch (status.toLowerCase()) {
        case 'approved':
          return 'تم القبول';
        case 'rejected':
          return 'مرفوض';
        case 'completed':
          return 'مكتمل';
        case 'pending':
        default:
          return 'قيد الانتظار';
      }
    }
  }

  String _buildPriceRange(dynamic minPrice, dynamic maxPrice, bool isFrench,
      AppLocalizations localizations) {
    if (isFrench) {
      if (minPrice == null && maxPrice == null) {
        return localizations.translate('undefined_price');
      }
      final parts = <String>[];
      if (minPrice != null) {
        parts.add('${localizations.translate('from_price')} $minPrice');
      }
      if (maxPrice != null) {
        parts.add('${localizations.translate('to_price')} $maxPrice');
      }
      return '${parts.join(' ')} ${localizations.translate('currency_unit')}';
    } else {
      if (minPrice == null && maxPrice == null) {
        return 'السعر غير محدد';
      }
      final parts = <String>[];
      if (minPrice != null) {
        parts.add('من $minPrice');
      }
      if (maxPrice != null) {
        parts.add('إلى $maxPrice');
      }
      return '${parts.join(' ')} أوقية';
    }
  }

  String _buildAreaRange(dynamic minSpace, dynamic maxSpace, bool isFrench,
      AppLocalizations localizations) {
    if (isFrench) {
      if (minSpace == null && maxSpace == null) {
        return localizations.translate('undefined_area');
      }
      final parts = <String>[];
      if (minSpace != null) {
        parts.add('${localizations.translate('from_price')} $minSpace');
      }
      if (maxSpace != null) {
        parts.add('${localizations.translate('to_price')} $maxSpace');
      }
      return '${parts.join(' ')} ${localizations.translate('area_unit')}';
    } else {
      if (minSpace == null && maxSpace == null) {
        return 'المساحة غير محددة';
      }
      final parts = <String>[];
      if (minSpace != null) {
        parts.add('من $minSpace');
      }
      if (maxSpace != null) {
        parts.add('إلى $maxSpace');
      }
      return '${parts.join(' ')} م²';
    }
  }

  String _getArabicPropertyType(String? englishType) {
    if (englishType == null || englishType.isEmpty) return 'غير محدد';

    final Map<String, String> propertyTypes = {
      'house': 'منزل',
      'villa': 'فيلا',
      'apartment': 'شقة',
      'store': 'محل تجاري',
      'shop': 'محل تجاري',
      'commercial': 'تجاري',
      'hall': 'قاعة',
      'studio': 'ستوديو',
      'land': 'أرض',
      'building': 'عمارة',
      'farm': 'مزرعة',
      'duplex': 'دوبلكس',
      'chalet': 'شاليه',
      'hotel': 'فندق',
      'resort': 'منتجع',
      'office': 'مكتب',
      'warehouse': 'مستودع',
      'residential': 'سكني',
      'other': 'أخرى'
    };

    return propertyTypes[englishType.toLowerCase()] ?? englishType;
  }

  String _getArabicCity(String? englishCity) {
    final Map<String, String> cities = {
      'nouakchott': 'انواكشوط',
      'nouadhibou': 'انواذيبو',
    };

    if (englishCity == null) return 'غير محدد';
    return cities[englishCity.toLowerCase()] ?? englishCity;
  }

  String _getArabicDistrict(String englishDistrict) {
    final Map<String, String> districts = {
      'tevragh_zeina': 'تفرغ زينة',
      'arafat': 'عرفات',
      'madrid': 'مدريد',
      'dar_naim': 'دار النعيم',
      'toujounine': 'توجنين',
    };

    return districts[englishDistrict.toLowerCase()] ?? englishDistrict;
  }

  Future<void> _callCustomer(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكن الاتصال بالرقم: $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveRequest(String requestId) async {
    if (!mounted) return;

    // عرض رسالة توضيحية للمستخدم أن القبول سيكون محلياً فقط
    bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تنبيه: تغيير محلي'),
        content: const Text(
          'سيتم قبول هذا الطلب محلياً فقط ولن يتم تحديث قاعدة البيانات. '
          'ستظهر التغييرات في التطبيق حتى بعد إعادة تشغيله.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('قبول محلياً'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    try {
      setState(() => _isLoading = true);

      // تحديث الواجهة المحلية فقط دون الاتصال بـ Firestore
      setState(() {
        int index = _generalPropertyRequests
            .indexWhere((req) => req['id'] == requestId);
        if (index != -1) {
          // تحديث البيانات محلياً
          final actionDate = Timestamp.now();
          _generalPropertyRequests[index]['status'] = 'approved';
          _generalPropertyRequests[index]['actionDate'] = actionDate;
          _generalPropertyRequests[index]['localChange'] = true;

          // حفظ التغييرات في SharedPreferences
          _savedRequestStates[requestId] = {
            'status': 'approved',
            'actionDate': actionDate.millisecondsSinceEpoch,
            'rejectionReason': null
          };
          _saveRequestStates();
        } else {
          print('لم يتم العثور على الطلب برقم: $requestId');
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'تم قبول الطلب (محلياً - سيبقى محفوظاً حتى بعد إعادة تشغيل التطبيق)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء قبول الطلب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    if (!mounted) return;

    final TextEditingController reasonController = TextEditingController();
    bool? shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سبب الرفض (سيبقى محفوظاً محلياً)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'يرجى إدخال سبب رفض الطلب\n'
              '(سيتم حفظ الرفض محلياً وسيظهر حتى بعد إعادة تشغيل التطبيق)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'أدخل سبب الرفض هنا',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('رفض محلياً'),
          ),
        ],
      ),
    );

    if (shouldReject != true) return;

    try {
      setState(() => _isLoading = true);

      // تحديث الواجهة المحلية فقط بدون تحديث Firestore
      int index =
          _generalPropertyRequests.indexWhere((req) => req['id'] == requestId);
      if (index != -1) {
        setState(() {
          // تحديث البيانات محلياً
          final actionDate = Timestamp.now();
          final rejectionReason = reasonController.text.trim();

          _generalPropertyRequests[index]['status'] = 'rejected';
          _generalPropertyRequests[index]['rejectionReason'] = rejectionReason;
          _generalPropertyRequests[index]['actionDate'] = actionDate;
          _generalPropertyRequests[index]['localChange'] = true;

          // حفظ التغييرات في SharedPreferences
          _savedRequestStates[requestId] = {
            'status': 'rejected',
            'actionDate': actionDate.millisecondsSinceEpoch,
            'rejectionReason': rejectionReason
          };
          _saveRequestStates();
        });
      } else {
        print('لم يتم العثور على الطلب برقم: $requestId في القائمة المحلية.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'تم رفض الطلب (محلياً - سيبقى محفوظاً حتى بعد إعادة تشغيل التطبيق)'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء رفض الطلب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showGeneralRequestDetails(Map<String, dynamic> request, bool isFrench,
      AppLocalizations localizations) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final createdAt = request['createdAt'] != null
        ? (request['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // مؤشر السحب
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // عنوان التفاصيل
                  Center(
                    child: Text(
                      isFrench
                          ? localizations.translate('request_details')
                          : 'تفاصيل الطلب',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // تفاصيل نوع العقار والموقع
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.home,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              '${isFrench ? localizations.translate('property_type') : 'نوع العقار'}: ${_getArabicPropertyType(request['propertyType'] ?? '')}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (request['city'] != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                '${isFrench ? localizations.translate('location') : 'الموقع'}: ${_getArabicCity(request['city'])}${request['district'] != null ? ' - ${_getArabicDistrict(request['district'])}' : ''}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // تفاصيل السعر والمساحة
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (request['minPrice'] != null ||
                            request['maxPrice'] != null)
                          Row(
                            children: [
                              Icon(Icons.monetization_on,
                                  color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${isFrench ? localizations.translate('price') : 'السعر'}: ${_buildPriceRange(request['minPrice'], request['maxPrice'], isFrench, localizations)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (request['minSpace'] != null ||
                            request['maxSpace'] != null) ...[
                          if (request['minPrice'] != null ||
                              request['maxPrice'] != null)
                            const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.square_foot, color: Colors.brown[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${isFrench ? localizations.translate('area') : 'المساحة'}: ${_buildAreaRange(request['minSpace'], request['maxSpace'], isFrench, localizations)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // معلومات المشتري
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFrench
                              ? localizations.translate('buyer_information')
                              : 'معلومات المشتري',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              '${isFrench ? localizations.translate('name') : 'الاسم'}: ${request['userName'] ?? (isFrench ? localizations.translate('not_specified') : 'مستخدم غير معروف')}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (request['userPhone'] != null &&
                            request['userPhone'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _callCustomer(request['userPhone']),
                            child: Row(
                              children: [
                                Icon(Icons.phone, color: Colors.green[700]),
                                const SizedBox(width: 8),
                                Text(
                                  request['userPhone'],
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // حالة الطلب
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request['status'] ?? 'pending')
                          .withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(request['status'] ?? 'pending')
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(request['status'] ?? 'pending'),
                          color:
                              _getStatusColor(request['status'] ?? 'pending'),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isFrench ? localizations.translate('request_status') : 'حالة الطلب'}: ${_getLocalizedStatus(request['status'] ?? 'pending', isFrench, localizations)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                _getStatusColor(request['status'] ?? 'pending'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // أزرار الإجراءات إذا كان الطلب معلقاً
                  if ((request['status'] ?? 'pending').toLowerCase() ==
                      'pending') ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _approveRequest(request['id']);
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(isFrench
                                ? localizations.translate('accept_request')
                                : 'قبول الطلب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _rejectRequest(request['id']);
                            },
                            icon: const Icon(Icons.cancel_outlined),
                            label: Text(isFrench
                                ? localizations.translate('reject_request')
                                : 'رفض الطلب'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // إظهار سبب الرفض إذا كان الطلب مرفوضاً وله سبب
                  if (request['rejectionReason'] != null &&
                      request['rejectionReason'].toString().isNotEmpty &&
                      (request['status'] ?? '').toLowerCase() ==
                          'rejected') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${isFrench ? localizations.translate('rejection_reason') : 'سبب الرفض'}:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            request['rejectionReason'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'completed':
        return Icons.task_alt;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  Widget _buildSellerRequestsList(
      bool isFrench, AppLocalizations localizations) {
    if (_sellerPropertyRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              isFrench
                  ? localizations.translate('no_direct_requests')
                  : 'لا توجد طلبات حالية',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isFrench
                  ? localizations.translate('request_will_appear_here')
                  : 'ستظهر هنا طلبات المشترين على عقاراتك',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(isFrench
                  ? localizations.translate('refresh_data')
                  : 'تحديث البيانات'),
              onPressed: () {
                _loadSellerRequests();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(isFrench
                          ? localizations.translate('updating_data')
                          : 'جاري تحديث البيانات...')),
                );
              },
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _sellerPropertyRequests.length,
      itemBuilder: (context, index) {
        final request = _sellerPropertyRequests[index];
        return _buildSellerRequestCard(request, isFrench, localizations);
      },
    );
  }

  Widget _buildSellerRequestCard(Map<String, dynamic> request, bool isFrench,
      AppLocalizations localizations) {
    final status = request['status'] ?? 'pending';

    // تحديد لون الحالة
    Color statusColor;
    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    // التاريخ المنسق
    String formattedDate =
        isFrench ? localizations.translate('not_specified') : 'غير محدد';
    if (request['createdAt'] is Timestamp) {
      final date = (request['createdAt'] as Timestamp).toDate();
      formattedDate = DateFormat('dd/MM/yyyy - HH:mm').format(date);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () =>
            _showSellerRequestDetails(request, isFrench, localizations),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request['propertyTitle'] ??
                          (isFrench
                              ? localizations.translate('not_specified')
                              : 'غير محدد'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getLocalizedStatus(status, isFrench, localizations),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  '${isFrench ? localizations.translate('request_date') : 'تاريخ الطلب'}: $formattedDate'),
              Text(
                  '${isFrench ? localizations.translate('from') : 'من'}: ${request['userName'] ?? (isFrench ? localizations.translate('not_specified') : 'غير محدد')}'),
              Text(
                  '${isFrench ? localizations.translate('phone_number') : 'رقم الهاتف'}: ${request['userPhone'] ?? (isFrench ? localizations.translate('not_specified') : 'غير محدد')}'),
              if (request['message'] != null &&
                  request['message'].trim().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      '${isFrench ? localizations.translate('buyer_message') : 'رسالة المشتري'}:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(request['message'] ?? ''),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (status == 'pending') ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: Text(isFrench
                          ? localizations.translate('accept')
                          : 'قبول'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () =>
                          _updateRequestStatus(request['id'], 'accepted'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: Text(
                          isFrench ? localizations.translate('reject') : 'رفض'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () =>
                          _updateRequestStatus(request['id'], 'rejected'),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.phone),
                    onPressed: () {
                      _makePhoneCall(request['userPhone'] ?? '');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSellerRequestDetails(Map<String, dynamic> request, bool isFrench,
      AppLocalizations localizations) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final createdAt = request['createdAt'] != null
        ? (request['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final status = request['status'] ?? 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // مؤشر السحب
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // عنوان التفاصيل
                  Center(
                    child: Text(
                      isFrench
                          ? localizations.translate('request_details')
                          : 'تفاصيل الطلب',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // تفاصيل العقار
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.home,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              '${isFrench ? localizations.translate('property') : 'العقار'}: ${request['propertyTitle'] ?? (isFrench ? localizations.translate('not_specified') : 'غير محدد')}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.vpn_key, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            Text(
                              '${isFrench ? localizations.translate('property_id') : 'معرف العقار'}: ${request['propertyId'] ?? (isFrench ? localizations.translate('not_specified') : 'غير محدد')}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // معلومات المشتري
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFrench
                              ? localizations.translate('buyer_information')
                              : 'معلومات المشتري',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              '${isFrench ? localizations.translate('name') : 'الاسم'}: ${request['userName'] ?? (isFrench ? localizations.translate('not_specified') : 'غير محدد')}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (request['userPhone'] != null &&
                            request['userPhone'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _makePhoneCall(request['userPhone']),
                            child: Row(
                              children: [
                                Icon(Icons.phone, color: Colors.green[700]),
                                const SizedBox(width: 8),
                                Text(
                                  request['userPhone'],
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              '${isFrench ? localizations.translate('request_date') : 'تاريخ الطلب'}: ${dateFormat.format(createdAt)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // رسالة المشتري
                  if (request['message'] != null &&
                      request['message'].toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${isFrench ? localizations.translate('buyer_message') : 'رسالة المشتري'}:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            request['message'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // حالة الطلب
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(status).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isFrench ? localizations.translate('request_status') : 'حالة الطلب'}: ${_getLocalizedStatus(status, isFrench, localizations)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // أزرار الإجراءات إذا كان الطلب معلقاً
                  if (status == 'pending') ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateRequestStatus(request['id'], 'accepted');
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(isFrench
                                ? localizations.translate('accept_request')
                                : 'قبول الطلب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showRejectReasonDialog(request['id']);
                            },
                            icon: const Icon(Icons.cancel_outlined),
                            label: Text(isFrench
                                ? localizations.translate('reject_request')
                                : 'رفض الطلب'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // إظهار سبب الرفض إذا كان الطلب مرفوضاً وله سبب
                  if (request['rejectionReason'] != null &&
                      request['rejectionReason'].toString().isNotEmpty &&
                      (request['status'] ?? '').toLowerCase() ==
                          'rejected') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${isFrench ? localizations.translate('rejection_reason') : 'سبب الرفض'}:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            request['rejectionReason'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // عرض مربع حوار لإدخال سبب الرفض
  void _showRejectReasonDialog(String requestId) {
    final localizations = AppLocalizations.of(context);
    final isFrench = localizations.isFrench();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFrench
            ? localizations.translate('rejection_reason')
            : 'سبب الرفض'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isFrench
                ? localizations.translate('enter_rejection_reason')
                : 'يرجى إدخال سبب رفض الطلب'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isFrench
                    ? localizations.translate('rejection_hint')
                    : 'أدخل سبب الرفض هنا',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isFrench ? localizations.translate('cancel') : 'إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateRequestStatusWithReason(
                  requestId, 'rejected', reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isFrench ? localizations.translate('reject') : 'رفض'),
          ),
        ],
      ),
    );
  }

  // دالة لتحديث حالة الطلب مع سبب الرفض
  Future<void> _updateRequestStatusWithReason(
      String requestId, String status, String reason) async {
    final localizations = AppLocalizations.of(context);
    final isFrench = localizations.isFrench();

    try {
      setState(() {
        _isLoading = true;
      });

      // تحديث الواجهة المحلية فقط دون الاتصال بـ Firestore
      setState(() {
        int index =
            _sellerPropertyRequests.indexWhere((req) => req['id'] == requestId);
        if (index != -1) {
          _sellerPropertyRequests[index]['status'] = status;
          _sellerPropertyRequests[index]['rejectionReason'] = reason;
        }
      });

      // لا نقوم بتحديث Firestore إذا كانت الحالة هي "rejected"
      if (status != 'rejected') {
        // تحديث Firestore للحالات الأخرى فقط
        Map<String, dynamic> updateData = {
          'status': status,
          'actionDate': FieldValue.serverTimestamp(),
        };

        if (reason.isNotEmpty) {
          updateData['rejectionReason'] = reason;
        }

        await FirebaseFirestore.instance
            .collection('sellerRequests')
            .doc(requestId)
            .update(updateData);

        // تحديث الطلب في مجموعة propertyPurchases أيضاً إذا وجد
        try {
          // البحث عن الطلب في propertyPurchases
          final purchases = await FirebaseFirestore.instance
              .collection('propertyPurchases')
              .where('propertyId',
                  isEqualTo: _sellerPropertyRequests.firstWhere(
                      (req) => req['id'] == requestId)['propertyId'])
              .get();

          if (purchases.docs.isNotEmpty) {
            for (var doc in purchases.docs) {
              await FirebaseFirestore.instance
                  .collection('propertyPurchases')
                  .doc(doc.id)
                  .update(updateData);

              print(
                  'تم تحديث حالة الطلب في propertyPurchases أيضاً: ${doc.id}');
            }
          }
        } catch (e) {
          print('خطأ في تحديث حالة الطلب في propertyPurchases: $e');
        }
      } else {
        // في حالة الرفض، نقوم بطباعة رسالة توضيحية فقط
        print(
            'تم رفض الطلب محلياً فقط (رقم الطلب: $requestId) - سبب الرفض: $reason');
      }

      // عرض رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${isFrench ? localizations.translate('request_updated_to') : 'تم تحديث حالة الطلب إلى'} ${_getLocalizedStatus(status, isFrench, localizations)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('خطأ في تحديث حالة الطلب: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${isFrench ? localizations.translate('error_updating_request') : 'حدث خطأ'}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة لتحديث حالة الطلب
  Future<void> _updateRequestStatus(String requestId, String status) async {
    if (status == 'rejected') {
      _showRejectReasonDialog(requestId);
      return;
    }

    await _updateRequestStatusWithReason(requestId, status, '');
  }

  // دالة لإجراء مكالمة هاتفية
  void _makePhoneCall(String phoneNumber) async {
    final localizations = AppLocalizations.of(context);
    final isFrench = localizations.isFrench();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFrench
              ? localizations.translate('phone_not_available')
              : 'رقم الهاتف غير متوفر'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      print('خطأ في إجراء المكالمة: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFrench
              ? localizations.translate('cannot_make_call')
              : 'لا يمكن إجراء المكالمة'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ترجمة حالة الطلب
  String _getLocalizedStatus(
      String status, bool isFrench, AppLocalizations localizations) {
    if (isFrench) {
      switch (status) {
        case 'pending':
          return localizations.translate('pending_status');
        case 'accepted':
          return localizations.translate('accepted_status');
        case 'rejected':
          return localizations.translate('rejected_status');
        case 'cancelled':
          return localizations.translate('cancelled_status');
        default:
          return localizations.translate('undefined_status');
      }
    } else {
      switch (status) {
        case 'pending':
          return 'قيد الانتظار';
        case 'accepted':
          return 'مقبول';
        case 'rejected':
          return 'مرفوض';
        case 'cancelled':
          return 'ملغي';
        default:
          return 'غير محدد';
      }
    }
  }
}
