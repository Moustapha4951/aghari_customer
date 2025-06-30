import '../../models/property_model.dart';
import '../../services/seller_request_service.dart';
import '../../widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'account_settings_screen.dart';
import '../../models/property_request_model.dart';
import '../../services/property_request_service.dart';
import '../../screens/profile/request_property_screen.dart';
import '../../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../models/seller_request_model.dart';
import '../../screens/profile/become_seller_screen.dart';
import '../../localization/app_localizations.dart';
import '../../providers/language_provider.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // late UserProvider _userProvider; // Removed
  late PropertyRequestService _propertyRequestService;
  late SellerRequestService _sellerRequestService;

  @override
  void initState() {
    super.initState();
    // _userProvider = Provider.of<UserProvider>(context, listen: false); // Removed
    _propertyRequestService = PropertyRequestService();
    _sellerRequestService = SellerRequestService();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    // Get UserProvider with listening enabled
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    // The route guard in main.dart should prevent ProfileScreen from being built if user is null.
    // However, adding a null check here for safety during transition or unexpected states.
    if (user == null) {
      // This should ideally not be reached if the route guard is working.
      // It might indicate a brief moment where user becomes null while widget is still in tree.
      return Scaffold(
        appBar: AppBar(title: Text(localizations.translate('profile'))),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('profile')),
      ),
      body: SafeArea(
        // Removed user == null check here, body is now directly the SingleChildScrollView
        child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            localizations.translate('my_account'),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: user.imageUrl != null
                        ? NetworkImage(user.imageUrl!)
                        : null,
                    child: user.imageUrl == null
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.phone,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (user.isSeller)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Chip(
                          label:
                              Text(localizations.translate('verified_seller')),
                        backgroundColor: Colors.green[100],
                        labelStyle: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                        avatar: Icon(
                          Icons.verified,
                          color: Colors.green[800],
                          size: 18,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.settings),
                            title: Text(
                                localizations.translate('account_settings')),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                      const AccountSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ListTile(
                            leading: const Icon(Icons.language),
                            title: Text(localizations.translate('language')),
                            subtitle: Text(
                                Provider.of<LanguageProvider>(context)
                                    .getCurrentLanguageName()),
                            trailing: PopupMenuButton<String>(
                              onSelected: (String value) {
                                final languageProvider =
                                    Provider.of<LanguageProvider>(context,
                                        listen: false);
                                languageProvider.changeLanguage(value);
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'ar',
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        margin: const EdgeInsets.only(
                                            left: 8, right: 8),
                                        child: const Text('🇸🇦',
                                            style: TextStyle(fontSize: 20)),
                                      ),
                                      const Text('العربية'),
                                      const SizedBox(width: 8),
                                      if (Provider.of<LanguageProvider>(context)
                                          .isArabic())
                                        const Icon(Icons.check,
                                            size: 16, color: Colors.green),
                      ],
                    ),
                  ),
                                PopupMenuItem<String>(
                                  value: 'fr',
                                  child: Row(
                          children: [
                                      Container(
                                        width: 24,
                                        margin: const EdgeInsets.only(
                                            left: 8, right: 8),
                                        child: const Text('🇫🇷',
                                            style: TextStyle(fontSize: 20)),
                                      ),
                                      const Text('Français'),
                                      const SizedBox(width: 8),
                                      if (Provider.of<LanguageProvider>(context)
                                          .isFrench())
                                        const Icon(Icons.check,
                                            size: 16, color: Colors.green),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                            ListTile(
                            leading: const Icon(Icons.search),
                            title: Text(
                                localizations.translate('request_property')),
                              onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RequestPropertyScreen(),
                                ),
                              );
                            },
                          ),
                          if (!user.isSeller) const Divider(),
                          if (!user.isSeller)
                            FutureBuilder<bool>(
                              future: _sellerRequestService
                                  .hasActiveRequest(user.id),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const ListTile(
                                    leading: Icon(Icons.store),
                                    title: Text('...'),
                                    trailing: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  );
                                }

                                final hasActiveRequest = snapshot.data ?? false;

                                return ListTile(
                                  leading: const Icon(Icons.store),
                                  title: Text(hasActiveRequest
                                      ? localizations
                                          .translate('seller_request_pending')
                                      : localizations
                                          .translate('become_seller')),
                                  trailing: hasActiveRequest
                                      ? const Icon(Icons.pending,
                                          color: Colors.orange)
                                      : null,
                                  onTap: hasActiveRequest
                                      ? () => _showSellerRequestPendingDialog()
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const BecomeSellerScreen(),
                                            ),
                                          );
                                        },
                                );
                              },
                            ),
                          if (user.isSeller) const Divider(),
                          if (user.isSeller)
                            ListTile(
                              leading: const Icon(Icons.shopping_cart),
                              title: Text(
                                  localizations.translate('received_requests')),
                              onTap: () {
                                Navigator.pushNamed(
                                    context, '/received-requests');
                              },
                            ),
                          if (user.isSeller) const Divider(),
                          if (user.isSeller)
                            ListTile(
                              leading: const Icon(Icons.home),
                              title: Text(
                                  localizations.translate('my_properties')),
                              onTap: () {
                                Navigator.pushNamed(context, '/my-properties');
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    FutureBuilder<List<PropertyRequestModel>>(
                      future: _propertyRequestService
                          .getUserRequests(user.id), // Use user.id directly
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '${localizations.translate('error_loading')}: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return _buildPropertyRequestsCard([]);
                        } else {
                          return _buildPropertyRequestsCard(snapshot.data!);
                        }
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(localizations.translate('logout')),
                              content: Text(localizations
                                  .translate('logout_confirmation')),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child:
                                      Text(localizations.translate('cancel')),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child:
                                      Text(localizations.translate('logout')),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                          await userProvider.logout(); // Use userProvider from build context
                            if (mounted) {
                            // Navigation is handled by the Consumer in main.dart reacting to logout
                            // No explicit navigation needed here, or ensure it aligns with router logic
                            // For now, let UserProvider notify and Consumer handle redirection.
                            // Navigator.pushReplacementNamed(context, '/login'); // Commented out or removed
                          }
                        }
                      },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.red.shade300),
                          foregroundColor: Colors.red,
                        ),
                        child: Text(localizations.translate('logout')),
                      ),
                    ),
                ],
                ),
              ),
            ),
    );
  }

  void _showSellerRequestPendingDialog() {
    final localizations = AppLocalizations.of(context);

    showDialog(
          context: context,
          builder: (context) => AlertDialog(
        title: Text(localizations.translate('seller_request_pending_title')),
        content:
            Text(localizations.translate('seller_request_pending_message')),
            actions: [
              TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.translate('ok')),
              ),
            ],
          ),
    );
  }

  void _showPaymentDialog() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('payment_details')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.translate('payment_instructions')),
                const SizedBox(height: 16),
            _buildPaymentInfoRow(
                localizations.translate('payment_amount'), '2000 أوقية قديمة'),
            _buildPaymentInfoRow(
                localizations.translate('payment_number'), '26425407'),
            const SizedBox(height: 16),
            Text(localizations.translate('upload_receipt')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);

              if (image != null && mounted) {
                Navigator.of(context).pop();
                _showUploadingDialog();

                try {
                  final success = await _submitSellerRequest(File(image.path));

                  if (mounted) {
                    Navigator.of(context).pop(); // إغلاق مربع حوار التحميل
                    if (success) {
                      _showSuccessDialog();
                    } else {
                      _showErrorDialog();
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop(); // إغلاق مربع حوار التحميل
                    _showErrorDialog();
                  }
                }
              }
            },
            child: Text(localizations.translate('upload')),
          ),
        ],
      ),
    );
  }

  void _showUploadingDialog() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(localizations.translate('uploading')),
                              ],
                            ),
                    ),
    );
  }

  void _showSuccessDialog() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('success')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text(localizations.translate('seller_request_submitted')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.translate('ok')),
          ),
        ],
      ),
    ).then((_) {
      // بعد إغلاق النافذة، قم بتحديث واجهة الشاشة
                              if (mounted) {
        setState(() {});
      }
    });
  }

  void _showErrorDialog() {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('error')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(localizations.translate('seller_request_error')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.translate('ok')),
          ),
        ],
      ),
    );
  }

  // إضافة دالة مساعدة لعرض صفوف المعلومات
  Widget _buildPaymentInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // إضافة دالة لرفع الصورة وإرسال الطلب
  Future<bool> _submitSellerRequest(File receiptImage) async {
    try {
      print('بدء عملية رفع إيصال الدفع');
      final userId = _userProvider.currentUser!.id;

      // 1. أولاً، إنشاء المستند في Firestore بدون صورة
      print('إنشاء طلب جديد في Firestore');
      final docRef =
          await FirebaseFirestore.instance.collection('sellerRequests').add({
        'userId': userId,
        'userName': _userProvider.currentUser!.name,
        'userPhone': _userProvider.currentUser!.phone,
        'requestDate': FieldValue.serverTimestamp(),
        'status': 'pending',
        'amount': '2000 أوقية قديمة',
        'paymentNumber': '26425407',
        'hasReceipt': false, // مؤشر يدل على أن الصورة لم يتم رفعها بعد
      });

      final requestId = docRef.id;
      print('تم إنشاء الطلب بنجاح بمعرف: $requestId');

      // 2. محاولة رفع الصورة مع التعامل مع الأخطاء بشكل منفصل
      try {
        // استخدام مسار بسيط للصورة
        print('محاولة رفع الصورة...');
        final storage = FirebaseStorage.instance;
        final imagePath = 'receipts/$requestId.jpg';

        // تحديد خيارات الرفع لتجنب المشاكل
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'requestId': requestId,
            'userId': userId,
          },
        );

        // رفع الصورة مع معالجة أحداث التقدم
        final uploadTask = storage.ref().child(imagePath).putFile(
              receiptImage,
              metadata,
            );

        // مراقبة حالة الرفع
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          print(
              'حالة الرفع: ${snapshot.bytesTransferred}/${snapshot.totalBytes} بايت');
        });

        // انتظار اكتمال رفع الصورة
        print('انتظار اكتمال رفع الصورة...');
        final snapshot = await uploadTask;

        // الحصول على رابط الصورة
        print('تم رفع الصورة، جاري الحصول على الرابط...');
        final imageUrl = await snapshot.ref.getDownloadURL();
        print('تم الحصول على رابط الصورة: $imageUrl');

        // تحديث المستند بمعلومات الصورة
        print('تحديث المستند بمعلومات الصورة...');
        await docRef.update({
          'receiptImageUrl': imageUrl,
          'receiptImagePath': imagePath,
          'hasReceipt': true,
        });

        print('تم تحديث المستند برابط الصورة بنجاح');
        return true;
      } catch (uploadError) {
        // في حالة فشل رفع الصورة، نستمر مع الطلب ولكن نضيف ملاحظة
        print('خطأ أثناء رفع الصورة: $uploadError');
        await docRef.update({
          'uploadError': uploadError.toString(),
          'uploadErrorAt': FieldValue.serverTimestamp(),
          'hasReceipt': false,
        });

        // اعتبر العملية ناجحة حتى لو فشل رفع الصورة
        // سيقوم المستخدم بمحاولة إعادة رفع الصورة لاحقاً
        return true;
      }
    } catch (e) {
      print('خطأ عام في إرسال طلب التسجيل كبائع: $e');
      rethrow;
    }
  }

  Widget _buildPropertyRequestsCard(List<PropertyRequestModel> requests) {
    final localizations = AppLocalizations.of(context);

    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
            ),
      elevation: 4, // زيادة الظل للتأكيد على الكارت
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(
                      localizations.translate('property_requests'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${requests.length} ${localizations.translate('requests')}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RequestPropertyScreen(),
                      ),
                    ).then((_) {
                      // تحديث الصفحة عند العودة
                      setState(() {});
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(localizations.translate('new_request')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
          ),
        ],
      ),
          ),
          const Divider(height: 1),
          requests.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
        children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                Text(
                        localizations.translate('no_property_requests'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                Text(
                        localizations.translate('tap_to_request_property'),
                  style: TextStyle(
                    fontSize: 14,
                          color: Colors.grey[500],
                  ),
                        textAlign: TextAlign.center,
                ),
              ],
            ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
              return _buildRequestItem(requests[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(PropertyRequestModel request) {
    final localizations = AppLocalizations.of(context);

    // تحديد لون وحالة الطلب
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (request.status) {
      case RequestStatus.approved:
        statusColor = Colors.green;
        statusText = localizations.translate('status_approved');
        statusIcon = Icons.check_circle;
        break;
      case RequestStatus.rejected:
        statusColor = Colors.red;
        statusText = localizations.translate('status_rejected');
        statusIcon = Icons.cancel;
        break;
      case RequestStatus.completed:
        statusColor = Colors.blue;
        statusText = localizations.translate('status_completed');
        statusIcon = Icons.task_alt;
        break;
      case RequestStatus.pending:
      default:
        statusColor = Colors.orange;
        statusText = localizations.translate('status_pending');
        statusIcon = Icons.pending;
    }

    // تنسيق تاريخ الطلب
    final requestDate = DateFormat('dd/MM/yyyy').format(request.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showRequestDetailsDialog(request),
        borderRadius: BorderRadius.circular(12),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // العنوان وحالة الطلب
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        request.propertyStatus == PropertyStatus.forSale
                            ? Icons.sell
                            : Icons.home_work,
                color: AppTheme.primaryColor,
                size: 20,
              ),
                      const SizedBox(width: 8),
                  Text(
                    request.propertyType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                  Text(
                          statusText,
                    style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // الموقع والتفاصيل
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الموقع
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${request.city}, ${request.district}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 4),

                        // السعر
                        if (request.minPrice != null ||
                            request.maxPrice != null)
                          Row(
                            children: [
                              Icon(Icons.attach_money,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                      '${request.minPrice != null ? request.minPrice!.toStringAsFixed(0) + " - " : ""}'
                      '${request.maxPrice != null ? request.maxPrice!.toStringAsFixed(0) : ""} '
                      '${localizations.translate('currency')}',
                      style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                      ),
              ),
          ],
        ),

                        // المساحة
                        if (request.minSpace != null ||
                            request.maxSpace != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.square_foot,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${request.minSpace != null ? request.minSpace!.toStringAsFixed(0) + " - " : ""}'
                                    '${request.maxSpace != null ? request.maxSpace!.toStringAsFixed(0) : ""} '
                                    '${localizations.translate('area_unit')}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // تاريخ الطلب
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                requestDate,
              style: TextStyle(
                                  color: Colors.grey[700],
                  fontSize: 12,
              ),
                              ),
                            ],
            ),
          ),
        ],
                    ),
                  ),
                ],
              ),

              // أزرار الإجراءات
              if (request.status ==
                  RequestStatus.pending) // إظهار زر الحذف فقط للطلبات المعلقة
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showDeleteRequestDialog(request),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(localizations.translate('delete_request')),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // إضافة دالة لعرض حوار بكل تفاصيل الطلب
  void _showRequestDetailsDialog(PropertyRequestModel request) {
    final localizations = AppLocalizations.of(context);

    // تحديد لون وحالة الطلب
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (request.status) {
      case RequestStatus.approved:
        statusColor = Colors.green;
        statusText = localizations.translate('status_approved');
        statusIcon = Icons.check_circle;
        break;
      case RequestStatus.rejected:
        statusColor = Colors.red;
        statusText = localizations.translate('status_rejected');
        statusIcon = Icons.cancel;
        break;
      case RequestStatus.completed:
        statusColor = Colors.blue;
        statusText = localizations.translate('status_completed');
        statusIcon = Icons.task_alt;
        break;
      case RequestStatus.pending:
      default:
        statusColor = Colors.orange;
        statusText = localizations.translate('status_pending');
        statusIcon = Icons.pending;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الحوار مع حالة الطلب
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                    Row(
                      children: [
                        Icon(
                          request.propertyStatus == PropertyStatus.forSale
                              ? Icons.sell
                              : Icons.home_work,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                Text(
                    localizations.translate('request_details'),
                    style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    ),
                        ),
                      ],
                  ),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                              fontSize: 14,
                      ),
                          ),
                        ],
                    ),
                  ),
                ],
              ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // نوع العقار والغرض
                    _buildDetailCard(
                      title: localizations.translate('property_info'),
                      icon: Icons.home,
                      content: [
              _buildDetailItem(
                localizations.translate('property_type'),
                request.propertyType,
              ),
              _buildDetailItem(
                localizations.translate('property_status'),
                request.propertyStatus == PropertyStatus.forSale
                    ? localizations.translate('property_status_sale')
                    : localizations.translate('property_status_rent'),
              ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // الموقع
                    _buildDetailCard(
                      title: localizations.translate('location'),
                      icon: Icons.location_on,
                      content: [
              _buildDetailItem(
                          localizations.translate('city'),
                          request.city,
                        ),
                        _buildDetailItem(
                          localizations.translate('district'),
                          request.district,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // التفاصيل والميزات
                    _buildDetailCard(
                      title: localizations.translate('specifications'),
                      icon: Icons.info_outline,
                      content: [
              // معلومات السعر
                        if (request.minPrice != null ||
                            request.maxPrice != null)
                _buildDetailItem(
                  localizations.translate('price_range'),
                  '${request.minPrice != null ? request.minPrice!.toStringAsFixed(0) : "0"} - '
                  '${request.maxPrice != null ? request.maxPrice!.toStringAsFixed(0) : "∞"} '
                  '${localizations.translate('currency')}',
                ),

              // معلومات المساحة
                        if (request.minSpace != null ||
                            request.maxSpace != null)
                _buildDetailItem(
                  localizations.translate('area_range'),
                  '${request.minSpace != null ? request.minSpace!.toStringAsFixed(0) : "0"} - '
                  '${request.maxSpace != null ? request.maxSpace!.toStringAsFixed(0) : "∞"} '
                  '${localizations.translate('area_unit')}',
                ),

              // الغرف
              if (request.bedrooms != null)
                _buildDetailItem(
                  localizations.translate('bedrooms'),
                  '${request.bedrooms}',
                ),

              if (request.bathrooms != null)
                _buildDetailItem(
                  localizations.translate('bathrooms'),
                  '${request.bathrooms}',
                          ),
                      ],
                ),

                    const SizedBox(height: 16),

              // تفاصيل إضافية
              if (request.additionalDetails != null &&
                  request.additionalDetails!.isNotEmpty)
                      _buildDetailCard(
                        title: localizations.translate('additional_details'),
                        icon: Icons.description,
                        content: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                  request.additionalDetails!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                ),

                    const SizedBox(height: 16),

              // تاريخ الطلب
                    _buildDetailCard(
                      title: localizations.translate('request_dates'),
                      icon: Icons.calendar_today,
                      content: [
              _buildDetailItem(
                          localizations.translate('created_at'),
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(request.createdAt),
                        ),
                      ],
              ),

              const SizedBox(height: 16),

                    // الأزرار
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(localizations.translate('close')),
                          ),
                        ),
                        // زر الحذف للطلبات المعلقة فقط
                        if (request.status == RequestStatus.pending) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showDeleteRequestDialog(request);
                              },
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: Text(
                                  localizations.translate('delete_request')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.redAccent.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لإنشاء بطاقة تفاصيل
  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> content,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان البطاقة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

          // محتوى البطاقة
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
            ),
          ),
        ],
      ),
    );
  }

  // دالة مساعدة لعناصر التفاصيل
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteRequestDialog(PropertyRequestModel request) {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('delete_request_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            Text(
              localizations.translate('delete_request_message_permanent'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              _deleteRequest(request);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(localizations.translate('delete_permanently')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRequest(PropertyRequestModel request) async {
    final localizations = AppLocalizations.of(context);

    try {
      Navigator.of(context).pop(); // إغلاق مربع حوار التأكيد

      // التحقق من أن معرف الطلب غير فارغ
      if (request.id == null || request.id!.isEmpty) {
        throw localizations.translate('invalid_request_id');
      }

      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(localizations.translate('deleting_request')),
            ],
          ),
        ),
      );

      // استدعاء خدمة حذف الطلب
      await _propertyRequestService.cancelRequest(request.id!);

      // إغلاق مؤشر التحميل
      if (mounted) Navigator.of(context).pop();

      // عرض رسالة نجاح العملية
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('request_deleted_permanently')),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: localizations.translate('ok'),
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );

      // تحديث واجهة المستخدم
      setState(() {});
    } catch (e) {
      // إغلاق مؤشر التحميل في حالة حدوث خطأ
      if (mounted) Navigator.of(context).pop();

      // عرض رسالة الخطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${localizations.translate('error_deleting_request')}: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
