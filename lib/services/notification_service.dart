import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // إعداد القناة للإشعارات المحلية
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'إشعارات مهمة',
    description: 'هذه القناة للإشعارات المهمة',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // طلب إذن الإشعارات
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('تم منح إذن الإشعارات: ${settings.authorizationStatus}');

    // إعداد الإشعارات المحلية
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(initSettings);

    // معالجة الإشعارات في المقدمة
    _setupForegroundNotificationHandling();

    // معالجة فتح الإشعارات عندما يكون التطبيق مغلقاً
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // التحقق من الإشعارات التي أطلقت التطبيق
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // تسجيل توكن FCM للمستخدم
    await _registerFCMToken();
  }

  void _setupForegroundNotificationHandling() {
    // معالجة الإشعارات في الواجهة الأمامية
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('تم استلام إشعار في المقدمة: ${message.notification?.title}');

      // استخراج بيانات الإشعار
      final notification = message.notification;
      final data = message.data;

      // عرض الإشعار المحلي
      if (notification != null) {
        _showLocalNotification(
          notification.hashCode,
          notification.title ?? 'إشعار جديد',
          notification.body ?? '',
          data,
        );
      }

      // معالجة إشعارات محددة
      if (data.containsKey('action')) {
        final action = data['action'];

        switch (action) {
          case 'seller_approval':
            print('تم استلام إشعار موافقة بائع');
            _handleSellerApproval(data);
            break;

          case 'seller_rejection':
            print('تم استلام إشعار رفض بائع');
            _handleSellerRejection(data);
            break;

          // يمكن إضافة المزيد من الإجراءات هنا
        }
      }
    });
  }

  void _handleSellerApproval(Map<String, dynamic> data) {
    print('تم قبول طلبك كبائع معتمد: $data');

    // تخزين حالة الموافقة لتحديث واجهة المستخدم عند العودة
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('is_seller_approved', true);
      prefs.setInt('seller_approval_time',
          data['time'] ?? DateTime.now().millisecondsSinceEpoch);
    });

    // عرض إشعار محلي حتى لو كان التطبيق مفتوحاً
    showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'تهانينا! تم قبول طلبك كبائع',
      body: 'يمكنك الآن إضافة عقارات للبيع ونشرها على منصة عقاري',
      payload: 'seller_approval',
    );
  }

  void _handleSellerRejection(Map<String, dynamic> data) {
    print('تم رفض طلبك للتسجيل كبائع: $data');

    final String reason = data['reason'] ?? '';

    // تخزين حالة الرفض لتحديث واجهة المستخدم عند العودة
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('is_seller_rejected', true);
      prefs.setString('seller_rejection_reason', reason);
      prefs.setInt('seller_rejection_time',
          data['time'] ?? DateTime.now().millisecondsSinceEpoch);
    });

    // عرض إشعار محلي حتى لو كان التطبيق مفتوحاً
    showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'تم رفض طلب التسجيل كبائع',
      body:
          'للأسف، تم رفض طلبك للتسجيل كبائع${reason.isNotEmpty ? '. السبب: $reason' : ''}',
      payload: 'seller_rejection',
    );
  }

  void _handleMessage(RemoteMessage message) {
    // تنفيذ إجراءات بناءً على نوع الإشعار
    if (message.data['type'] == 'property_request_approved') {
      // انتقل إلى شاشة معينة أو اتخذ إجراءً محدداً
      print('تم قبول طلب العقار: ${message.data['requestId']}');
      // يمكنك استخدام خدمة التنقل للانتقال إلى الشاشة المناسبة
    }
  }

  // تسجيل توكن المستخدم
  Future<void> saveUserToken(String userId) async {
    // الحصول على توكن الجهاز
    String? token = await _messaging.getToken();

    if (token != null) {
      await FirebaseFirestore.instance
          .collection('user_tokens')
          .doc(userId)
          .set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': 'mobile'
      });

      print('تم حفظ توكن المستخدم: $token');

      // الاستماع لتغييرات التوكن
      _messaging.onTokenRefresh.listen((newToken) {
        saveUserToken(userId);
      });
    }
  }

  // إلغاء تسجيل توكن المستخدم عند تسجيل الخروج
  Future<void> removeUserToken(String userId) async {
    await FirebaseFirestore.instance
        .collection('user_tokens')
        .doc(userId)
        .delete();

    print('تم حذف توكن المستخدم');
  }

  // الاشتراك في موضوع
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  // إلغاء الاشتراك من موضوع
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // دالة عرض الإشعار المحلي
  void _showLocalNotification(
      int id, String title, String body, Map<String, dynamic> data) {
    _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: data['type'],
    );
  }

  // دالة لعرض إشعار محلي
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'aghari_notifications',
      'إشعارات عقاري',
      channelDescription: 'قناة إشعارات تطبيق عقاري',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // إشعار عند إرسال طلب تسجيل كبائع
  Future<void> showSellerRequestNotification({
    String? userName,
    String? phone,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'تم إرسال طلب تسجيل كبائع',
      body: 'تم إرسال طلبك للتسجيل كبائع في منصة عقاري وسيتم مراجعته قريباً',
      payload: 'seller_request',
    );

    // حفظ معلومات الإشعار للإدارة
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_has_new_seller_request', true);
  }

  // إشعار للإدارة عند وجود طلب جديد
  Future<void> showAdminNewSellerRequestNotification() async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'طلب تسجيل بائع جديد',
      body: 'تم استلام طلب جديد للتسجيل كبائع. يرجى مراجعته في لوحة التحكم',
      payload: 'admin_seller_request',
    );
  }

  // تبسيط دالة checkForMissedNotifications
  Future<void> checkForMissedNotifications(String userId) async {
    try {
      print('جاري التحقق من وجود إشعارات فائتة للمستخدم: $userId');

      // 1. التحقق أولاً من وجود إشعارات في مجموعة notifications
      final notificationsQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // تعيين معرف فريد لكل إشعار بناءً على الوقت
      int baseId = DateTime.now().millisecondsSinceEpoch.remainder(10000);
      int counter = 0;

      for (var doc in notificationsQuery.docs) {
        try {
          final data = doc.data();
          final title = data['title'] ?? 'إشعار جديد';
          final body = data['body'] ?? '';
          final type = data['type'] ?? 'notification';

          // عرض الإشعار المحلي مع معرف فريد
          await showNotification(
            id: baseId + counter,
            title: title,
            body: body,
            payload: type,
          );

          counter++;

          // تحديث حالة الإشعار ليكون مقروءاً
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(doc.id)
              .update({'isRead': true});

          // معالجة خاصة لإشعار قبول البائع
          if (type == 'seller_approval') {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_seller_approved', true);
          }
        } catch (e) {
          print('خطأ في معالجة الإشعار ${doc.id}: $e');
        }
      }

      print('تم التحقق من ${counter} إشعار فائت');
    } catch (e) {
      print('خطأ في فحص الإشعارات الفائتة: $e');
    }
  }

  // إضافة دالة لتسجيل التوكن
  Future<void> _registerFCMToken() async {
    try {
      // التحقق من تسجيل الدخول
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null && userId.isNotEmpty) {
        print('تسجيل توكن FCM للمستخدم: $userId');

        // الحصول على التوكن
        final token = await _messaging.getToken();

        if (token != null) {
          // تحديث التوكن في وثيقة المستخدم
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({'fcmToken': token});

          print('تم تحديث توكن FCM: $token');

          // فحص الإشعارات الفائتة
          await checkForMissedNotifications(userId);
        }
      }
    } catch (e) {
      print('خطأ في تسجيل توكن FCM: $e');
    }
  }
}
