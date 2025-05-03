import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'سياسة الخصوصية',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'آخر تحديث: ينار 2024',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 24),
            Text(
              'مرحباً بك في تطبيق عقاري',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'نلتزم في عقاري بحماية خصوصيتك وبياناتك الشخصية. توضح سياسة الخصوصية هذه كيفية جمع واستخدام وحماية المعلومات التي تقدمها عند استخدام تطبيقنا.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'المعلومات التي نجمعها',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '• معلومات الحساب: عند التسجيل، نقوم بجمع اسمك، بريدك الإلكتروني، ورقم هاتفك.\n'
              '• المعلومات المقدمة: أي معلومات تقدمها طوعًا مثل تفاصيل العقارات أو المراجعات.\n'
              '• معلومات الجهاز: نجمع معلومات عن الجهاز الذي تستخدمه للوصول إلى التطبيق.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'كيف نستخدم معلوماتك',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '• لتقديم وتحسين خدماتنا.\n'
              '• للتواصل معك حول التحديثات والعروض.\n'
              '• لأغراض الأمان وتحسين التطبيق.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'مشاركة المعلومات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'لا نشارك معلوماتك الشخصية مع أطراف ثالثة دون موافقتك، باستثناء ما يلي:\n'
              '• المطورين وموفري الخدمات الذين يساعدوننا في تشغيل التطبيق.\n'
              '• الامتثال للقوانين والإجراءات القانونية.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'أمان البيانات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نتخذ تدابير مناسبة لحماية معلوماتك من الوصول أو التغيير أو الإفصاح غير المصرح به.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'تغييرات في سياسة الخصوصية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر. سنخطرك بأي تغييرات عن طريق نشر السياسة الجديدة على هذه الصفحة.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'اتصل بنا',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'إذا كان لديك أي أسئلة حول سياسة الخصوصية، يرجى الاتصال بنا على support@aghari.com',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
