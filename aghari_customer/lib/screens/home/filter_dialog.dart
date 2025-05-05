import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';

class PropertyFilter {
  final String? type;
  final double? minPrice;
  final double? maxPrice;
  final String? city;
  final String? propertyType;

  PropertyFilter({
    this.type,
    this.minPrice,
    this.maxPrice,
    this.city,
    this.propertyType,
  });
}

class FilterDialog extends StatefulWidget {
  final PropertyFilter? initialFilter;

  const FilterDialog({
    Key? key,
    this.initialFilter,
  }) : super(key: key);

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  String? _selectedCity;
  String? _selectedType;
  String? _selectedPropertyType;
  double? _minPrice;
  double? _maxPrice;

  final List<String> _cities = [
    'nouakchott',
    'nouadhibou',
  ];

  final List<String> _propertyTypes = [
    'apartment',
    'villa',
    'house',
    'store',
    'hall',
    'studio',
    'land',
    'other',
  ];

  final List<String> _dealTypes = [
    'sale',
    'rent',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    if (widget.initialFilter != null) {
      _selectedCity = widget.initialFilter!.city;
      _selectedType = widget.initialFilter!.type;
      _selectedPropertyType = widget.initialFilter!.propertyType;
      _minPrice = widget.initialFilter!.minPrice;
      _maxPrice = widget.initialFilter!.maxPrice;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.translate('filter_properties')),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // المدينة مع الترجمة
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: localizations.translate('city'),
                prefixIcon: const Icon(Icons.location_city),
              ),
              value: _selectedCity,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(localizations.translate('all')),
                ),
                ..._cities.map((city) => DropdownMenuItem<String>(
                      value: city,
                      child: Text(localizations.translate('city_$city')),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // نوع العقار مع الترجمة
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: localizations.translate('property_type'),
                prefixIcon: const Icon(Icons.category),
              ),
              value: _selectedType,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(localizations.translate('all')),
                ),
                ..._propertyTypes.map((type) => DropdownMenuItem<String>(
                      value: type,
                      child:
                          Text(localizations.translate('property_type_$type')),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // نوع المعاملة (بيع/إيجار) مع الترجمة
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: localizations.translate('deal_type'),
                prefixIcon: const Icon(Icons.real_estate_agent),
              ),
              value: _selectedPropertyType,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(localizations.translate('all')),
                ),
                ..._dealTypes.map((type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                          localizations.translate('property_status_$type')),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPropertyType = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // السعر
            Text(
              localizations.translate('price_range'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: localizations.translate('min_price'),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _minPrice?.toString(),
                    onChanged: (value) {
                      setState(() {
                        _minPrice =
                            value.isNotEmpty ? double.parse(value) : null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: localizations.translate('max_price'),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _maxPrice?.toString(),
                    onChanged: (value) {
                      setState(() {
                        _maxPrice =
                            value.isNotEmpty ? double.parse(value) : null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.translate('cancel')),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              PropertyFilter(
                city: _selectedCity,
                type: _selectedType,
                propertyType: _selectedPropertyType,
                minPrice: _minPrice,
                maxPrice: _maxPrice,
              ),
            );
          },
          child: Text(localizations.translate('apply')),
        ),
      ],
    );
  }
}
