import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../../models/property_model.dart';
import '../../providers/property_provider.dart';
import '../../providers/user_provider.dart';
import '../../localization/app_localizations.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({Key? key}) : super(key: key);

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final List<File> _selectedImages = [];
  String? _selectedCityId;
  bool _isLoading = false;
  String? _errorMessage;
  String _loadingMessage = '';
  double _uploadProgress = 0.0;

  // نموذج البيانات
  PropertyType _propertyType = PropertyType.apartment;
  PropertyStatus _propertyStatus = PropertyStatus.forSale;
  bool _hasPool = false;
  bool _hasGarden = false;
  final Map<String, bool> _features = {
    'furnished': false,
    'parking': false,
    'security': false,
    'airConditioning': false,
  };

  // المدن المتاحة
  List<Map<String, String>> _cities = [];

  // أسماء أنواع العقارات
  String _getPropertyTypeName(PropertyType type) {
    final localizations = AppLocalizations.of(context);

    switch (type) {
      case PropertyType.house:
        return localizations.translate('property_type_house');
      case PropertyType.villa:
        return localizations.translate('property_type_villa');
      case PropertyType.apartment:
        return localizations.translate('property_type_apartment');
      case PropertyType.store:
        return localizations.translate('property_type_store');
      case PropertyType.hall:
        return localizations.translate('property_type_hall');
      case PropertyType.studio:
        return localizations.translate('property_type_studio');
      case PropertyType.land:
        return localizations.translate('property_type_land');
      case PropertyType.other:
        return localizations.translate('property_type_other');
      default:
        return localizations.translate('property_type_unknown');
    }
  }

  @override
  void initState() {
    super.initState();
    _initCities();
  }

  // تهيئة قائمة المدن باستخدام الترجمات
  void _initCities() {
    // سيتم استدعاء هذه الدالة في الـ didChangeDependencies لضمان توفر السياق
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final localizations = AppLocalizations.of(context);
    _cities = [
      {'id': 'nouakchott', 'name': localizations.translate('city_nouakchott')},
      {'id': 'nouadhibou', 'name': localizations.translate('city_nouadhibou')},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('add_property')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FormBuilder(
          key: _formKey,
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value:
                                  _uploadProgress > 0 ? _uploadProgress : null,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          if (_uploadProgress > 0)
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _loadingMessage.isNotEmpty
                            ? _loadingMessage
                            : localizations
                                .translate('uploading_property_images'),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        localizations.translate('please_wait_upload'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // صور العقار
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.translate('property_images'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            if (_selectedImages.isNotEmpty)
                              SizedBox(
                                height: 120,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImages.length + 1,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    if (index == _selectedImages.length) {
                                      return _buildAddImageButton();
                                    }
                                    return _buildImagePreview(index);
                                  },
                                ),
                              )
                            else
                              _buildAddImageButton(),
                          ],
                        ),
                      ),
                    ),

                    // معلومات العقار الأساسية
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.translate('basic_information'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            FormBuilderTextField(
                              name: 'title',
                              decoration: InputDecoration(
                                labelText:
                                    localizations.translate('property_title'),
                                hintText: localizations
                                    .translate('property_title_hint'),
                                prefixIcon: Icon(Icons.title),
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(
                                    errorText: localizations
                                        .translate('property_title_required')),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            FormBuilderTextField(
                              name: 'description',
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: localizations
                                    .translate('property_description'),
                                hintText: localizations
                                    .translate('property_description_hint'),
                                prefixIcon: Icon(Icons.description),
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(
                                    errorText: localizations.translate(
                                        'property_description_required')),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            FormBuilderTextField(
                              name: 'address',
                              decoration: InputDecoration(
                                labelText: localizations.translate('address'),
                                hintText:
                                    localizations.translate('address_hint'),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(
                                    errorText: localizations
                                        .translate('address_required')),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderDropdown<String>(
                                    name: 'city',
                                    decoration: InputDecoration(
                                      labelText:
                                          localizations.translate('city'),
                                      prefixIcon: Icon(Icons.location_city),
                                    ),
                                    items: _cities.map((city) {
                                      return DropdownMenuItem(
                                        value: city['id'],
                                        child: Text(city['name']!),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCityId = value;
                                      });
                                    },
                                    validator: FormBuilderValidators.required(
                                      errorText: localizations
                                          .translate('city_required'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // حقل إدخال اسم الحي مباشرة
                            FormBuilderTextField(
                              name: 'districtName',
                              decoration: InputDecoration(
                                labelText: localizations.translate('district'),
                                hintText: localizations
                                    .translate('district_name_hint'),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(
                                    errorText: localizations
                                        .translate('district_name_required')),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            FormBuilderRadioGroup<String>(
                              name: 'type',
                              decoration: InputDecoration(
                                labelText:
                                    localizations.translate('property_type'),
                              ),
                              options: PropertyType.values.map((type) {
                                return FormBuilderFieldOption<String>(
                                  value: type.toString().split('.').last,
                                  child: Text(_getPropertyTypeName(type)),
                                );
                              }).toList(),
                              initialValue:
                                  _propertyType.toString().split('.').last,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _propertyType = PropertyType.values
                                        .firstWhere((type) =>
                                            type.toString().split('.').last ==
                                            value);
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            FormBuilderRadioGroup<String>(
                              name: 'status',
                              decoration: InputDecoration(
                                labelText:
                                    localizations.translate('property_status'),
                              ),
                              options: [
                                FormBuilderFieldOption(
                                  value: 'forSale',
                                  child: Row(
                                    children: [
                                      Icon(Icons.sell,
                                          color:
                                              Theme.of(context).primaryColor),
                                      const SizedBox(width: 8),
                                      Text(localizations
                                          .translate('property_status_sale')),
                                    ],
                                  ),
                                ),
                                FormBuilderFieldOption(
                                  value: 'forRent',
                                  child: Row(
                                    children: [
                                      Icon(Icons.home,
                                          color:
                                              Theme.of(context).primaryColor),
                                      const SizedBox(width: 8),
                                      Text(localizations
                                          .translate('property_status_rent')),
                                    ],
                                  ),
                                ),
                              ],
                              initialValue:
                                  _propertyStatus.toString().split('.').last,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _propertyStatus = PropertyStatus.values
                                        .firstWhere((status) =>
                                            status.toString().split('.').last ==
                                            value);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // تفاصيل العقار
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.translate('property_details'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'price',
                                    decoration: InputDecoration(
                                      labelText:
                                          localizations.translate('price'),
                                      prefixIcon: Icon(Icons.monetization_on),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(
                                          errorText: localizations
                                              .translate('price_required')),
                                      FormBuilderValidators.numeric(
                                          errorText: localizations
                                              .translate('numeric_value')),
                                    ]),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'area',
                                    decoration: InputDecoration(
                                      labelText: localizations
                                          .translate('property_area'),
                                      prefixIcon: Icon(Icons.square_foot),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(
                                          errorText: localizations
                                              .translate('area_required')),
                                      FormBuilderValidators.numeric(
                                          errorText: localizations
                                              .translate('numeric_value')),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'rooms',
                                    decoration: InputDecoration(
                                      labelText:
                                          localizations.translate('rooms'),
                                      prefixIcon: Icon(Icons.bedroom_parent),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(
                                          errorText: localizations
                                              .translate('rooms_required')),
                                      FormBuilderValidators.numeric(
                                          errorText: localizations
                                              .translate('numeric_value')),
                                    ]),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'bathrooms',
                                    decoration: InputDecoration(
                                      labelText: localizations
                                          .translate('bathrooms_count'),
                                      prefixIcon: Icon(Icons.bathroom),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(
                                          errorText: localizations
                                              .translate('bathrooms_required')),
                                      FormBuilderValidators.numeric(
                                          errorText: localizations
                                              .translate('numeric_value')),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'parking',
                                    decoration: InputDecoration(
                                      labelText: localizations
                                          .translate('parking_spaces'),
                                      prefixIcon: Icon(Icons.car_rental),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.numeric(
                                          errorText: localizations
                                              .translate('numeric_value')),
                                    ]),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'floors',
                                    decoration: InputDecoration(
                                      labelText:
                                          localizations.translate('floors'),
                                      prefixIcon: Icon(Icons.layers),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.numeric(
                                          errorText: localizations
                                              .translate('numeric_value')),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    title:
                                        Text(localizations.translate('pool')),
                                    value: _hasPool,
                                    onChanged: (val) {
                                      setState(() {
                                        _hasPool = val ?? false;
                                      });
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                ),
                                Expanded(
                                  child: CheckboxListTile(
                                    title:
                                        Text(localizations.translate('garden')),
                                    value: _hasGarden,
                                    onChanged: (val) {
                                      setState(() {
                                        _hasGarden = val ?? false;
                                      });
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ميزات العقار
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.translate('additional_features'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 0,
                              children: [
                                _buildFeatureCheckbox(
                                    'furnished', 'furnished', Icons.chair),
                                _buildFeatureCheckbox(
                                    'parking', 'parking', Icons.car_rental),
                                _buildFeatureCheckbox(
                                    'security', 'security', Icons.security),
                                _buildFeatureCheckbox('air_conditioning',
                                    'airConditioning', Icons.ac_unit),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // معلومات الاتصال
                    Card(
                      margin: const EdgeInsets.only(bottom: 32),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.translate('contact_information'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            FormBuilderTextField(
                              name: 'phone',
                              decoration: InputDecoration(
                                labelText:
                                    localizations.translate('contact_phone'),
                                hintText: localizations
                                    .translate('contact_phone_hint'),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                              initialValue: Provider.of<UserProvider>(context,
                                      listen: false)
                                  .currentUser
                                  ?.phone,
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // زر الحفظ
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveProperty,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save),
                                SizedBox(width: 8),
                                Text(
                                  localizations.translate('save_property'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          onPressed: _savePropertyWithoutImages,
                          icon: Icon(Icons.add_circle_outline),
                          tooltip: "إضافة بدون صور (للاختبار)",
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
        ),
      ),
    );
  }

  // بناء مربع اختيار للميزة
  Widget _buildFeatureCheckbox(String title, String key, IconData icon) {
    final localizations = AppLocalizations.of(context);

    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: CheckboxListTile(
        title: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(localizations.translate(title)),
          ],
        ),
        value: _features[key],
        onChanged: (val) {
          setState(() {
            _features[key] = val ?? false;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      ),
    );
  }

  // زر إضافة صورة
  Widget _buildAddImageButton() {
    final localizations = AppLocalizations.of(context);

    return InkWell(
      onTap: _pickImages,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              localizations.translate('add_images'),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // معاينة الصورة
  Widget _buildImagePreview(int index) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(_selectedImages[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // اختيار الصور
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();

    try {
      final List<XFile> pickedImages = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedImages.isNotEmpty) {
        setState(() {
          // تحديد عدد الصور المسموح به (5 صور كحد أقصى)
          int availableSlots = 5 - _selectedImages.length;
          int imagesToAdd = pickedImages.length > availableSlots
              ? availableSlots
              : pickedImages.length;

          for (int i = 0; i < imagesToAdd; i++) {
            _selectedImages.add(File(pickedImages[i].path));
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء اختيار الصور: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // إزالة صورة
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // حفظ العقار
  void _saveProperty() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final localizations = AppLocalizations.of(context);

      // التحقق من اختيار المدينة والحي
      if (formData['city'] == null) {
        setState(() {
          _errorMessage = localizations.translate('please_select_city');
        });
        return;
      }

      // التحقق من إضافة صورة واحدة على الأقل
      if (_selectedImages.isEmpty) {
        setState(() {
          _errorMessage =
              localizations.translate('please_add_at_least_one_image');
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _uploadProgress = 0.0;
        _loadingMessage = localizations.translate('preparing_to_upload');
      });

      try {
        // الحصول على بيانات المستخدم والمزود
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final propertyProvider =
            Provider.of<PropertyProvider>(context, listen: false);
        final user = userProvider.currentUser;

        if (user == null) {
          throw Exception('يجب تسجيل الدخول أولاً');
        }

        print('=== بدء إضافة عقار جديد ===');
        print('معرف المستخدم: ${user.id}');
        print('اسم المستخدم: ${user.name}');
        print('الصور: ${_selectedImages.length}');

        setState(() {
          _loadingMessage = localizations.translate('creating_property');
          _uploadProgress = 0.1; // 10% للإعداد
        });

        // التحقق من الصور قبل الرفع
        for (int i = 0; i < _selectedImages.length; i++) {
          if (!await _selectedImages[i].exists()) {
            print(
                'تحذير: الصورة ${i + 1} غير موجودة: ${_selectedImages[i].path}');
            setState(() {
              _errorMessage = 'الصورة ${i + 1} غير موجودة';
            });
            return;
          }

          final fileSize = await _selectedImages[i].length();
          print(
              'حجم الصورة ${i + 1}: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} ميجابايت');
        }

        // إنشاء كائن العقار
        final property = PropertyModel(
          id: '',
          title: formData['title'],
          description: formData['description'],
          address: formData['address'] ?? '',
          type: _propertyType,
          status: _propertyStatus,
          price: double.parse(formData['price']?.toString() ?? '0'),
          area: double.parse(formData['area']?.toString() ?? '0'),
          bedrooms: int.parse(formData['rooms']?.toString() ?? '0'),
          bathrooms: int.parse(formData['bathrooms']?.toString() ?? '0'),
          parkingSpaces: int.parse(formData['parking']?.toString() ?? '0'),
          floors: int.parse(formData['floors']?.toString() ?? '0'),
          hasPool: _hasPool,
          hasGarden: _hasGarden,
          cityId: formData['city'] ?? '',
          districtId: null, // لم نعد نستخدم معرف الحي
          districtName: formData['districtName'] ?? '',
          images: [],
          features: _features,
          ownerId: user.id,
          ownerName: user.name,
          ownerPhone: formData['phone'] ?? user.phone,
          districtDocument: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          favoriteUserIds: [],
        );

        print('تم إنشاء كائن العقار: ${property.title}');

        // تعيين معرف المستخدم في مزود العقارات
        propertyProvider.currentUserId = user.id;

        setState(() {
          _loadingMessage =
              localizations.translate('uploading_property_images');
          _uploadProgress = 0.3; // 30% بعد إنشاء العقار
        });

        // محاولة حفظ العقار ورفع الصور (الآن تستخدم الطريقة المحسنة)
        print('بدء رفع العقار والصور...');
        final propertyId =
            await propertyProvider.addProperty(property, _selectedImages);
        print('اكتمل رفع العقار بمعرف: $propertyId');

        // تحديث التقدم مع انتهاء العملية
        setState(() {
          _uploadProgress = 1.0;
          _loadingMessage =
              localizations.translate('property_saved_successfully');
        });

        // انتظار لعرض اكتمال العملية قبل إظهار رسالة النجاح
        await Future.delayed(Duration(milliseconds: 800));

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (propertyId != null) {
            print('تم إضافة العقار بنجاح برقم: $propertyId');
            // عرض مربع حوار نجاح إضافة العقار مع توضيح أنه قيد المراجعة
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: Text(
                    localizations.translate('property_added_successfully')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 50),
                    SizedBox(height: 16),
                    Text(
                      localizations.translate('property_pending_review'),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      localizations
                          .translate('property_will_be_visible_after_approval'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                    },
                    child: Text(localizations.translate('ok')),
                  ),
                ],
              ),
            );
          } else {
            print('فشل إضافة العقار: معرف العقار فارغ');
            setState(() {
              _errorMessage = localizations.translate('error_adding_property');
            });
          }
        }
      } catch (e) {
        print('خطأ في حفظ العقار: $e');
        print('نوع الخطأ: ${e.runtimeType}');
        print('تفاصيل الخطأ: ${e.toString()}');

        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                localizations.translate('error_occurred') + ': ${e.toString()}';
          });
        }
      }
    }
  }

  // إضافة عقار بدون صور (للاختبار فقط)
  void _savePropertyWithoutImages() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final localizations = AppLocalizations.of(context);

      // التحقق من اختيار المدينة والحي
      if (formData['city'] == null) {
        setState(() {
          _errorMessage = localizations.translate('please_select_city');
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _uploadProgress = 0.0;
        _loadingMessage = localizations.translate('preparing_to_upload');
      });

      try {
        // الحصول على بيانات المستخدم والمزود
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final propertyProvider =
            Provider.of<PropertyProvider>(context, listen: false);
        final user = userProvider.currentUser;

        if (user == null) {
          throw Exception('يجب تسجيل الدخول أولاً');
        }

        print('=== بدء إضافة عقار جديد بدون صور (اختبار) ===');
        print('معرف المستخدم: ${user.id}');
        print('اسم المستخدم: ${user.name}');

        setState(() {
          _loadingMessage = localizations.translate('creating_property');
          _uploadProgress = 0.3; // 30% للإعداد
        });

        // إنشاء كائن العقار
        final property = PropertyModel(
          id: '',
          title: formData['title'],
          description: formData['description'],
          address: formData['address'] ?? '',
          type: _propertyType,
          status: _propertyStatus,
          price: double.parse(formData['price']?.toString() ?? '0'),
          area: double.parse(formData['area']?.toString() ?? '0'),
          bedrooms: int.parse(formData['rooms']?.toString() ?? '0'),
          bathrooms: int.parse(formData['bathrooms']?.toString() ?? '0'),
          parkingSpaces: int.parse(formData['parking']?.toString() ?? '0'),
          floors: int.parse(formData['floors']?.toString() ?? '0'),
          hasPool: _hasPool,
          hasGarden: _hasGarden,
          cityId: formData['city'] ?? '',
          districtId: null,
          districtName: formData['districtName'] ?? '',
          images: [],
          features: _features,
          ownerId: user.id,
          ownerName: user.name,
          ownerPhone: formData['phone'] ?? user.phone,
          districtDocument: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          favoriteUserIds: [],
        );

        print('تم إنشاء كائن العقار: ${property.title}');

        // تعيين معرف المستخدم في مزود العقارات
        propertyProvider.currentUserId = user.id;

        setState(() {
          _loadingMessage = "إضافة العقار بدون صور...";
          _uploadProgress = 0.5;
        });

        // استخدام الطريقة المبسطة بدون صور
        print('بدء إضافة العقار بدون صور...');
        final propertyId = await propertyProvider.addPropertySimple(property);
        print('اكتمل إضافة العقار بدون صور بمعرف: $propertyId');

        // تحديث التقدم مع انتهاء العملية
        setState(() {
          _uploadProgress = 1.0;
          _loadingMessage =
              localizations.translate('property_saved_successfully');
        });

        // انتظار لعرض اكتمال العملية قبل إظهار رسالة النجاح
        await Future.delayed(Duration(milliseconds: 800));

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (propertyId != null) {
            print('تم إضافة العقار بدون صور بنجاح برقم: $propertyId');

            // عرض مربع حوار نجاح إضافة العقار مع توضيح أنه قيد المراجعة
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: Text('تم إضافة العقار بنجاح (بدون صور)'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 50),
                    SizedBox(height: 16),
                    Text(
                      localizations.translate('property_pending_review'),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "تم إضافة العقار بنجاح بدون صور لأغراض الاختبار. المعرف: $propertyId",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                    },
                    child: Text(localizations.translate('ok')),
                  ),
                ],
              ),
            );
          } else {
            print('فشل إضافة العقار: معرف العقار فارغ');
            setState(() {
              _errorMessage = localizations.translate('error_adding_property');
            });
          }
        }
      } catch (e) {
        print('خطأ في حفظ العقار بدون صور: $e');
        print('نوع الخطأ: ${e.runtimeType}');
        print('تفاصيل الخطأ: ${e.toString()}');

        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'حدث خطأ أثناء إضافة العقار بدون صور: ${e.toString()}';
          });
        }
      }
    }
  }
}
