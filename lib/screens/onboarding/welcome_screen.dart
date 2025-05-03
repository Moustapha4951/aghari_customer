import 'package:aghari_customer/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // إعادة زر التخطي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _goToOffersScreen(context),
                    icon: const Icon(Icons.local_offer),
                    label:
                        Text(AppLocalizations.of(context).translate('offers')),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _showLanguageDialog(context);
                    },
                    icon: const Icon(Icons.language),
                    label: Text(
                        AppLocalizations.of(context).translate('language')),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ],
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
                          color: Colors.amber.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/welcome_icon.png',
                            width: 200,
                            height: 200,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.home,
                              size: 80,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // العنوان الرئيسي
              Text(
                AppLocalizations.of(context).translate('request_your_property'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // النص التوضيحي
              Text(
                AppLocalizations.of(context)
                    .translate('property_agents_description'),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // الميزات
              _buildFeatureItem(
                context,
                Icons.local_offer,
                AppLocalizations.of(context).translate('matching_offers'),
                AppLocalizations.of(context)
                    .translate('matching_offers_description'),
                onTap: () => _goToMainScreen(context),
              ),

              const SizedBox(height: 16),

              // تعديل عنصر "تواصل مباشر" ليحتوي على الأرقام
              _buildFeatureItem(
                context,                Icons.phone,
                AppLocalizations.of(context).translate('direct_communication'),
                AppLocalizations.of(context).translate('direct_communication_description'),
                onTap: () => _showContactOptions(context),
              ),

              const SizedBox(height: 16),

              _buildFeatureItem(
                context,
                Icons.business,
                AppLocalizations.of(context).translate('become_agent'),
                AppLocalizations.of(context)
                    .translate('become_agent_description'),
                onTap: () => Navigator.pushNamed(context, '/become-seller'),
              ),

              const SizedBox(height: 40),

              // زر البدء
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _goToHome(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    AppLocalizations.of(context)
                        .translate('submit_request_now'),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // إضافة دالة لعرض خيارات الاتصال
  void _showContactOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('contact_us')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('22505361'),
              onTap: () => _launchCall('22505361', context),
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('44549730'),
              onTap: () => _launchCall('44549730', context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
        ],
      ),
    );
  }

  // دالة لتنفيذ الاتصال
  void _launchCall(String phoneNumber, BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      debugPrint('لا يمكن الاتصال بالرقم $phoneNumber');
    }
    Navigator.pop(context);
  }

  // دالة لإنشاء عنصر ميزة قابل للنقر
  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.amber),
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
          if (onTap != null)
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  // دالة للانتقال إلى شاشة طلب العقار
  void _goToHome(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/request-property',
        arguments: {'from_welcome': true});
  }

  // تغيير دالة التخطي لتوجه المستخدم إلى شاشة العروض
  void _goToOffersScreen(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_welcome', true);

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/offers');
      }
    } catch (e) {
      print('خطأ في الانتقال إلى شاشة العروض: $e');
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/offers');
      }
    }
  }

  // إضافة دالة للانتقال إلى الشاشة الرئيسية بالشريط السفلي
  void _goToMainScreen(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_welcome', true);

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      print('خطأ في الانتقال إلى الشاشة الرئيسية: $e');
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  // إضافة دالة عرض حوار تغيير اللغة
  void _showLanguageDialog(BuildContext context) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('العربية'),
              leading: const Text('🇸🇦'),
              selected: languageProvider.isArabic(),
              onTap: () {
                languageProvider.changeLanguage('ar');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Français'),
              leading: const Text('🇫🇷'),
              selected: languageProvider.isFrench(),
              onTap: () {
                languageProvider.changeLanguage('fr');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
