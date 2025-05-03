import 'package:flutter/material.dart';
import '../models/property_model.dart';

class PropertyCard extends StatefulWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final bool showFavoriteButton;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const PropertyCard({
    Key? key,
    required this.property,
    required this.onTap,
    this.showFavoriteButton = false,
    this.isFavorite = false,
    this.onToggleFavorite,
  }) : super(key: key);

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  bool _isLoadingFavorite = false;
  bool _localIsFavorite = false;

  @override
  void initState() {
    super.initState();
    _localIsFavorite = widget.isFavorite;
  }

  @override
  void didUpdateWidget(PropertyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _localIsFavorite = widget.isFavorite;
    }
  }

  String _getPropertyTypeText(PropertyType type) {
    switch (type) {
      case PropertyType.apartment:
        return 'شقة';
      case PropertyType.villa:
        return 'فيلا';
      case PropertyType.house:
        return 'منزل';
      case PropertyType.store:
        return 'محل تجاري';
      case PropertyType.land:
        return 'أرض';
      case PropertyType.hall:
        return 'قاعة';
      case PropertyType.studio:
        return 'ستوديو';
      default:
        return 'أخرى';
    }
  }

  // تبديل حالة المفضلة محلياً قبل الاستدعاء الفعلي
  void _handleToggleFavorite() async {
    if (widget.onToggleFavorite == null) return;

    setState(() {
      _isLoadingFavorite = true;
      _localIsFavorite = !_localIsFavorite; // تغيير الحالة مباشرة
    });

    try {
      widget.onToggleFavorite!(); // استدعاء الدالة الأصلية
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة العقار
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.3,
                  child: widget.property.images.isNotEmpty
                      ? Image.network(
                          widget.property.images[0],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.home,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
                // شارة نوع العقار (بيع/إيجار)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.property.status == PropertyStatus.forSale
                          ? Colors.green
                          : Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.property.status == PropertyStatus.forSale
                          ? 'للبيع'
                          : 'للإيجار',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // زر المفضلة
                if (widget.showFavoriteButton)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: _isLoadingFavorite ? null : _handleToggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: _isLoadingFavorite
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.red[300]!,
                                  ),
                                ),
                              )
                            : Icon(
                                _localIsFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    _localIsFavorite ? Colors.red : Colors.grey,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
            // تفاصيل العقار
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان العقار
                    Text(
                      widget.property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // عنوان الموقع
                    Text(
                      widget.property.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    // السعر
                    Text(
                      '${widget.property.price.toStringAsFixed(0)} أوقية',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
