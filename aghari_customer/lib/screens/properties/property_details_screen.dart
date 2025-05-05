import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/property_model.dart';
import '../../providers/property_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/property_request_provider.dart';
import '../../providers/property_purchase_provider.dart';
import '../../models/property_purchase_model.dart';
import '../../localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({Key? key, required this.propertyId})
      : super(key: key);

  @override
  _PropertyDetailsScreenState createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  bool _isFavorite = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _purchaseSubmitted = false;
  bool _isAdmin = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // تنفيذ التحقق من المستخدم عند بدء الشاشة
    _checkUserStatus();

    // ⚠️ تعيين مستخدم اختبار مباشرة للإصلاح السريع
    // تم تعطيل هذا السطر لحل مشكلة ظهور "مستخدم اختبار" بدلاً من البيانات الحقيقية
    // _setTestUserDirectly();
  }

  // دالة فحص حالة المستخدم الحالي بطريقة أكثر أمانًا
  Future<void> _checkUserStatus() async {
    try {
      print('🔍 التحقق من حالة المستخدم...');
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // تحديث حالة المستخدم من التخزين المحلي
      await userProvider.checkUserSession();

      // التحقق من حالة تسجيل الدخول
      final currentUser = userProvider.currentUser;
      print(
          '👤 حالة المستخدم: ${currentUser != null ? 'مسجل دخول' : 'غير مسجل دخول'}');
      if (currentUser != null) {
        print('👤 معرف المستخدم: ${currentUser.id}');
        print('👤 اسم المستخدم: ${currentUser.name}');
        print('👤 هاتف المستخدم: ${currentUser.phone}');
      }

      // التحقق من صلاحيات المشرف - فقط للمستخدم المسجل دخول
      if (currentUser != null) {
        // يمكنك هنا إضافة منطق التحقق من صلاحيات المشرف
        // مثلاً من خلال قائمة معرفات المستخدمين المشرفين أو من خلال حقل في وثيقة المستخدم

        // للاختبار فقط - تعليق هذا في الإصدار النهائي
        setState(() {
          _isAdmin = true;
        });
      } else {
        setState(() {
          _isAdmin = false;
        });
      }
    } catch (e) {
      print('❌ خطأ في التحقق من حالة المستخدم: $e');
      setState(() {
        _isAdmin = false;
      });
    }
  }

  // دالة لتعيين مستخدم اختبار مباشرة
  Future<void> _setTestUserDirectly() async {
    try {
      print('🔧 محاولة تعيين مستخدم اختبار مباشرة في شاشة التفاصيل...');

      // الانتظار لضمان تحميل البيانات
      await Future.delayed(Duration(milliseconds: 500));

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // استخدام دالة setTestUser للتعيين المباشر
      await userProvider.setTestUser();

      // تعيين المستخدم في جميع المزودين
      userProvider.setUserIdInProviders(context);

      // تحديث الواجهة
      if (mounted) {
        setState(() {
          print('✅ تم تحديث الواجهة بعد تعيين مستخدم الاختبار');
        });
      }
    } catch (e) {
      print('❌ خطأ في تعيين مستخدم الاختبار: $e');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Consumer2<PropertyProvider, PropertyRequestProvider>(
      builder: (context, propertyProvider, requestProvider, child) {
        final property = propertyProvider.getPropertyById(widget.propertyId);
        final userProvider = Provider.of<UserProvider>(context);

        if (property == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                floating: false,
                pinned: true,
                actions: [
                  if (userProvider.currentUser != null)
                    StatefulBuilder(builder: (context, setState) {
                      return IconButton(
                        icon: Icon(
                          propertyProvider.isFavorite(property.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.white,
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                setState(() {
                                  _isSubmitting = true;
                                });

                                try {
                                  print(
                                      '👤 المستخدم الحالي: ${userProvider.currentUser!.id}');

                                  // التحقق من وجود معرف المستخدم في PropertyProvider
                                  if (propertyProvider.currentUserId == null ||
                                      propertyProvider.currentUserId !=
                                          userProvider.currentUser!.id) {
                                    print(
                                        '⚠️ عدم تطابق المستخدم، إعادة تعيين...');
                                    propertyProvider.currentUserId =
                                        userProvider.currentUser!.id;
                                  }

                                  // تبديل حالة المفضلة
                                  await propertyProvider
                                      .toggleFavorite(property.id);
                                } catch (e) {
                                  print('❌ خطأ في تبديل المفضلة: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('حدث خطأ: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isSubmitting = false;
                                    });
                                  }
                                }
                              },
                      );
                    }),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: PageView.builder(
                    itemCount: property.images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        property.images[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            property.address,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${property.price.toStringAsFixed(0)} ${localizations.translate('currency')}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Chip(
                            label: Text(
                              PropertyModel.getLocalizedStatus(
                                  property.status, localizations.translate),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor:
                                property.status == PropertyStatus.forSale
                                    ? Colors.blue
                                    : Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildFeature(
                                  Icons.king_bed,
                                  '${property.bedrooms}',
                                  localizations.translate('rooms')),
                              _buildFeature(
                                  Icons.bathtub,
                                  '${property.bathrooms}',
                                  localizations.translate('bathrooms')),
                              _buildFeature(
                                  Icons.square_foot,
                                  '${property.area}',
                                  localizations.translate('area_unit')),
                              _buildFeature(
                                  Icons.garage,
                                  '${property.parkingSpaces}',
                                  localizations.translate('parking_spaces')),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localizations.translate('property_details'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        property.description,
                        style: const TextStyle(
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localizations.translate('property_features'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (property.hasPool)
                            _buildFeatureChip(localizations.translate('pool')),
                          if (property.hasGarden)
                            _buildFeatureChip(
                                localizations.translate('garden')),
                          ...property.features.entries
                              .where((entry) => entry.value)
                              .map((entry) => _buildFeatureChip(
                                  localizations.translate(entry.key))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.translate('owner_info'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.black,
                                  child: Icon(Icons.person),
                                ),
                                title: Text(property.ownerName),
                                subtitle: Text(property.ownerPhone),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.phone),
                                      onPressed: () async {
                                        final url = Uri.parse(
                                            'tel:${property.ownerPhone}');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.message),
                                      onPressed: () async {
                                        final url = Uri.parse(
                                            'sms:${property.ownerPhone}');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // إضافة قسم حالة المستخدم
                      const SizedBox(height: 24),
                      if (userProvider.currentUser == null)
                        _buildUserStatusCard(userProvider)
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // زر تقديم طلب الشراء
                  if (!_purchaseSubmitted)
                    _buildPurchaseButton()
                  else
                    _buildSuccessMessage(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeature(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[700]),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  // تقديم طلب شراء
  Future<void> _submitPurchaseRequest() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🚀 بدء عملية تقديم طلب شراء...');

      // جلب بيانات العقار
      final property = Provider.of<PropertyProvider>(context, listen: false)
          .getPropertyById(widget.propertyId);

      if (property == null) {
        throw 'لم يتم العثور على العقار';
      }

      print('🏠 جلب عقار للشراء: ${property.id}');

      // استخدام مزود طلبات الشراء مباشرة
      final purchaseProvider =
          Provider.of<PropertyPurchaseProvider>(context, listen: false);

      // تأكد من تعيين معرف المستخدم
      final userId = await SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('userId'));

      if (userId == null || userId.isEmpty) {
        throw 'المستخدم غير مسجل دخول. الرجاء تسجيل الدخول أولاً.';
      }

      // تعيين معرف المستخدم في مزود طلبات الشراء
      purchaseProvider.setUserId(userId);
      print('👤 تم تعيين معرف المستخدم: $userId');

      // إنشاء طلب الشراء
      final purchaseId = await purchaseProvider.createPurchase(
        property.id!,
        notes: _notesController.text.trim(),
      );

      print('✅ تم إنشاء طلب الشراء بنجاح! المعرف: $purchaseId');

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _purchaseSubmitted = true;
        });

        // عرض رسالة نجاح
        _showSuccessDialog();
      }
    } catch (e) {
      print('❌ خطأ في تقديم طلب الشراء: $e');

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // عرض رسالة الخطأ للمستخدم
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // عرض رسالة طلب مكرر
  void _showDuplicateRequestDialog() {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.translate('duplicate_request_title')),
        content: Text(localizations.translate('duplicate_request_content')),
        actions: [
          TextButton(
            child: Text(localizations.translate('view_purchases')),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed('/purchases');
            },
          ),
          TextButton(
            child: Text(localizations.translate('ok')),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // عرض رسالة نجاح
  void _showSuccessDialog() {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.translate('purchase_success_title')),
        content: Text(localizations.translate('purchase_success_content')),
        actions: [
          TextButton(
            child: Text(localizations.translate('view_purchases')),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed('/purchases');
            },
          ),
          TextButton(
            child: Text(localizations.translate('ok')),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  // إنشاء طلب شراء محلي (للاحتياط)
  void _createLocalPurchase() {
    try {
      final property = Provider.of<PropertyProvider>(context, listen: false)
          .getPropertyById(widget.propertyId);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // تجديد حالة المستخدم
      userProvider.checkUserSession().then((_) {
        final currentUser = userProvider.currentUser;

        if (property != null && currentUser != null) {
          // طباعة بيانات العقار والمالك للتشخيص
          print('🏠 بيانات العقار - المعرف: ${property.id}');
          print('👤 معلومات المالك - المعرف: ${property.ownerId}');
          print('👤 معلومات المالك - الاسم: ${property.ownerName}');
          print('👤 معلومات المالك - الهاتف: ${property.ownerPhone}');

          // التأكد من وجود معرف المالك
          if (property.ownerId.isEmpty) {
            print(
                '⚠️ تحذير: معرف المالك غير متوفر! استخدام معرف المالك الافتراضي.');
          }

          // التأكد من وجود رقم هاتف المالك
          if (property.ownerPhone.isEmpty) {
            print(
                '⚠️ تحذير: رقم هاتف المالك غير متوفر! استخدام رقم هاتف افتراضي.');
          }

          final localPurchase = PropertyPurchaseModel(
            id: 'local_${DateTime.now().millisecondsSinceEpoch}',
            userId: currentUser.id,
            userName: currentUser.name,
            userPhone: currentUser.phone,
            propertyId: property.id!,
            propertyTitle: property.title,
            propertyPrice: property.price,
            ownerName: property.ownerName,
            ownerPhone: property.ownerPhone,
            purchaseDate: DateTime.now(),
            status: 'pending',
            notes: _notesController.text.trim(),
            propertyType: property.type.toString().split('.').last,
            propertyStatus: property.status.toString().split('.').last,
            city: property.address.split(',').first,
            district: property.address.split(',').length > 1
                ? property.address.split(',')[1]
                : '',
            propertyArea: property.area,
            bedrooms: property.bedrooms,
            bathrooms: property.bathrooms,
            ownerId: property.ownerId.isNotEmpty
                ? property.ownerId
                : 'unknown_owner',
          );

          // طباعة البيانات النهائية للنموذج للتشخيص
          print('📝 بيانات طلب الشراء:');
          print('- معرف المستخدم: ${localPurchase.userId}');
          print('- اسم المستخدم: ${localPurchase.userName}');
          print('- هاتف المستخدم: ${localPurchase.userPhone}');
          print('- معرف العقار: ${localPurchase.propertyId}');
          print('- عنوان العقار: ${localPurchase.propertyTitle}');
          print('- معرف المالك: ${localPurchase.ownerId}');
          print('- اسم المالك: ${localPurchase.ownerName}');
          print('- هاتف المالك: ${localPurchase.ownerPhone}');

          // إضافة الطلب المحلي
          final purchaseProvider =
              Provider.of<PropertyPurchaseProvider>(context, listen: false);

          purchaseProvider.setUserId(currentUser.id);
          purchaseProvider.addLocalPurchase(localPurchase);
          purchaseProvider.forceLocalStorage();

          print('✅ تم إنشاء طلب شراء محلي بديل بنجاح');

          setState(() {
            _purchaseSubmitted = true;
          });

          // عرض رسالة نجاح
          _showSuccessDialog();
        } else {
          throw 'لا يمكن إنشاء طلب بدون تسجيل دخول أو بدون عقار صالح';
        }
      });
    } catch (e) {
      print('❌ فشل في إنشاء طلب محلي: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تقديم الطلب. حاول مرة أخرى.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPurchaseButton() {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          print('🖱️ الضغط على زر تقديم طلب الشراء');

          // التحقق من حالة المستخدم قبل إظهار مربع حوار التأكيد
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);

          // التحقق المباشر من المستخدم الحالي
          if (userProvider.currentUser == null) {
            print(
                '⚠️ المستخدم غير موجود! توجيه المستخدم إلى شاشة تسجيل الدخول...');

            // بدلاً من تعيين مستخدم اختبار، توجيه المستخدم إلى شاشة تسجيل الدخول
            _showLoginDialog();
          } else {
            print(
                '✅ المستخدم موجود: ${userProvider.currentUser!.id}. عرض مربع حوار تأكيد الشراء.');
            _showPurchaseConfirmDialog();
          }
        },
        icon: const Icon(Icons.shopping_cart),
        label: Text(AppLocalizations.of(context).translate('buy_property')),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.green,
        ),
      ),
    );
  }

  // عرض مربع حوار تأكيد الشراء
  void _showPurchaseConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('confirm_purchase')),
        content: Text(
            AppLocalizations.of(context).translate('confirm_purchase_message')),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context).translate('cancel')),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text(AppLocalizations.of(context).translate('confirm')),
            onPressed: () {
              Navigator.of(ctx).pop();
              _submitPurchaseRequest();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pushNamed('/purchases');
        },
        icon: const Icon(Icons.shopping_cart),
        label: Text(AppLocalizations.of(context).translate('view_purchases')),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.green,
        ),
      ),
    );
  }

  // بطاقة حالة المستخدم
  Widget _buildUserStatusCard(UserProvider userProvider) {
    return Card(
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'حالة المستخدم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('المستخدم غير مسجل الدخول حالياً!'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('تسجيل الدخول'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _forceSetCurrentUser();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('إصلاح تسجيل الدخول'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // دالة إجبار تعيين المستخدم الحالي (للإصلاح فقط)
  Future<void> _forceSetCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      print('💾 معرف المستخدم في التخزين المحلي: ${userId ?? 'غير موجود'}');

      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'لم يتم العثور على معرف المستخدم! الرجاء تسجيل الدخول أولاً.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // إنشاء مستخدم مباشرة بالمعرف
      print('⚡️ إنشاء مستخدم مؤقت مباشرة بالمعرف: $userId');

      final user = UserModel(
        id: userId,
        name: 'المستخدم الحالي',
        phone: '050000000',
        password: '',
        imageUrl: '',
        isSeller: false,
      );

      // تعيين المستخدم مباشرة في مزود المستخدم
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateLocalUser(user);

      // محاولة تحميل بيانات المستخدم بعد تعيينه
      try {
        // الحصول على بيانات المستخدم من Firestore مباشرة
        final firestore = FirebaseFirestore.instance;
        final doc = await firestore.collection('users').doc(userId).get();

        if (doc.exists) {
          print('✅ تم العثور على وثيقة المستخدم في Firestore');
          final userData = doc.data()!;

          // تحديث المستخدم بالبيانات الفعلية
          final updatedUser = UserModel(
            id: userId,
            name: userData['name'] ?? 'المستخدم',
            phone: userData['phone'] ?? '050000000',
            password: '', // لا داعي لتخزين كلمة المرور
            imageUrl: userData['imageUrl'] ?? '',
            isSeller: userData['isSeller'] ?? false,
          );

          await userProvider.updateLocalUser(updatedUser);
          print('✅ تم تحديث بيانات المستخدم من Firestore');
        } else {
          print(
              '⚠️ لم يتم العثور على وثيقة المستخدم في Firestore، لكن تم تعيين مستخدم مؤقت');
        }
      } catch (firestoreError) {
        print('⚠️ خطأ في قراءة بيانات المستخدم من Firestore: $firestoreError');
        print('⚠️ سنستمر بالمستخدم المؤقت');
      }

      // تعيين معرف المستخدم في جميع المزودين
      userProvider.setUserIdInProviders(context);

      // طباعة قيمة المستخدم الحالي الآن
      print(
          '👤 المستخدم الحالي الآن: ${userProvider.currentUser != null ? 'موجود' : 'غير موجود'}');
      if (userProvider.currentUser != null) {
        print('   - المعرف: ${userProvider.currentUser!.id}');
        print('   - الاسم: ${userProvider.currentUser!.name}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'تم تعيين المستخدم بنجاح! ${userProvider.currentUser?.name ?? 'المستخدم'}'),
          backgroundColor: Colors.green,
        ),
      );

      // إعادة تحميل الصفحة
      setState(() {});
    } catch (e) {
      print('❌ خطأ في إجبار تعيين المستخدم: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // إضافة مربع حوار طلب تسجيل الدخول
  void _showLoginDialog() {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.translate('login_required')),
        content: Text(localizations.translate('login_required_to_purchase')),
        actions: [
          TextButton(
            child: Text(localizations.translate('cancel')),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text(localizations.translate('login')),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
