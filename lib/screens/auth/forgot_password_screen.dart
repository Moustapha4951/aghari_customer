import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/user_provider.dart';
import '../../localization/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _submitResetRequest() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final data = _formKey.currentState!.value;

      try {
        // التحقق من وجود المستخدم
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: data['phone'])
            .get();

        if (userQuery.docs.isEmpty) {
          throw AppLocalizations.of(context).translate('phone_not_found');
        }

        // التحقق من تطابق كلمات المرور
        if (data['new_password'] != data['confirm_password']) {
          throw AppLocalizations.of(context).translate('passwords_not_match');
        }

        // إنشاء طلب تغيير كلمة المرور
        await FirebaseFirestore.instance
            .collection('passwordResetRequests')
            .add({
          'userId': userQuery.docs.first.id,
          'userPhone': data['phone'],
          'newPassword': data['new_password'],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
      } catch (e) {
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
      appBar: AppBar(
        title: Text(localizations.translate('forgot_password')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isSuccess
                ? _buildSuccessMessage(localizations)
                : _buildResetForm(localizations),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage(AppLocalizations localizations) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.mark_email_read,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        Text(
          localizations.translate('reset_request_submitted'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          localizations.translate('reset_request_message'),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(localizations.translate('back_to_login')),
        ),
      ],
    );
  }

  Widget _buildResetForm(AppLocalizations localizations) {
    return FormBuilder(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            localizations.translate('reset_password_title'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('reset_password_description'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),
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
            name: 'new_password',
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: localizations.translate('new_password'),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                  errorText:
                      localizations.translate('please_enter_new_password')),
              FormBuilderValidators.minLength(6,
                  errorText: localizations.translate('password_min_length')),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'confirm_password',
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: localizations.translate('confirm_new_password'),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
              ),
            ),
            obscureText: _obscureConfirmPassword,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                  errorText:
                      localizations.translate('please_confirm_new_password')),
            ]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitResetRequest,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(localizations.translate('submit_reset_request')),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text(localizations.translate('back_to_login')),
          ),
        ],
      ),
    );
  }
}
