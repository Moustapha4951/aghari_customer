import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/user_provider.dart';
import 'package:intl/intl.dart';
import '../../localization/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  String? _errorMessage;
  bool _isGuestMode = false; // Added state variable

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isGuestMode = false; // Reset guest mode
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id;

      if (userId == null) {
        setState(() {
          // _errorMessage = 'لا يمكن تحميل الإشعارات. الرجاء تسجيل الدخول أولاً.'; // Remove this line
          _isGuestMode = true; // Set guest mode
          _isLoading = false;
        });
        return;
      }

      print('جاري جلب الإشعارات للمستخدم: $userId');

      // جلب الإشعارات من قاعدة البيانات
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      print('تم العثور على ${snapshot.docs.length} إشعار');

      // تحويل البيانات وترتيبها
      final List<Map<String, dynamic>> notificationList = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // إضافة معرف الوثيقة والوقت المناسب
        final notification = {
          'id': doc.id,
          'title': data['title'] ?? 'إشعار جديد',
          'body': data['body'] ?? '',
          'isRead': data['isRead'] ?? false,
          'type': data['type'] ?? 'notification',
          'timestamp': data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          'data': data['data'],
        };

        notificationList.add(notification);
      }

      setState(() {
        _notifications = notificationList;
        _isLoading = false;
      });

      // تحديث حالة الإشعارات لتكون مقروءة
      for (var doc in snapshot.docs) {
        if (doc['isRead'] == false) {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(doc.id)
              .update({'isRead': true});
        }
      }
    } catch (e) {
      print('خطأ في جلب الإشعارات: $e');
      setState(() {
        _errorMessage = 'حدث خطأ أثناء تحميل الإشعارات: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('notifications')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _buildBody(localizations), // Pass localizations
    );
  }

  Widget _buildBody(AppLocalizations localizations) { // Accept localizations
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // New _isGuestMode check
    else if (_isGuestMode) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              "Stay Updated!", // Hardcoded: localizations.translate('notifications_guest_title'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                "Log in to receive personal notifications and updates.", // Hardcoded: localizations.translate('notifications_guest_description'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              icon: const Icon(Icons.login),
              label: Text(localizations.translate('login')), // Existing key
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Simplified _errorMessage block (no longer needs needsLogin check)
    else if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!, // Display the actual error
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications, // Retry loading
              child: Text(localizations.translate('retry')),
            ),
          ],
        ),
      );
    }

    else if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final DateTime timestamp = notification['timestamp'] ?? DateTime.now();
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy - hh:mm a');
    final bool isRead = notification['isRead'] ?? false;

    // تحديد الأيقونة حسب نوع الإشعار
    IconData icon;
    Color iconColor;

    switch (notification['type']) {
      case 'seller_approval':
        icon = Icons.verified_user;
        iconColor = Colors.green;
        break;
      case 'seller_rejection':
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'property_request':
        icon = Icons.home;
        iconColor = Colors.blue;
        break;
      case 'new_offer':
        icon = Icons.local_offer;
        iconColor = Colors.amber;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isRead ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification['title'] ?? '',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['body'] ?? ''),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // مسار التنقل عند النقر على الإشعار
    switch (notification['type']) {
      case 'seller_approval':
        Navigator.pushNamed(context, '/my-properties');
        break;
      case 'seller_rejection':
        Navigator.pushNamed(context, '/become-seller');
        break;
      case 'property_request':
        if (notification['data'] != null &&
            notification['data']['propertyId'] != null) {
          Navigator.pushNamed(
            context,
            '/property-details',
            arguments: notification['data']['propertyId'],
          );
        }
        break;
      case 'new_offer':
        Navigator.pushNamed(context, '/offers');
        break;
      default:
      // لا شيء
    }
  }

  Widget _buildEmptyState() {
    // localizations is already available in build method, if needed here, it should be passed.
    // For now, assuming it's not directly needed or accessed via AppLocalizations.of(context)
    final localizations = AppLocalizations.of(context); // Added to ensure it's available if used by original code

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            localizations.translate('no_notifications'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('no_notifications_description'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
