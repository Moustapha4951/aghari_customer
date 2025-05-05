import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

class BecomeSellerOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  
  const BecomeSellerOverlay({Key? key, required this.onDismiss}) : super(key: key);

  @override
  State<BecomeSellerOverlay> createState() => _BecomeSellerOverlayState();
}

class _BecomeSellerOverlayState extends State<BecomeSellerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  // مزايا الانضمام كبائع
  final List<Map<String, dynamic>> _benefits = [
    {
      'icon': Icons.real_estate_agent,
      'title': 'عرض العقارات الخاصة بك',
      'description': 'إمكانية نشر وإدارة العقارات على المنصة',
    },
    {
      'icon': Icons.trending_up,
      'title': 'زيادة المبيعات',
      'description': 'الوصول لآلاف العملاء المحتملين',
    },
    {
      'icon': Icons.verified_user,
      'title': 'بائع معتمد',
      'description': 'الحصول على شارة البائع المعتمد',
    },
    {
      'icon': Icons.attach_money,
      'title': 'عمولات أقل',
      'description': 'عمولات تنافسية على كل عملية بيع',
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // إعداد التأثيرات الحركية
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );
    
    // بدء التأثيرات الحركية
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return WillPopScope(
      onWillPop: () async {
        // عند الضغط على زر الرجوع
        widget.onDismiss();
        return false;
      },
      child: Stack(
        children: [
          // طبقة التظليل
          FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ),
          
          // محتوى الطبقة
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // رأس الطبقة
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                localizations.translate('become_seller'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: widget.onDismiss,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // الشعار أو الصورة التوضيحية
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.store,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // نص توضيحي
                        Text(
                          localizations.translate('join_as_seller_promo'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // قائمة المزايا
                        ...List.generate(_benefits.length, (index) {
                          final benefit = _benefits[index];
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    benefit['icon'],
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        benefit['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        benefit['description'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        
                        const SizedBox(height: 20),
                        
                        // زر الانضمام
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onDismiss();
                              Navigator.pushNamed(context, '/become-seller');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.store),
                                const SizedBox(width: 8),
                                Text(
                                  localizations.translate('join_now'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// دالة مساعدة للتحقق من عرض الطبقة التوجيهية
class BecomeSellerOverlayHelper {
  static const String _hasSeenOverlayKey = 'has_seen_seller_overlay';
  
  // التحقق من عرض الطبقة من قبل
  static Future<bool> shouldShowOverlay() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_hasSeenOverlayKey) ?? false);
  }
  
  // تعيين أن المستخدم شاهد الطبقة
  static Future<void> markOverlayAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOverlayKey, true);
  }
} 