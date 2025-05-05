import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/user_model.dart';
import '../../localization/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  File? _imageFile;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _errorMessage = null;
        });
        print('Image picked successfully: ${image.path}');
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _errorMessage = 'حدث خطأ في اختيار الصورة: $e';
      });
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_imageFile == null) return null;
    
    try {
      print('Starting image upload for user: $userId');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'users/$userId/profile_$timestamp.jpg';
      final ref = _storage.ref().child(path);
      
      // التحقق من وجود الملف
      if (!await _imageFile!.exists()) {
        print('Image file does not exist');
        return null;
      }
      
      // طباعة حجم الملف
      print('Image file size: ${await _imageFile!.length()} bytes');
      
      // رفع الصورة
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );
      
      final uploadTask = await ref.putFile(_imageFile!, metadata);
      
      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        print('Image uploaded successfully. URL: $downloadUrl');
        return downloadUrl;
      } else {
        print('Upload failed with state: ${uploadTask.state}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        _errorMessage = 'حدث خطأ في رفع الصورة: $e';
      });
      return null;
    }
  }

  Future<void> _checkUserExists(String phone) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();
    
    if (querySnapshot.docs.isNotEmpty) {
      throw 'رقم الهاتف مستخدم بالفعل';
    }
  }

  void _register(BuildContext context) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final data = _formKey.currentState!.value;
      String? imageUrl;
      
      try {
        // التحقق من وجود المستخدم
        final existingUsers = await _firestore
            .collection('users')
            .where('phone', isEqualTo: data['phone'])
            .get();
        
        if (existingUsers.docs.isNotEmpty) {
          throw 'رقم الهاتف مستخدم بالفعل';
        }
        
        // إنشاء معرف فريد للمستخدم
        final docRef = _firestore.collection('users').doc();
        
        // رفع الصورة إذا تم اختيارها
        if (_imageFile != null) {
          print('Attempting to upload image');
          imageUrl = await _uploadImage(docRef.id);
          print('Image URL after upload: $imageUrl');
        }

        // إنشاء كائن المستخدم
        final user = UserModel(
          id: docRef.id,
          name: data['name'],
          phone: data['phone'],
          password: data['password'],
          imageUrl: imageUrl,
        );

        // حفظ بيانات المستخدم في Firestore
        await docRef.set(user.toJson());
        print('User created successfully with ID: ${user.id}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        print('Error during registration: $e');
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('register')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  Text(
                    localizations.translate('create_account'),
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: _isLoading ? null : _pickImage,
                    child: Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              image: _imageFile != null
                                  ? DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _imageFile == null
                                ? Icon(Icons.add_a_photo,
                                    size: 40, color: Colors.grey[400])
                                : null,
                          ),
                          if (_imageFile != null)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FormBuilderTextField(
                    name: 'name',
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: localizations.translate('full_name'),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: localizations.translate('name_required')),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'phone',
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: localizations.translate('phone'),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(errorText: 'الرجاء إدخال رقم الهاتف'),
                      FormBuilderValidators.numeric(errorText: 'الرجاء إدخال أرقام فقط'),
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
                      FormBuilderValidators.required(errorText: 'الرجاء إدخال كلمة المرور'),
                      FormBuilderValidators.minLength(6,
                          errorText: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
                    ]),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _register(context),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('إنشاء حساب'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('لديك حساب بالفعل؟ سجل دخول'),
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