import '../../screens/auth/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
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
            userProvider.setCurrentUser(userData);
            print('✅ تم تعيين المستخدم في UserProvider');

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
            // final isFirstLogin = !(prefs.getBool('has_seen_welcome') ?? false);

            // if (isFirstLogin && mounted) {
            //   Navigator.pushReplacementNamed(context, '/welcome');
            // } else {
            //   Navigator.pushReplacementNamed(context, '/main');
            // }
            // Automatically restart the app instead of navigating
            if (mounted) {
              Phoenix.rebirth(context);
            }
          } catch (e) {
            print('❌ خطأ في معالجة تسجيل الدخول: $e');
            // In case of an error during post-login processing,
            // it's safer to indicate an error rather than navigating to /main or /restart-prompt
            // For now, let's rethrow or show an error message if possible,
            // or fall back to login screen with error.
            // For simplicity in this step, we'll let the generic catch handle it.
            // if (mounted) Navigator.pushReplacementNamed(context, '/main'); // Original fallback
             if (mounted) {
setState(() {
                // Use a generic error message or e.toString() to avoid scope issue with 'localizations'
                _errorMessage = 'Error processing login: ${e.toString()}';
                _isLoading = false;
});
            }
          }
        } else {
          // Use AppLocalizations.of(context) if context is available and needed, or a generic string
          // For this catch block, a generic string is safer if localizations isn't easily accessible.
          final String genericLoginFailedError = "Login failed: User data is empty"; // Default
          // Attempt to get localized version if context were available, but it's not directly in this path.
          // So, we rely on the outer catch for localized messages from AuthService for now.
          throw genericLoginFailedError;
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

  void _loginAnonymously(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = await _authService.signInAnonymously();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setCurrentUser(userData);
      userProvider.setUserIdInProviders(context);

      // For anonymous login, no need to check for welcome screen, go straight to main
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
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
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading ? null : () => _loginAnonymously(context),
                    child: Text(
                      localizations.translate('continue_as_guest') ?? 'Continue as Guest',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
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
