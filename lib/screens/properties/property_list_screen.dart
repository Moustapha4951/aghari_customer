import 'package:aghari_customer/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../providers/property_provider.dart';
import '../../widgets/property_card.dart';
import '../home/filter_dialog.dart';

class PropertyListScreen extends StatefulWidget {
  final String title;
  final PropertyStatus status;

  const PropertyListScreen({
    Key? key,
    required this.title,
    required this.status,
  }) : super(key: key);

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  PropertyFilter? _activeFilter;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      await propertyProvider.fetchProperties();

      // تطبيق فلتر حالة العقار (بيع/إيجار)
      propertyProvider.applyFilters(status: widget.status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).translate('error_occurred') +
                    ': $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showFilterDialog() async {
    final result = await showDialog<PropertyFilter>(
      context: context,
      builder: (context) => FilterDialog(initialFilter: _activeFilter),
    );

    if (result != null && mounted) {
      setState(() {
        _activeFilter = result;
      });

      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      // تطبيق الفلتر مع الحفاظ على فلتر حالة العقار
      propertyProvider.applyFilters(
        cityId: result.city,
        type: result.type != null
            ? PropertyType.values.firstWhere(
                (type) => type.toString().split('.').last == result.type,
                orElse: () => PropertyType.apartment,
              )
            : null,
        status: widget.status, // دائمًا استخدم حالة العقار المحددة للشاشة
        minPrice: result.minPrice,
        maxPrice: result.maxPrice,
      );
    }
  }

  void _showSortDialog() {
    final localizations = AppLocalizations.of(context);

    // النسخة المبسطة لحوار الترتيب بدون استدعاء وظائف غير موجودة
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.translate('sort')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: Text(localizations.translate('price_low_to_high')),
              onTap: () {
                // إغلاق الحوار فقط في الوقت الحالي
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: Text(localizations.translate('price_high_to_low')),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(localizations.translate('newest_first')),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.space_dashboard_outlined),
              title: Text(localizations.translate('area_largest_first')),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // استخدام مفتاح ترجمة للعنوان بناءً على حالة العقار بدلاً من المعلمة الممررة
    final screenTitle = widget.status == PropertyStatus.forSale
        ? localizations.translate('properties_for_sale')
        : localizations.translate('properties_for_rent');

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle), // استخدام العنوان المترجم دائماً
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildSearchBar(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: localizations.translate('filter'),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: localizations.translate('sort'),
            onPressed: _showSortDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<PropertyProvider>(
              builder: (context, propertyProvider, child) {
                final properties = propertyProvider.properties
                    .where((p) => p.status == widget.status)
                    .where((p) =>
                        _searchQuery.isEmpty ||
                        p.title
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        p.address
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        p.description
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                    .toList();

                if (properties.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.status == PropertyStatus.forSale
                              ? Icons.sell
                              : Icons.home,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.translate('no_matching_properties'),
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _activeFilter = null;
                            });
                            final propertyProvider =
                                Provider.of<PropertyProvider>(context,
                                    listen: false);
                            propertyProvider.applyFilters(
                              status: widget.status,
                            );
                          },
                          child: Text(localizations.translate('reset_filter')),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    return PropertyCard(
                      property: property,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/property-details',
                          arguments: property.id,
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildSearchBar() {
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: localizations.translate('search_hint'),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }
}
