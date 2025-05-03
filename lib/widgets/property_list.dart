import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import 'property_card.dart';
import '../models/property_model.dart';

class PropertyList extends StatelessWidget {
  final List<PropertyModel>? properties;
  final bool showFavoriteButton;

  const PropertyList({
    Key? key,
    this.properties,
    this.showFavoriteButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, child) {
        // استخدام القائمة المحددة أو استرجاع كل العقارات من البروفايدر
        final propertyList = properties ?? propertyProvider.properties;

        if (propertyProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (propertyProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(propertyProvider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      propertyProvider.loadProperties(ownerId: null),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        if (propertyList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'لا توجد عقارات متاحة',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: propertyList.length,
          itemBuilder: (context, index) {
            final property = propertyList[index];
            return PropertyCard(
              property: property,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/property-details',
                  arguments: property.id,
                );
              },
              showFavoriteButton: showFavoriteButton,
              isFavorite: propertyProvider.isFavorite(property.id),
              onToggleFavorite: () =>
                  propertyProvider.toggleFavorite(property.id),
            );
          },
        );
      },
    );
  }
}
