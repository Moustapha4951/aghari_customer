import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/property_provider.dart';
import '../../widgets/property_card.dart';
import 'filter_dialog.dart';
import '../properties/property_list_screen.dart';
import '../../widgets/become_seller_overlay.dart';
import '../../localization/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  PropertyFilter? _activeFilter;
  bool _showSellerOverlay = false;

  final Map<String, PropertyType?> _filterTypes = {
    'all': null,
    'house': PropertyType.house,
    'villa': PropertyType.villa,
    'apartment': PropertyType.apartment,
    'store': PropertyType.store,
    'hall': PropertyType.hall,
    'studio': PropertyType.studio,
    'land': PropertyType.land,
    'other': PropertyType.other,
  };

  @override
  void initState() {
    super.initState();

    // تحميل العقارات عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      propertyProvider.fetchProperties();

      // التحقق من عرض طبقة الانضمام كبائع
      _checkSellerOverlay();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(String filterKey) {
    setState(() {
      _selectedFilter = filterKey;
      _activeFilter = PropertyFilter(
        type: filterKey == 'all'
            ? null
            : _getPropertyTypeString(_filterTypes[filterKey]),
        city: null,
        propertyType: null,
        minPrice: null,
        maxPrice: null,
      );
    });

    // تطبيق الفلتر
    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);
    propertyProvider.applyFilters(
      type: _filterTypes[filterKey],
    );
  }

  String? _getPropertyTypeString(PropertyType? type) {
    if (type == null) return null;
    return type.toString().split('.').last;
  }

  void _showFilterDialog() async {
    final result = await showDialog<PropertyFilter>(
      context: context,
      builder: (context) => FilterDialog(initialFilter: _activeFilter),
    );

    if (result != null) {
      setState(() {
        _activeFilter = result;
        // تحديث الفلتر المحدد إذا تم تغيير النوع
        if (result.type != null) {
          for (var entry in _filterTypes.entries) {
            String typeString = _getPropertyTypeString(entry.value) ?? '';
            if (typeString == result.type) {
              _selectedFilter = entry.key;
              break;
            }
          }
        }
      });

      // تطبيق الفلتر الشامل
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      propertyProvider.applyFilters(
        cityId: result.city,
        type: result.type != null
            ? PropertyType.values.firstWhere(
                (type) => type.toString().split('.').last == result.type,
                orElse: () => PropertyType.apartment,
              )
            : null,
        status: result.propertyType == 'بيع'
            ? PropertyStatus.forSale
            : result.propertyType == 'إيجار'
                ? PropertyStatus.forRent
                : null,
        minPrice: result.minPrice,
        maxPrice: result.maxPrice,
      );
    }
  }

  // التحقق من عرض طبقة الانضمام كبائع
  Future<void> _checkSellerOverlay() async {
    // تحقق ما إذا كان المستخدم قد رأى الطبقة من قبل
    bool shouldShow = await BecomeSellerOverlayHelper.shouldShowOverlay();

    if (shouldShow && mounted) {
      // التأخير قليلاً لضمان تحميل الشاشة الرئيسية أولاً
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showSellerOverlay = true;
          });
        }
      });
    }
  }

  // إغلاق طبقة الانضمام كبائع
  void _dismissSellerOverlay() {
    setState(() {
      _showSellerOverlay = false;
    });

    // تسجيل أن المستخدم قد رأى الطبقة
    BecomeSellerOverlayHelper.markOverlayAsSeen();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Stack(
      children: [
        // الشاشة الرئيسية الأصلية
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // ترويسة مدمجة مع شريط البحث
                _buildCompactHeader(),

                // الفلاتر السريعة
                _buildQuickFilters(),

                // محتوى العقارات (الجزء الأكبر)
                Expanded(
                  child: Consumer<PropertyProvider>(
                    builder: (context, propertyProvider, child) {
                      if (propertyProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (propertyProvider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 36, color: Colors.red),
                              const SizedBox(height: 8),
                              Text(
                                localizations.translate('error_occurred') +
                                    ': ${propertyProvider.error}',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () =>
                                    propertyProvider.fetchProperties(),
                                child: Text(localizations.translate('retry')),
                              ),
                            ],
                          ),
                        );
                      }

                      final propertiesForSale = propertyProvider.properties
                          .where((p) => p.status == PropertyStatus.forSale)
                          .toList();

                      final propertiesForRent = propertyProvider.properties
                          .where((p) => p.status == PropertyStatus.forRent)
                          .toList();

                      if (propertiesForSale.isEmpty &&
                          propertiesForRent.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                localizations
                                    .translate('no_properties_available'),
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // قسم العقارات للبيع
                          _buildSectionHeader(
                            localizations.translate('properties_for_sale'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PropertyListScreen(
                                    title: localizations
                                        .translate('properties_for_sale'),
                                    status: PropertyStatus.forSale,
                                  ),
                                ),
                              );
                            },
                          ),

                          if (propertiesForSale.isEmpty)
                            _buildEmptySection(localizations
                                .translate('no_matching_properties_sale'))
                          else
                            _buildPropertyGrid(
                                propertiesForSale.take(6).toList(),
                                maxHeight: 400),

                          const SizedBox(height: 24),

                          // قسم العقارات للإيجار
                          _buildSectionHeader(
                            localizations.translate('properties_for_rent'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PropertyListScreen(
                                    title: localizations
                                        .translate('properties_for_rent'),
                                    status: PropertyStatus.forRent,
                                  ),
                                ),
                              );
                            },
                          ),

                          if (propertiesForRent.isEmpty)
                            _buildEmptySection(localizations
                                .translate('no_matching_properties_rent'))
                          else
                            _buildPropertyGrid(
                                propertiesForRent.take(6).toList(),
                                maxHeight: 400),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // طبقة الانضمام كبائع
        if (_showSellerOverlay)
          BecomeSellerOverlay(
            onDismiss: _dismissSellerOverlay,
          ),
      ],
    );
  }

  Widget _buildCompactHeader() {
    final localizations = AppLocalizations.of(context);

    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.currentUser;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user != null
                            ? localizations
                                .translate('welcome_user')
                                .replaceAll('{name}', user.name)
                            : localizations.translate('welcome_guest'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.translate('search_ideal_property'),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      if (user == null) {
                        Navigator.pushNamed(context, '/login');
                      } else {
                        Navigator.pushNamed(context, '/profile');
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        user != null ? Icons.person : Icons.login,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    hintText: localizations.translate('search_properties'),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.filter_list, size: 20),
                      onPressed: _showFilterDialog,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      final propertyProvider =
                          Provider.of<PropertyProvider>(context, listen: false);
                      propertyProvider.searchProperties(value);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickFilters() {
    final localizations = AppLocalizations.of(context);

    // تحويل خريطة الفلاتر لاستخدام المفاتيح المترجمة
    final filterMap = {
      'all': null,
      'house': PropertyType.house,
      'villa': PropertyType.villa,
      'apartment': PropertyType.apartment,
      'store': PropertyType.store,
      'hall': PropertyType.hall,
      'studio': PropertyType.studio,
      'land': PropertyType.land,
      'other': PropertyType.other,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: filterMap.entries.map((entry) {
          final filterKey = entry.key;
          final filterType = entry.value;
          final isSelected = filterKey == _selectedFilter;

          // استخدام المفاتيح المترجمة
          String filterText = filterKey == 'all'
              ? localizations.translate('all')
              : localizations.translate('property_type_$filterKey');

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(filterText),
              selected: isSelected,
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (selected) {
                if (selected) {
                  _applyFilter(filterKey);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onTap}) {
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Row(
              children: [
                Text(localizations.translate('see_all')),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildPropertyGrid(List<PropertyModel> properties,
      {double? maxHeight}) {
    return SizedBox(
      height: maxHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
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
      ),
    );
  }
}
