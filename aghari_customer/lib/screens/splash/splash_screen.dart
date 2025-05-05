import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/property_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkForNotifications().then((_) {
      _checkUserAndNavigate();
    });
  }

  Future<void> _checkUserAndNavigate() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = await userProvider.checkUserSession();

      if (user) {
        // تحديث وقت آخر تسجيل دخول
        await userProvider.updateLastLoginTime();
        
        // فحص الإشعارات الفائتة
        final notificationService = NotificationService();
        await notificationService.checkForMissedNotifications(userProvider.currentUser!.id);
        
        // معالجة إشعارات قبول/رفض البائع
        final prefs = await SharedPreferences.getInstance();
        final isSellerApproved = prefs.getBool('is_seller_approved') ?? false;
        final isSellerRejected = prefs.getBool('is_seller_rejected') ?? false;
        
        // عرض رسالة قبول البائع إذا وجدت
        if (isSellerApproved) {
          final approvalTime = prefs.getInt('seller_approval_time') ?? 0;
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          // عرض الرسالة فقط إذا تم قبوله خلال الـ 24 ساعة الماضية
          if (currentTime - approvalTime < 24 * 60 * 60 * 1000) {
            // إزالة الحالة بعد عرضها
            await prefs.setBool('is_seller_approved', false);
            
            if (mounted) {
              _showCongratulationsDialog();
              return;
            }
          }
        }
        
        // عرض رسالة رفض البائع إذا وجدت
        if (isSellerRejected) {
          final rejectionTime = prefs.getInt('seller_rejection_time') ?? 0;
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          // عرض الرسالة فقط إذا تم رفضه خلال الـ 24 ساعة الماضية
          if (currentTime - rejectionTime < 24 * 60 * 60 * 1000) {
            final reason = prefs.getString('seller_rejection_reason') ?? '';
            // إزالة الحالة بعد عرضها
            await prefs.setBool('is_seller_rejected', false);

      if (mounted) {
              _showRejectionDialog(reason);
              return;
            }
          }
        }
        
        // التغيير هنا: عرض شاشة الترحيب دائماً بدلاً من التحقق
        if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
        
      } else {
        // المستخدم غير مسجل، توجيهه إلى شاشة تسجيل الدخول
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('خطأ في فحص حالة المستخدم: $e');
      // في حالة حدوث خطأ، توجيه المستخدم إلى شاشة تسجيل الدخول
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _checkForNotifications() async {
    try {
      // الحصول على معرف المستخدم
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;
      
      // التحقق من وجود إشعارات جديدة باستخدام خدمة الإشعارات
      final notificationService = NotificationService();
      await notificationService.checkForMissedNotifications(userId);
      
      // التحقق المباشر من وثيقة المستخدم للتأكد من وجود تحديثات حالة البائع
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        if (userData['hasNewSellerApproval'] == true) {
          // عرض إشعار محلي مباشرة
          await notificationService.showNotification(
            id: 54321,
            title: 'تهانينا! تم قبول طلبك كبائع',
            body: 'يمكنك الآن إضافة عقارات للبيع ونشرها على منصة عقاري',
            payload: 'seller_approval',
          );
          
          // تحديث الحالة المحلية
          await prefs.setBool('is_seller_approved', true);
          
          // إعادة تعيين الحقل في Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'hasNewSellerApproval': false});
        }
      }
    } catch (e) {
      print('خطأ في التحقق من الإشعارات: $e');
    }
  }

  // عرض رسالة تهنئة بعد قبول طلب البائع
  void _showCongratulationsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تهانينا! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'تم قبول طلبك للتسجيل كبائع معتمد في منصة عقاري!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'يمكنك الآن إضافة وإدارة العقارات وتلقي طلبات المشترين.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/main');
            },
            child: const Text('استمرار'),
          ),
        ],
      ),
    );
  }

  // عرض رسالة رفض طلب البائع
  void _showRejectionDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تم رفض طلبك'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'للأسف، تم رفض طلبك للتسجيل كبائع في منصة عقاري.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'السبب: $reason',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'يمكنك إعادة تقديم الطلب مع التأكد من استيفاء جميع الشروط.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/main');
            },
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // شعار التطبيق
            Image.asset(
              'assets/images/aghari.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 24),
            // دائرة التحميل
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
