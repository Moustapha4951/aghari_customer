import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BecomeSellerWelcomeScreen extends StatelessWidget {
  const BecomeSellerWelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // زر تخطي
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _skipToMainScreen(context),
                  child: const Text('تخطي'),
                ),
              ),

              // صورة الترحيب
              Expanded(
                flex: 4,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/aghari.png',
                            width: 200,
                            height: 200,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.store,
                              size: 80,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // العنوان الرئيسي
              const Text(
                'كن وسيطاً عقارياً!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // النص التوضيحي
              const Text(
                'انضم إلى منصة عقاري كوسيط عقاري واستفد من مزايا حصرية',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // الميزات
              _buildFeatureItem(
                context,
                Icons.add_business,
                'عرض عقاراتك',
                'إضافة ونشر العقارات في المنصة',
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                context,
                Icons.attach_money,
                'مصدر دخل إضافي',
                'كسب المزيد من العملاء والأرباح',
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                context,
                Icons.verified_user,
                'وسيط معتمد',
                'علامة توثيق تزيد من ثقة العملاء',
              ),

              const SizedBox(height: 40),

              // زر البدء
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _goToRequestScreen(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'سجل كوسيط عقاري الآن',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لإنشاء عنصر ميزة
  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // دالة للانتقال إلى شاشة تقديم طلب تسجيل كبائع
  void _goToRequestScreen(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_seller_welcome', true);
      
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/become-seller');
      }
    } catch (e) {
      print('خطأ في الانتقال من شاشة الترحيب: $e');
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/become-seller');
      }
    }
  }

  // دالة للتخطي إلى الشاشة الرئيسية
  void _skipToMainScreen(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_seller_welcome', true);
      
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      print('خطأ في التخطي للشاشة الرئيسية: $e');
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }
} 