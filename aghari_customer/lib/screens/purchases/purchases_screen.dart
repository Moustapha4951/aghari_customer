import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../../providers/property_purchase_provider.dart';
import '../../models/property_purchase_model.dart';
import '../../localization/app_localizations.dart';
import '../../providers/user_provider.dart';
import 'purchases_translations.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({Key? key}) : super(key: key);

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isGuestUser = false; // Added state variable

  // المشتريات مصنفة حسب الحالة
  List<PropertyPurchaseModel> _allPurchases = [];
  List<PropertyPurchaseModel> _pendingPurchases = [];
  List<PropertyPurchaseModel> _approvedPurchases = [];
  List<PropertyPurchaseModel> _rejectedPurchases = [];
  List<PropertyPurchaseModel> _displayedPurchases = [];

  // متغيرات البحث والفلترة
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // إحصائيات
  Map<String, dynamic> _stats = {
    'total': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
    'totalValue': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // تحميل البيانات عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPurchases();

      // بدء التحديث الدوري
      final purchaseProvider =
          Provider.of<PropertyPurchaseProvider>(context, listen: false);
      purchaseProvider.startPeriodicFetch(context);

      // إضافة تحديث إضافي كل دقيقة للتأكد من تحديث الواجهة
      Timer.periodic(const Duration(minutes: 1), (timer) {
          if (mounted) {
          print('🔄 تحديث إضافي لشاشة المشتريات (${timer.tick})');
          _loadPurchases();
          } else {
          // إلغاء المؤقت إذا لم تعد الشاشة مرئية
            timer.cancel();
          }
        });
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate(PurchasesTranslations.kPurchases)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadPurchases,
            tooltip: localizations.translate(PurchasesTranslations.kRefresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPurchases,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    if (_isGuestUser) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              // Using hardcoded string as per instructions, localization key 'login_to_view_purchases' to be added later
              "Please log in to view your purchases.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              icon: const Icon(Icons.login),
              label: Text(localizations.translate('login')), // Existing key
            ),
          ],
        ),
      );
    }

    if (_isLoading && _allPurchases.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ??
                  localizations.translate(PurchasesTranslations.kErrorLoading),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPurchases,
              icon: const Icon(Icons.refresh),
              label: Text(localizations.translate('retry')),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // إحصائيات الطلبات
        _buildStatisticsCard(),

        // شريط البحث
        _buildSearchBar(),

        // شريط التبويب
        _buildTabBar(),

        // قائمة الطلبات
        Expanded(
          child: _displayedPurchases.isEmpty
              ? _buildEmptyState()
              : _buildPurchasesList(),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    final localizations = AppLocalizations.of(context);
    final currencyFormat = NumberFormat('#,###');

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            localizations.translate(PurchasesTranslations.kStatistics),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.receipt_long, '${_stats['total']}',
                  localizations.translate(PurchasesTranslations.kTotalRequests)),
              _buildStatItem(Icons.pending_actions, '${_stats['pending']}',
                  localizations.translate(PurchasesTranslations.kPendingRequests),
                  color: Colors.orange),
              _buildStatItem(Icons.check_circle, '${_stats['approved']}',
                  localizations.translate(PurchasesTranslations.kApprovedRequests),
                  color: Colors.green),
              _buildStatItem(
                  Icons.monetization_on,
                  '${currencyFormat.format(_stats['totalValue'])}',
                  localizations.translate(PurchasesTranslations.kTotalValue),
                  color: Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey[700]),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color ?? Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: localizations.translate('ابحث عن مشترياتي') ,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _handleSearch('');
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
        onChanged: _handleSearch,
      ),
    );
  }

  Widget _buildTabBar() {
    final localizations = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
              tabs: [
                Tab(text: localizations.translate('all')),
          _buildTabWithBadge(
            localizations.translate('status_pending'),
            _stats['pending'],
            Colors.orange,
          ),
          _buildTabWithBadge(
            localizations.translate('status_approved'),
            _stats['approved'],
            Colors.green,
          ),
          _buildTabWithBadge(
            localizations.translate('status_rejected'),
            _stats['rejected'],
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTabWithBadge(String text, int count, Color badgeColor) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                count.toString(),
            style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
                textAlign: TextAlign.center,
          ),
          ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context);

    String message;
    switch (_tabController.index) {
      case 1:
        message = localizations.translate('no_pending_purchases');
        break;
      case 2:
        message = localizations.translate('no_approved_purchases');
        break;
      case 3:
        message = localizations.translate('no_rejected_purchases');
        break;
      default:
        message = localizations.translate('no_purchases');
    }

    return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
            message,
                    style: TextStyle(
              fontSize: 16,
                      color: Colors.grey[600],
                    ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _displayedPurchases.length,
      itemBuilder: (context, index) {
        final purchase = _displayedPurchases[index];
        return _buildPurchaseCard(purchase);
      },
    );
  }

  Widget _buildPurchaseCard(PropertyPurchaseModel purchase) {
    final localizations = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusText = _getStatusText(purchase.status);
    final statusColor = _getStatusColor(purchase.status);
    final currencyFormat = NumberFormat('#,###');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _showPurchaseDetails(purchase),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // رأس البطاقة مع الحالة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(_getStatusIcon(purchase.status),
                          color: statusColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                          style: TextStyle(
                          color: statusColor,
                            fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    dateFormat.format(purchase.purchaseDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    ),
                ],
              ),
            ),

            // محتوى البطاقة
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان العقار
                  Text(
                    purchase.propertyTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // معلومات البائع
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                                purchase.ownerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _callSeller(purchase.ownerPhone),
                                child: Row(
                    children: [
                                    Icon(Icons.phone,
                                        color: Colors.green[700], size: 16),
                          const SizedBox(width: 4),
                          Text(
                                      purchase.ownerPhone,
                            style: TextStyle(
                                        color: Colors.green[700],
                                        decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${currencyFormat.format(purchase.propertyPrice.toInt())} ${localizations.translate('currency')}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                  ),
                ],
              ),
            ),

                  // خيارات
                  ButtonBar(
                    alignment: MainAxisAlignment.spaceBetween,
                    buttonPadding: EdgeInsets.zero,
                children: [
                  TextButton.icon(
                        onPressed: () => _showPurchaseDetails(purchase),
                    icon: const Icon(Icons.info_outline, size: 16),
                        label: Text(localizations.translate('view_details')),
                    ),
                      if (purchase.status.toLowerCase() == 'pending')
                        TextButton.icon(
                    onPressed: () =>
                              _confirmCancelPurchase(purchase.id ?? ''),
                          icon: const Icon(Icons.cancel_outlined,
                              size: 16, color: Colors.red),
                          label: Text(
                            localizations.translate('cancel_request'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (purchase.status.toLowerCase() == 'approved')
                        TextButton.icon(
                          onPressed: () => _callSeller(purchase.ownerPhone),
                          icon: const Icon(Icons.phone,
                              size: 16, color: Colors.green),
                      label: Text(
                            localizations.translate('call_seller'),
                            style: TextStyle(color: Colors.green[700]),
                      ),
                      ),
                    ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;

    setState(() {
      _updateDisplayedPurchases();
    });
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _updateDisplayedPurchases();
    });
  }

  Future<void> _loadPurchases() async {
    if (!mounted) return; // التحقق من أن الشاشة لا تزال مرئية

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _isGuestUser = false; // Reset guest status
    });

    try {
      print('📋 جاري تحميل طلبات المشتريات...');
      final startTime = DateTime.now();

      // استخدام UserProvider بدلاً من FirebaseAuth
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // تحديث حالة المستخدم من التخزين المحلي
      await userProvider.checkUserSession();

      if (userProvider.currentUser == null) {
        print('👤 المستخدم غير مسجل الدخول - عرض شاشة الضيف');
        setState(() {
          _isLoading = false;
          _isGuestUser = true;
        });
        return; // Return early, do not proceed to fetch purchases
      }

      // استخدام معرف المستخدم من UserProvider
      final userId = userProvider.currentUser!.id;
      print('👤 جلب طلبات المشتريات للمستخدم: $userId');

      // محاولة جلب المشتريات باستخدام مزود البيانات
      final purchaseProvider =
          Provider.of<PropertyPurchaseProvider>(context, listen: false);

      // تعيين معرف المستخدم في مزود طلبات الشراء
      purchaseProvider.setUserId(userId);

      // استخدام الطريقة الذكية لتحميل الطلبات بدلاً من إعادة التحميل الكامل
      await purchaseProvider.loadPurchasesSmartly();

      // الحصول على أحدث التحديثات من Firebase
      print('🔍 التحقق من أحدث تحديثات الحالة...');
      await purchaseProvider.checkForStatusUpdates(forceUpdate: true);

      // استخدام الطلبات من المزود
      final purchases = purchaseProvider.purchases;
      print('✅ تم جلب ${purchases.length} طلب من المزود');

      // طباعة حالات الطلبات للتشخيص
      if (purchases.isNotEmpty) {
        print('📊 إحصائيات الطلبات:');
        int pending = 0, approved = 0, rejected = 0, cancelled = 0, others = 0;

        for (var purchase in purchases) {
          final status = purchase.status.toLowerCase();
          if (status == 'pending')
            pending++;
          else if (status == 'approved')
            approved++;
          else if (status == 'rejected')
            rejected++;
          else if (status == 'cancelled')
            cancelled++;
          else
            others++;

          print(
              '🏠 طلب ${purchase.id} - الحالة: ${purchase.status} - العنوان: ${purchase.propertyTitle}');
        }

        print(
            '📈 قيد الانتظار: $pending, الموافقة: $approved, الرفض: $rejected, الإلغاء: $cancelled, أخرى: $others');
      }

      // تصنيف الطلبات المجلوبة من المزود
      _categorizeRequests(purchases);

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      print('⏱️ استغرق تحميل وتصنيف المشتريات: $duration مللي ثانية');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ خطأ في تحميل المشتريات: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _categorizeRequests(List<PropertyPurchaseModel> purchases) {
    _allPurchases = purchases;

    // تنظيف القوائم
    _pendingPurchases.clear();
    _approvedPurchases.clear();
    _rejectedPurchases.clear();

    // فرز الطلبات حسب حالتها
    for (var purchase in purchases) {
      final status = purchase.status.toLowerCase();
      if (status == 'pending') {
        _pendingPurchases.add(purchase);
      } else if (status == 'approved') {
        _approvedPurchases.add(purchase);
      } else if (status == 'rejected' || status == 'cancelled') {
        _rejectedPurchases.add(purchase);
      }
    }

    // تحديث الإحصائيات
    int totalValue = 0;
    for (var purchase in purchases) {
      totalValue += purchase.propertyPrice.toInt();
    }

    _stats = {
      'total': purchases.length,
      'pending': _pendingPurchases.length,
      'approved': _approvedPurchases.length,
      'rejected': _rejectedPurchases.length,
      'totalValue': totalValue,
    };

    // تحديث المشتريات المعروضة
    _updateDisplayedPurchases();
  }

  void _updateDisplayedPurchases() {
    // تحديد المشتريات التي ستعرض حسب التبويب الحالي
    switch (_tabController.index) {
      case 0: // الكل
        _displayedPurchases = List.from(_allPurchases);
        break;
      case 1: // قيد الانتظار
        _displayedPurchases = List.from(_pendingPurchases);
        break;
      case 2: // تمت الموافقة
        _displayedPurchases = List.from(_approvedPurchases);
        break;
      case 3: // مرفوض
        _displayedPurchases = List.from(_rejectedPurchases);
        break;
    }

    // تطبيق البحث إذا كان هناك كلمة بحث
    if (_searchQuery.isNotEmpty) {
      _displayedPurchases = _displayedPurchases.where((purchase) {
        final title = purchase.propertyTitle.toLowerCase();
        final sellerName = purchase.ownerName.toLowerCase();
        final query = _searchQuery.toLowerCase();

        return title.contains(query) ||
            sellerName.contains(query) ||
            purchase.ownerPhone.contains(query);
      }).toList();
    }

    // ترتيب المشتريات حسب التاريخ (الأحدث أولاً)
    _displayedPurchases
        .sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
  }

  // دوال مساعدة لحالة الطلب
  String _getStatusText(String status) {
    final localizations = AppLocalizations.of(context);
    switch (status.toLowerCase()) {
      case 'pending':
        return localizations.translate('status_pending');
      case 'approved':
        return localizations.translate('status_approved');
      case 'rejected':
        return localizations.translate('status_rejected');
      case 'cancelled':
        return localizations.translate('status_cancelled');
      case 'completed':
        return localizations.translate('status_completed');
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.red[400]!;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.close;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help_outline;
    }
  }

  // إظهار تفاصيل طلب الشراء
  void _showPurchaseDetails(PropertyPurchaseModel purchase) {
    final localizations = AppLocalizations.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusText = _getStatusText(purchase.status);
    final statusColor = _getStatusColor(purchase.status);
    final currencyFormat = NumberFormat('#,###');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // مؤشر السحب
            Center(
              child: Container(
                    width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

                // عنوان وحالة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
              localizations.translate('request_details'),
              style: const TextStyle(
                          fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStatusIcon(purchase.status),
                              size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // تفاصيل العقار
                _buildDetailSection(
                  title: localizations.translate('property_details'),
                  children: [
                    _buildDetailRow(
                      icon: Icons.home,
                      label: localizations.translate('property_title'),
                      value: purchase.propertyTitle,
                    ),
                    if (purchase.propertyType != null)
                      _buildDetailRow(
                        icon: Icons.category,
                        label: localizations.translate('property_type'),
                        value: _getPropertyTypeText(purchase.propertyType!),
                      ),
                    _buildDetailRow(
                      icon: Icons.monetization_on,
                      label: localizations.translate('price'),
                      value:
                          '${currencyFormat.format(purchase.propertyPrice.toInt())} ${localizations.translate('currency')}',
                      valueColor: Theme.of(context).primaryColor,
                    ),
                    if (purchase.propertyStatus != null)
                      _buildDetailRow(
                        icon: Icons.info_outline,
                        label: localizations.translate('property_status'),
                        value: _getPropertyStatusText(purchase.propertyStatus!),
                      ),
                    if (purchase.city != null)
                      _buildDetailRow(
                        icon: Icons.location_city,
                        label: localizations.translate('city'),
                        value: _getCityName(purchase.city!),
                      ),
                    if (purchase.district != null)
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: localizations.translate('district'),
                        value: purchase.district!,
                      ),
                  ],
            ),
            const SizedBox(height: 16),

                // تفاصيل البائع
                _buildDetailSection(
                  title: localizations.translate('seller_details'),
                  children: [
            _buildDetailRow(
                      icon: Icons.person,
                      label: localizations.translate('name'),
                      value: purchase.ownerName,
                    ),
            _buildDetailRow(
                      icon: Icons.phone,
                      label: localizations.translate('phone'),
                      value: purchase.ownerPhone,
                      onTap: () => _callSeller(purchase.ownerPhone),
                      valueColor: Colors.blue,
                      valueDecoration: TextDecoration.underline,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // تفاصيل الطلب
                _buildDetailSection(
                  title: localizations.translate('request_info'),
                  children: [
            _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: localizations.translate('request_date'),
                      value: dateFormat.format(purchase.purchaseDate),
                    ),
                    _buildDetailRow(
                      icon: Icons.av_timer,
                      label: localizations.translate('status'),
                      value: statusText,
                      valueColor: statusColor,
                    ),
            if (purchase.notes != null && purchase.notes!.isNotEmpty)
                      _buildDetailRow(
                        icon: Icons.note,
                        label: localizations.translate('notes'),
                        value: purchase.notes!,
                      ),
                    // عرض ملاحظات المدير إذا كانت موجودة (سواء تم الرفض أو القبول)
                    if (purchase.adminNotes != null &&
                        purchase.adminNotes!.isNotEmpty)
                      _buildDetailRow(
                        icon: Icons.comment,
                        label: localizations.translate('admin_notes'),
                        value: purchase.adminNotes!,
                        valueColor: Theme.of(context).primaryColor,
                      ),
                    // إضافة عرض سبب الرفض إذا كان الطلب مرفوضاً وتم تحديد سبب
                    if (purchase.status.toLowerCase() == 'rejected' &&
                        purchase.rejectionReason != null &&
                        purchase.rejectionReason!.isNotEmpty)
                      _buildDetailRow(
                        icon: Icons.cancel,
                        label: localizations.translate('rejection_reason'),
                        value: purchase.rejectionReason!,
                        valueColor: Colors.red,
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // أزرار الإجراءات
                if (purchase.status.toLowerCase() == 'approved')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                      onPressed: () => _callSeller(purchase.ownerPhone),
                      icon: const Icon(Icons.phone),
                      label: Text(localizations.translate('call_seller')),
                  style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (purchase.status.toLowerCase() == 'pending')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                        _confirmCancelPurchase(purchase.id ?? '');
                  },
                      icon:
                          const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: Text(
                        localizations.translate('cancel_request'),
                        style: const TextStyle(color: Colors.red),
                ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
              ),
                    ),
                  ),
                const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                    child: Text(localizations.translate('close')),
              ),
            ),
          ],
        ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    TextDecoration? valueDecoration,
    VoidCallback? onTap,
  }) {
    final row = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                  fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  decoration: valueDecoration,
                  ),
                ),
              ],
            ),
          ),
        ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: row,
      ),
    );
  }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: row,
    );
  }

  String _getPropertyTypeText(String type) {
    final localizations = AppLocalizations.of(context);
    switch (type.toLowerCase()) {
      case 'house':
        return localizations.translate('house');
      case 'apartment':
        return localizations.translate('apartment');
      case 'villa':
        return localizations.translate('villa');
      case 'land':
        return localizations.translate('land');
      case 'commercial':
        return localizations.translate('commercial');
      case 'store':
        return localizations.translate('store');
      default:
        return type;
    }
  }

  String _getPropertyStatusText(String status) {
    final localizations = AppLocalizations.of(context);
    switch (status.toLowerCase()) {
      case 'for_sale':
        return localizations.translate('for_sale');
      case 'for_rent':
        return localizations.translate('for_rent');
      default:
        return status;
    }
  }

  String _getCityName(String city) {
    final localizations = AppLocalizations.of(context);
    switch (city.toLowerCase()) {
      case 'nouakchott':
        return localizations.translate('nouakchott');
      case 'nouadhibou':
        return localizations.translate('nouadhibou');
      default:
        return city;
    }
  }

  // تأكيد إلغاء طلب الشراء
  void _confirmCancelPurchase(String purchaseId) {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('confirm_cancel')),
        content: Text(localizations.translate('confirm_cancel_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.translate('back')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelPurchase(purchaseId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.translate('confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelPurchase(String purchaseId) async {
    final localizations = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final purchaseProvider =
                  Provider.of<PropertyPurchaseProvider>(context, listen: false);

      // إضافة التحقق من المستخدم قبل الإلغاء
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        // تعيين معرف المستخدم في مزود طلبات الشراء
        purchaseProvider.setUserId(userProvider.currentUser!.id);
      }

      await purchaseProvider.cancelPurchase(purchaseId);

      // تحديث المشتريات بعد الإلغاء
      await _loadPurchases();

      if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
            content: Text(localizations.translate('request_cancelled_success')),
                    backgroundColor: Colors.green,
                  ),
                );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
            content: Text('${localizations.translate('error')}: $e'),
                    backgroundColor: Colors.red,
      ),
    );
  }
    }
  }

  // الاتصال بالبائع
  Future<void> _callSeller(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).translate('cannot_call') +
                    ': $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
