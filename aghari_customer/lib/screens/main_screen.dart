import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'favorites/favorites_screen.dart';
import 'purchases/purchases_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';
import '../localization/app_localizations.dart';
import '../providers/property_provider.dart';
import '../providers/user_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoritesScreen(),
    const PurchasesScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // قائمة العناوين المترجمة
    final List<String> _titles = [
      localizations.translate('home'),
      localizations.translate('favorites'),
      localizations.translate('purchases'),
      localizations.translate('notifications'),
      localizations.translate('profile'),
    ];

    final List<IconData> _icons = [
      Icons.home,
      Icons.favorite,
      Icons.shopping_cart,
      Icons.notifications,
      Icons.person,
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: List.generate(_titles.length, (index) {
          return BottomNavigationBarItem(
            icon: Icon(_icons[index]),
            label: _titles[index],
          );
        }),
        currentIndex: _selectedIndex,
        onTap: (index) {
          // تحميل المفضلات عند الانتقال إلى شاشة المفضلة
          if (index == 1) {
            final userProvider =
                Provider.of<UserProvider>(context, listen: false);
            final propertyProvider =
                Provider.of<PropertyProvider>(context, listen: false);

            if (userProvider.currentUser != null) {
              propertyProvider.loadFavorites();
            }
          }

          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
