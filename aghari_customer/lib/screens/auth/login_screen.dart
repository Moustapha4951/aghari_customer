import '../../screens/auth/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../localization/app_localizations.dart';
import '../../providers/property_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  void _login(BuildContext context) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = _formKey.currentState!.value;

      try {
        print('🔑 محاولة تسجيل الدخول: ${data['phone']}');

        final userData = await _authService.login(
          data['phone'],
          data['password'],
        );

        if (mounted && userData != null) {
          try {
            print('✅ تم تسجيل الدخول بنجاح! معرف المستخدم: ${userData['id']}');

            final userProvider =
                Provider.of<UserProvider>(context, listen: false);

            // تعيين المستخدم الحالي في مزود المستخدم
            await userProvider.setCurrentUser(userData); // Added await
            print('✅ تم تعيين المستخدم في UserProvider');

            // Add a very short delay to allow the notification to propagate
            await Future.delayed(const Duration(milliseconds: 100));

            // مشاركة معرف المستخدم مع المزودين الآخرين بشكل آمن
            try {
              print('🔄 مشاركة معرف المستخدم مع المزودين الآخرين...');
              userProvider.setUserIdInProviders(context);

              // تحميل المفضلات مباشرة
              final propertyProvider =
                  Provider.of<PropertyProvider>(context, listen: false);
              print('🔄 تحميل المفضلات بعد تسجيل الدخول...');
              await propertyProvider.forceReloadFavorites(userData['id']);
              print('✅ تم تحميل المفضلات بنجاح');
            } catch (e) {
              print('⚠️ خطأ في مشاركة معرف المستخدم أو تحميل المفضلات: $e');
              // الاستمرار في العملية رغم الخطأ
            }

            // التحقق من شاشة الترحيب
            final prefs = await SharedPreferences.getInstance();
            final isFirstLogin = !(prefs.getBool('has_seen_welcome') ?? false);

            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (isFirstLogin) {
                  Navigator.pushReplacementNamed(context, '/welcome');
                } else {
                  // Pass userData as arguments
                  Navigator.pushReplacementNamed(context, '/main', arguments: userData);
                }
              });
            }
          } catch (e) {
            print('❌ خطأ في معالجة تسجيل الدخول: $e');
            // في حالة حدوث خطأ، انتقل إلى الشاشة الرئيسية
            if (mounted) { // Ensure mounted check here too for safety
                WidgetsBinding.instance.addPostFrameCallback((_) {
                    // Do not pass arguments on error, as userData might be null or incomplete
                    Navigator.pushReplacementNamed(context, '/main');
                });
            }
          }
        } else {
          throw 'فشل تسجيل الدخول: البيانات فارغة';
        }
      } catch (e) {
        print('❌ خطأ في تسجيل الدخول: $e');
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Image.asset(
                    'assets/images/aghari.png',
                    height: 120,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    localizations.translate('welcome'),
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate('login_description'),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
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
                  FormBuilderTextField(
                    name: 'phone',
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: localizations.translate('phone'),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: localizations.translate('phone_required')),
                      FormBuilderValidators.numeric(
                          errorText: localizations.translate('phone_numeric')),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'password',
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: localizations.translate('password'),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: FormBuilderValidators.required(
                        errorText:
                            localizations.translate('password_required')),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _login(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(localizations.translate('login')),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen()));
                        },
                        child: Text(localizations.translate('forgot_password')),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.pushNamed(context, '/register'),
                    child: Text(localizations.translate('no_account')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
