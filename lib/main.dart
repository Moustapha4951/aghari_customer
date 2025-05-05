import 'package:aghari_customer/models/property_model.dart';
import 'package:aghari_customer/screens/profile/become_seller_screen.dart';
import 'package:aghari_customer/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/property_provider.dart';
import 'providers/property_request_provider.dart';
import 'screens/properties/property_details_screen.dart';
import 'screens/properties/property_list_screen.dart';
import 'package:aghari_customer/services/notification_service.dart';
import 'providers/property_purchase_provider.dart';
import 'screens/purchases/purchases_screen.dart';
import 'screens/profile/my_properties_screen.dart';
import 'screens/profile/received_requests_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/profile/request_property_screen.dart';
import 'screens/onboarding/become_seller_welcome_screen.dart';
import 'firebase_options.dart';
import 'screens/offers/offers_screen.dart';
import 'providers/offer_provider.dart';
import 'providers/language_provider.dart';
import 'localization/app_localizations.dart';
import 'providers/received_requests_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تهيئة خدمة الإشعارات
  await NotificationService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => PropertyRequestProvider()),
        ChangeNotifierProvider(create: (_) => PropertyPurchaseProvider()),
        ChangeNotifierProvider(create: (_) => OfferProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ReceivedRequestsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'عقاري',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor:
                  const Color(0xFF1976D2), // تغيير من اللون الأخضر إلى الأزرق
              primary: const Color(0xFF1976D2),
              secondary: const Color(0xFF64B5F6), // لون أزرق فاتح كلون ثانوي
            ),
            textTheme: GoogleFonts.tajawalTextTheme(
              Theme.of(context).textTheme,
            ),
            chipTheme: ChipThemeData(
              selectedColor:
                  const Color(0xFF1976D2), // تحديث لون الـ Chip المحدد
              backgroundColor: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 12),
              labelStyle: const TextStyle(fontSize: 14),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedItemColor: const Color(0xFF1976D2),
              unselectedItemColor: Colors.grey[600],
              type: BottomNavigationBarType.fixed,
              elevation: 8,
            ),
          ),
          locale: languageProvider.locale,
          supportedLocales: const [
            Locale('ar', 'SA'),
            Locale('fr', 'FR'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/main': (context) => const MainScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/seller-welcome': (context) => const BecomeSellerWelcomeScreen(),
            '/request-property': (context) => const RequestPropertyScreen(),
            '/become-seller': (context) => const BecomeSellerScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/property-details': (context) => PropertyDetailsScreen(
                  propertyId:
                      ModalRoute.of(context)?.settings.arguments as String,
                ),
            '/property-list': (context) => PropertyListScreen(
                  title: 'عقارات',
                  status: ModalRoute.of(context)!.settings.arguments
                      as PropertyStatus,
                ),
            '/purchases': (context) => const PurchasesScreen(),
            '/my-properties': (context) => const MyPropertiesScreen(),
            '/received-requests': (context) => const ReceivedRequestsScreen(),
            '/profile': (context) {
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              if (userProvider.currentUser == null) {
                return const LoginScreen();
              }
              return const ProfileScreen();
            },
            '/offers': (context) => const OffersScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
