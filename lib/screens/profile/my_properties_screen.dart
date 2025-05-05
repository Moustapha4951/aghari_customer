import 'package:aghari_customer/screens/properties/add_property_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/property_provider.dart';
import '../../providers/user_provider.dart';
import '../../localization/app_localizations.dart';
import '../../models/property_approval_status.dart';
import '../../models/property_model.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({Key? key}) : super(key: key);

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  TabController? _tabController;
  Map<String, List<PropertyModel>> _categorizedProperties = {
    'pending': [],
    'approved': [],
    'rejected': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMyProperties();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadMyProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null || !user.isSeller) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      // استخدام الطريقة الجديدة لتجميع العقارات حسب حالة الموافقة
      _categorizedProperties =
          await propertyProvider.fetchUserPropertiesByStatus(user.id);
    } catch (e) {
      print('خطأ في تحميل العقارات: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    final localizations = AppLocalizations.of(context);

    // التحقق من وجود المستخدم وكونه بائعاً
    if (user == null || !user.isSeller) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.translate('my_properties'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.no_accounts, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                localizations.translate('no_access_permission'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                localizations.translate('seller_required_access'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.translate('back')),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.translate('my_properties'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool hasNoProperties = _categorizedProperties['pending']!.isEmpty &&
        _categorizedProperties['approved']!.isEmpty &&
        _categorizedProperties['rejected']!.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('my_properties')),
        bottom: hasNoProperties
            ? null
            : TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            localizations.translate('property_status_pending')),
                        const SizedBox(width: 4),
                        if (_categorizedProperties['pending']!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_categorizedProperties['pending']!.length}',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(localizations
                            .translate('property_status_approved')),
                        const SizedBox(width: 4),
                        if (_categorizedProperties['approved']!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_categorizedProperties['approved']!.length}',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(localizations
                            .translate('property_status_rejected')),
                        const SizedBox(width: 4),
                        if (_categorizedProperties['rejected']!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_categorizedProperties['rejected']!.length}',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      body: hasNoProperties
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work_outlined,
                      size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('no_properties'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // التنقل إلى صفحة إضافة عقار
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPropertyScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(localizations.translate('add_new_property')),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // علامة التبويب الأولى: العقارات المعلقة
                _buildPropertyList(_categorizedProperties['pending']!,
                    PropertyApprovalStatus.pending, localizations),

                // علامة التبويب الثانية: العقارات المعتمدة
                _buildPropertyList(_categorizedProperties['approved']!,
                    PropertyApprovalStatus.approved, localizations),

                // علامة التبويب الثالثة: العقارات المرفوضة
                _buildPropertyList(_categorizedProperties['rejected']!,
                    PropertyApprovalStatus.rejected, localizations),
              ],
            ),
      // زر إضافة عقار جديد
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AddPropertyScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPropertyList(List<PropertyModel> properties,
      PropertyApprovalStatus status, AppLocalizations localizations) {
    if (properties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == PropertyApprovalStatus.pending
                  ? Icons.pending_actions
                  : status == PropertyApprovalStatus.approved
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStatusMessage(status, localizations),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // شريط حالة العقار
              Container(
                color: _getStatusColor(property.approvalStatus),
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(property.approvalStatus),
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusText(property.approvalStatus, localizations),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // صورة العقار
              if (property.images.isNotEmpty)
                Image.network(
                  property.images.first,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان العقار
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // السعر والموقع
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.address,
                            style: TextStyle(color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.attach_money,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${property.price} أوقية',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // أزرار الإجراءات
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit,
                          label: localizations.translate('edit'),
                          onPressed: () {},
                        ),
                        _buildActionButton(
                          icon: Icons.visibility,
                          label: localizations.translate('view'),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/property-details',
                              arguments: property.id,
                            );
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.delete,
                          label: localizations.translate('delete'),
                          color: Colors.red,
                          onPressed: () => _confirmDeleteProperty(
                              context, property.id, localizations),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteProperty(BuildContext context, String propertyId,
      AppLocalizations localizations) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(localizations.translate('delete_property')),
            content:
                Text(localizations.translate('delete_property_confirmation')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(localizations.translate('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && context.mounted) {
      try {
        final propertyProvider =
            Provider.of<PropertyProvider>(context, listen: false);
        await propertyProvider.deleteProperty(propertyId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف العقار بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          // إعادة تحميل العقارات بعد الحذف
          _loadMyProperties();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في حذف العقار: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(icon, color: color ?? Colors.grey[700]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color ?? Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PropertyApprovalStatus status) {
    switch (status) {
      case PropertyApprovalStatus.pending:
        return Colors.amber;
      case PropertyApprovalStatus.approved:
        return Colors.green;
      case PropertyApprovalStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PropertyApprovalStatus status) {
    switch (status) {
      case PropertyApprovalStatus.pending:
        return Icons.pending;
      case PropertyApprovalStatus.approved:
        return Icons.check_circle;
      case PropertyApprovalStatus.rejected:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(
      PropertyApprovalStatus status, AppLocalizations localizations) {
    switch (status) {
      case PropertyApprovalStatus.pending:
        return localizations.translate('property_status_pending');
      case PropertyApprovalStatus.approved:
        return localizations.translate('property_status_approved');
      case PropertyApprovalStatus.rejected:
        return localizations.translate('property_status_rejected');
      default:
        return '';
    }
  }

  String _getEmptyStatusMessage(
      PropertyApprovalStatus status, AppLocalizations localizations) {
    switch (status) {
      case PropertyApprovalStatus.pending:
        return 'لا توجد عقارات معلقة';
      case PropertyApprovalStatus.approved:
        return 'لا توجد عقارات تمت الموافقة عليها';
      case PropertyApprovalStatus.rejected:
        return 'لا توجد عقارات مرفوضة';
      default:
        return 'لا توجد عقارات';
    }
  }
}
