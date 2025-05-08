import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/seller_request_service.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_service.dart';
import '../../localization/app_localizations.dart';

class BecomeSellerScreen extends StatefulWidget {
  const BecomeSellerScreen({Key? key}) : super(key: key);

  @override
  State<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends State<BecomeSellerScreen> {
  final SellerRequestService _sellerRequestService = SellerRequestService();

  File? _idCardImage;
  File? _licenseImage;

  bool _isSubmitting = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, int imageType) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        switch (imageType) {
          case 1:
            _idCardImage = File(pickedFile.path);
            break;
          case 2:
            _licenseImage = File(pickedFile.path);
            break;
        }
      });
    }
  }

  Future<void> _selectImageSource(int imageType) async {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title:
                    Text(AppLocalizations.of(context).translate('take_photo')),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera, imageType);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context)
                    .translate('choose_from_gallery')),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery, imageType);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitRequest() async {
    // التحقق من وجود الصور المطلوبة
    if (_idCardImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context).translate('attach_id_image'))),
      );
      return;
    }

    if (_licenseImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('attach_license_image'))),
      );
      return;
    }

    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context).translate('login_required')),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // إضافة طباعة للتتبع
      print('بدء عملية رفع الصور...');

      // تقسيم العملية إلى خطوات منفصلة لتسهيل اكتشاف المشكلة

      // رفع صورة الهوية
      print('جاري رفع صورة بطاقة الهوية...');
      final idCardSuccess = await _sellerRequestService.uploadImage(
          _idCardImage!,
          'idcards/${user.id}_${DateTime.now().millisecondsSinceEpoch}');
      if (!idCardSuccess) {
        throw Exception(
            AppLocalizations.of(context).translate('id_upload_failed'));
      }

      // ثم رفع صورة الترخيص
      print('جاري رفع صورة شهادة التبريز...');
      final licenseSuccess = await _sellerRequestService.uploadImage(
          _licenseImage!,
          'licenses/${user.id}_${DateTime.now().millisecondsSinceEpoch}');
      if (!licenseSuccess) {
        throw Exception(
            AppLocalizations.of(context).translate('license_upload_failed'));
      }

      print('تم رفع جميع الصور بنجاح، جاري إرسال الطلب...');

      // إرسال الطلب بعد نجاح رفع الصور
      await _sellerRequestService.submitSellerRequest(
        userId: user.id,
        userName: user.name,
        userPhone: user.phone,
        idCardImage: _idCardImage!,
        licenseImage: _licenseImage!,
        notes: _notesController.text,
      );

      // إضافة إشعار محلي بعد نجاح إرسال الطلب
      await NotificationService().showSellerRequestNotification(
        userName: user.name,
        phone: user.phone,
      );

      // إضافة إشعار للإدارة
      await NotificationService().showAdminNewSellerRequestNotification();

      print('تم إرسال الطلب بنجاح!');

      // تحقق من وجود context قبل عرض رسالة النجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('request_sent_successfully')),
            backgroundColor: Colors.green,
          ),
        );

        // تأخير قصير قبل إغلاق الشاشة للتأكد من عرض الرسالة
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context);
      }
    } catch (e) {
      print('حدث خطأ أثناء إرسال الطلب: $e');

      // تحقق من وجود context قبل عرض رسالة الخطأ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).translate('error_occurred') +
                    ': $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // تحقق من وجود context قبل تحديث حالة الواجهة
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('become_certified_seller')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // معلومات الشاشة
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      localizations.translate('become_certified_seller'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      localizations
                          .translate('seller_registration_instructions'),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      localizations.translate('seller_required_documents'),
                      textAlign: TextAlign.start,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // صورة بطاقة الهوية
            _buildImageSelector(
              title: localizations.translate('id_card_image'),
              description: localizations.translate('attach_id_instructions'),
              image: _idCardImage,
              onTap: () => _selectImageSource(1),
            ),

            const SizedBox(height: 16),

            // صورة الترخيص
            _buildImageSelector(
              title: localizations.translate('license_image'),
              description:
                  localizations.translate('attach_license_instructions'),
              image: _licenseImage,
              onTap: () => _selectImageSource(2),
            ),

            const SizedBox(height: 24),

            // ملاحظات إضافية
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: localizations.translate('additional_notes'),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // زر التقديم
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelector({
    required String title,
    required String description,
    required File? image,
    required VoidCallback onTap,
  }) {
    final localizations = AppLocalizations.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              image == null
                  ? Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 36, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              localizations.translate('tap_to_select_image'),
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        image,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(AppLocalizations.of(context).translate('submit_request'),
                style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
