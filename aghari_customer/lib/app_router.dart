import 'package:flutter/material.dart';
import 'screens/profile/request_property_screen.dart';
// قم باستيراد الشاشات الأخرى هنا...

class AppRouter {
  // تحديث المسارات
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // المسارات الحالية...

      case '/request-property':
        return MaterialPageRoute(builder: (_) => const RequestPropertyScreen());

      // مسارات أخرى...
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('صفحة غير موجودة: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
