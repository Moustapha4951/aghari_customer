import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/property_provider.dart';
import '../../widgets/property_list.dart';
import '../../localization/app_localizations.dart';
import '../../providers/user_provider.dart';
import '../../models/property_model.dart'; // Added import

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = false;
  bool _isGuestMode = false; // Added state variable
  List<PropertyModel> _guestProperties = []; // Added state variable

  @override
  void initState() {
    super.initState();
    _checkUserAndLoadFavorites();
  }

  // تحقق من المستخدم وتحميل المفضلة
  Future<void> _checkUserAndLoadFavorites() async {
    setState(() {
      _isLoading = true;
      _isGuestMode = false; // Reset guest mode
    });

    try {
      print('📱 تهيئة شاشة المفضلة...');

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // التحقق من جلسة المستخدم أولاً
      await userProvider.checkUserSession();

      if (userProvider.currentUser == null) {
        print('⚠️ Guest user on Favorites screen, loading guest properties...');
        // No longer just return; call _loadGuestProperties instead.
        _loadGuestProperties(); // Call the new method
        return;
      }

      print('👤 المستخدم الحالي: ${userProvider.currentUser!.id}');

      // التحقق من تعيين المستخدم في المزودين
      await userProvider.verifyUserIdInProviders(context);

      // تحميل المفضلة
      await _loadFavorites();
    } catch (e) {
      print('❌ خطأ في التحقق من المستخدم وتحميل المفضلة: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // تأكد من وجود معرف المستخدم
      if (userProvider.currentUser != null) {
        final userId = userProvider.currentUser!.id;
        print('🔄 تحميل المفضلة للمستخدم: $userId');

        // استخدام إعادة التحميل القسري للتأكد من المزامنة
        await propertyProvider.forceReloadFavorites(userId);

        // تحميل العقارات
        await propertyProvider.fetchProperties();
      } else {
        print('⚠️ لا يوجد مستخدم مسجل الدخول لتحميل المفضلة');
      }
    } catch (e) {
      print('❌ خطأ في تحميل المفضلة: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method to load properties for guest users
  Future<void> _loadGuestProperties() async {
    setState(() {
      _isLoading = true;
      _isGuestMode = true;
    });
    try {
      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
      // Ensure properties are fetched if not already available or if a fresh list is desired for guests
      await propertyProvider.fetchProperties();
      if (mounted) {
        setState(() {
          // Take a limited number of properties for display, e.g., first 6.
          _guestProperties = propertyProvider.properties.take(6).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading guest properties: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Optionally handle error state for guest properties if needed
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      localizations.translate('favorites'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // حالة المستخدم للتشخيص
                  Text(
                    userProvider.currentUser != null ? '✅' : '❌',
                    style: TextStyle(fontSize: 18),
                  ),

                  // زر إعادة التحميل
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: _isLoading ? null : _checkUserAndLoadFavorites,
                    tooltip: 'تحديث المفضلة',
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            // New block for guest mode
            else if (_isGuestMode)
              Expanded( // Make sure this Column takes available space
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Explore Properties", // Hardcoded: localizations.translate('explore_properties_title'),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_guestProperties.isEmpty && !_isLoading)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text("No properties found to display at the moment."), // Hardcoded: localizations.translate('no_properties_found')),
                      )
                    else
                      Expanded(
                        child: PropertyList(
                          properties: _guestProperties,
                          showFavoriteButton: false, // Explicitly false for guest view
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text("Log in to save your favorites!"), // Hardcoded: localizations.translate('login_for_favorites_prompt')),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            icon: const Icon(Icons.login),
                            label: Text(localizations.translate('login')), // Existing key
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            // Existing block for logged-in users
            else if (userProvider.currentUser != null)
              Expanded(
                child: Consumer<PropertyProvider>(
                  builder: (context, propertyProvider, child) {
                    final favoriteProperties =
                        propertyProvider.favoriteProperties;

                    if (favoriteProperties.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              localizations.translate('no_favorites'),
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                    context, '/main');
                              },
                              icon: Icon(Icons.home),
                              label: Text('استعرض العقارات'),
                            ),
                          ],
                        ),
                      );
                    }

                    return PropertyList(
                      properties: favoriteProperties,
                      showFavoriteButton: true,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
