import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../models/property_model.dart';
import '../../models/property_request_model.dart';
import '../../services/property_request_service.dart';
import '../../providers/user_provider.dart';
import '../../localization/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestPropertyScreen extends StatefulWidget {
  const RequestPropertyScreen({Key? key}) : super(key: key);

  @override
  State<RequestPropertyScreen> createState() => _RequestPropertyScreenState();
}

class _RequestPropertyScreenState extends State<RequestPropertyScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final PropertyRequestService _requestService = PropertyRequestService();
  bool _isLoading = false;
  final TextEditingController _phoneController = TextEditingController();

  // إضافة متغير لحالة العقار
  PropertyStatus _propertyStatus = PropertyStatus.forSale;

  // تعديل إعلان _propertyTypes ليكون خالياً عند التعريف
  // ثم تعبئته في دالة initState

  final List<String> _propertyTypes =
      []; // قائمة فارغة بدلاً من القائمة المترجمة مباشرة

  // المدن ستكون ديناميكية
  List<String> _cities = [];
  String? _selectedCity;

  @override
  void initState() {
    super.initState();

    // استرجاع رقم الهاتف من المستخدم إذا كان متاحاً
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      _phoneController.text = userProvider.user.phone;
    }

    // تحميل المدن من قاعدة البيانات
    _loadCities();

    // تعبئة قائمة أنواع العقارات المترجمة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localizations = AppLocalizations.of(context);
      setState(() {
        _propertyTypes.addAll([
          localizations.translate('property_type_house'),
          localizations.translate('property_type_villa'),
          localizations.translate('property_type_apartment'),
          localizations.translate('property_type_store'),
          localizations.translate('property_type_hall'),
          localizations.translate('property_type_studio'),
          localizations.translate('property_type_land'),
          localizations.translate('property_type_other'),
        ]);
      });
    });
  }

  Future<void> _loadCities() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final localizations = AppLocalizations.of(context);

      // جلب المدن من Firestore
      final citiesSnapshot = await FirebaseFirestore.instance
          .collection('cities')
          .orderBy('name')
          .get();

      final List<String> cityList = [];
      final Map<String, String> cityTranslations = {
        'nouakchott': localizations.translate('city_nouakchott'),
        'nouadhibou': localizations.translate('city_nouadhibou'),
      };

      for (var doc in citiesSnapshot.docs) {
        // التحقق مما إذا كان اسم المدينة له ترجمة متوفرة
        final cityId = doc.id.toLowerCase();
        final cityName = cityTranslations.containsKey(cityId)
            ? cityTranslations[cityId]
            : doc['name'];
        cityList.add(cityName!);
      }

      setState(() {
        _cities = cityList;
        // إذا كانت القائمة فارغة، إضافة مدن افتراضية
        if (_cities.isEmpty) {
          _cities = [
            localizations.translate('city_nouakchott'),
            localizations.translate('city_nouadhibou')
          ];
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('خطأ في تحميل المدن: $e');
      final localizations = AppLocalizations.of(context);
      setState(() {
        _cities = [
          localizations.translate('city_nouakchott'),
          localizations.translate('city_nouadhibou')
        ];
        _isLoading = false;
      });
    }
  }



  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final localizations = AppLocalizations.of(context);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.user == null) {
          throw localizations.translate('login_required');
        }

        final formData = _formKey.currentState!.value;

        // إنشاء نموذج طلب عقار
        final propertyRequest = PropertyRequestModel(
          userId: userProvider.user.id,
          userName: userProvider.user.name,
          phone: _phoneController.text,
          propertyType: formData['propertyType'],
          propertyStatus: _propertyStatus,
          city: formData['city'],
          district: formData['district'],
          minPrice: formData['minPrice'] != null
              ? double.tryParse(formData['minPrice'].toString())
              : null,
          maxPrice: formData['maxPrice'] != null
              ? double.tryParse(formData['maxPrice'].toString())
              : null,
          minSpace: formData['minSpace'] != null
              ? double.tryParse(formData['minSpace'].toString())
              : null,
          maxSpace: formData['maxSpace'] != null
              ? double.tryParse(formData['maxSpace'].toString())
              : null,
          bedrooms: formData['bedrooms'] != null
              ? int.tryParse(formData['bedrooms'].toString())
              : null,
          bathrooms: formData['bathrooms'] != null
              ? int.tryParse(formData['bathrooms'].toString())
              : null,
          additionalDetails: formData['additionalDetails'],
          status: RequestStatus.pending,
          createdAt: DateTime.now(),
        );

        // إرسال الطلب إلى Firestore
        await _requestService.addPropertyRequest(propertyRequest);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  localizations.translate('request_submitted_successfully')),
              backgroundColor: Colors.green,
            ),
          );

          // التحقق من المعلومات المرسلة مع الانتقال للتعرف على مصدر الانتقال
          final routeArgs = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final fromWelcome = routeArgs?['from_welcome'] == true;

          if (fromWelcome) {
            // إذا كان المستخدم قادمًا من شاشة الترحيب، ننتقل إلى الشاشة الرئيسية
            Navigator.pushNamedAndRemoveUntil(
                context, '/main', (route) => false);
          } else {
            // وإلا نعود إلى الشاشة السابقة (البروفايل)
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('request_property')),
        centerTitle: true,
      ),
      body: _isLoading && _cities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان النموذج
                    Center(
                      child: Text(
                        localizations.translate('request_property_description'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // نوع العقار
                    FormBuilderDropdown<String>(
                      name: 'propertyType',
                      decoration: InputDecoration(
                        labelText: localizations.translate('property_type'),
                        hintText:
                            localizations.translate('select_property_type'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        prefixIcon: const Icon(Icons.home),
                      ),
                      items: _propertyTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      validator: FormBuilderValidators.required(
                        errorText:
                            localizations.translate('property_type_required'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // إضافة خيار حالة العقار (بيع/إيجار)
                    Text(
                      localizations.translate('property_status'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _propertyStatus == PropertyStatus.forSale
                              ? localizations.translate('property_status_sale')
                              : localizations.translate('property_status_rent'),
                        ),
                        const SizedBox(width: 16),
                        Switch(
                          value: _propertyStatus == PropertyStatus.forRent,
                          onChanged: (value) {
                            setState(() {
                              _propertyStatus = value
                                  ? PropertyStatus.forRent
                                  : PropertyStatus.forSale;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // المدينة
                    FormBuilderDropdown<String>(
                      name: 'city',
                      decoration: InputDecoration(
                        labelText: localizations.translate('city'),
                        hintText: localizations.translate('select_city'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        prefixIcon: const Icon(Icons.location_city),
                      ),
                      items: _cities
                          .map((city) => DropdownMenuItem(
                                value: city,
                                child: Text(city),
                              ))
                          .toList(),
                      validator: FormBuilderValidators.required(
                        errorText: localizations.translate('city_required'),
                      ),
                      onChanged: (value) {
                        if (value != null && value != _selectedCity) {
                          setState(() {
                            _selectedCity = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // إدخال اسم الحي
                    FormBuilderTextField(
                      name: 'district',
                      decoration: InputDecoration(
                        labelText: localizations.translate('district'),
                        hintText: localizations.translate('enter_district'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      validator: FormBuilderValidators.required(
                        errorText: localizations.translate('district_required'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // رقم الهاتف
                    FormBuilderTextField(
                      name: 'phone',
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('phone'),
                        hintText: localizations.translate('enter_phone'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: localizations.translate('phone_required'),
                        ),
                        FormBuilderValidators.numeric(
                          errorText: localizations.translate('phone_numeric'),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // نطاق السعر
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
                          child: FormBuilderTextField(
                            name: 'minPrice',
                            decoration: InputDecoration(
                              labelText: localizations.translate('min_price'),
                              hintText:
                                  localizations.translate('min_price_hint'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              prefixIcon: const Icon(Icons.money),
                              suffixText: localizations.translate('currency'),
                            ),
                            keyboardType: TextInputType.number,
                            validator: FormBuilderValidators.numeric(
                              errorText: localizations
                                  .translate('numeric_value_required'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'maxPrice',
                            decoration: InputDecoration(
                              labelText: localizations.translate('max_price'),
                              hintText:
                                  localizations.translate('max_price_hint'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              prefixIcon: const Icon(Icons.money),
                              suffixText: localizations.translate('currency'),
                            ),
                            keyboardType: TextInputType.number,
                            validator: FormBuilderValidators.numeric(
                              errorText: localizations
                                  .translate('numeric_value_required'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // نطاق المساحة
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'minSpace',
                            decoration: InputDecoration(
                              labelText: localizations.translate('min_area'),
                              hintText:
                                  localizations.translate('min_area_hint'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              prefixIcon: const Icon(Icons.square_foot),
                              suffixText: localizations.translate('area_unit'),
                            ),
                            keyboardType: TextInputType.number,
                            validator: FormBuilderValidators.numeric(
                              errorText: localizations
                                  .translate('numeric_value_required'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'maxSpace',
                            decoration: InputDecoration(
                              labelText: localizations.translate('max_area'),
                              hintText:
                                  localizations.translate('max_area_hint'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              prefixIcon: const Icon(Icons.square_foot),
                              suffixText: localizations.translate('area_unit'),
                            ),
                            keyboardType: TextInputType.number,
                            validator: FormBuilderValidators.numeric(
                              errorText: localizations
                                  .translate('numeric_value_required'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // غرف النوم والحمامات
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'bedrooms',
                            decoration: InputDecoration(
                              labelText: localizations.translate('bedrooms'),
                              hintText:
                                  localizations.translate('bedrooms_count'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              prefixIcon: const Icon(Icons.bed),
                            ),
                            keyboardType: TextInputType.number,
                            validator: FormBuilderValidators.numeric(
                              errorText: localizations
                                  .translate('numeric_value_required'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: 'bathrooms',
                            decoration: InputDecoration(
                              labelText: localizations.translate('bathrooms'),
                              hintText:
                                  localizations.translate('bathrooms_count'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              prefixIcon: const Icon(Icons.bathtub),
                            ),
                            keyboardType: TextInputType.number,
                            validator: FormBuilderValidators.numeric(
                              errorText: localizations
                                  .translate('numeric_value_required'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // تفاصيل إضافية
                    FormBuilderTextField(
                      name: 'additionalDetails',
                      decoration: InputDecoration(
                        labelText:
                            localizations.translate('additional_details'),
                        hintText:
                            localizations.translate('additional_details_hint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        prefixIcon: const Icon(Icons.notes),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // زر الإرسال
                    CustomButton(
                      text: _isLoading
                          ? localizations.translate('sending')
                          : localizations.translate('send_request'),
                      onPressed: _isLoading ? null : _submitForm,
                      isLoading: _isLoading,
                      color: AppTheme.primaryColor,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
