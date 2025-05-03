import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../localization/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('settings')),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // إعدادات اللغة مع تصميم أفضل
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('language'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // خيار اللغة العربية
                  _buildLanguageOption(
                    context,
                    title: 'العربية',
                    subtitle: 'Arabic',
                    isSelected: languageProvider.isArabic(),
                    onTap: () => languageProvider.changeLanguage('ar'),
                  ),
                  
                  const Divider(),
                  
                  // خيار اللغة الفرنسية
                  _buildLanguageOption(
                    context,
                    title: 'Français',
                    subtitle: 'French',
                    isSelected: languageProvider.isFrench(),
                    onTap: () => languageProvider.changeLanguage('fr'),
                  ),
                ],
              ),
            ),
          ),
          
          // البقية كما هي...
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(localizations.translate('about')),
            onTap: () {
              // فتح شاشة حول التطبيق
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_phone),
            title: Text(localizations.translate('contact_us')),
            onTap: () {
              // فتح شاشة اتصل بنا
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(localizations.translate('terms')),
            onTap: () {
              // فتح شاشة الشروط والأحكام
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(localizations.translate('privacy_policy')),
            onTap: () {
              // فتح شاشة سياسة الخصوصية
            },
          ),
        ],
      ),
    );
  }
  
  // دالة مساعدة لإنشاء خيار اللغة
  Widget _buildLanguageOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }
} 