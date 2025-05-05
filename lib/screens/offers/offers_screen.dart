import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/offer_model.dart';
import '../../providers/offer_provider.dart';
import 'offer_details_screen.dart';
import 'package:intl/intl.dart';
import '../../localization/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({Key? key}) : super(key: key);

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    print('تهيئة شاشة العروض...');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOffers();
    });
  }

  void _loadOffers() {
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);
    offerProvider.fetchActiveOffers().then((_) {
      print('تم جلب ${offerProvider.offers.length} عرض');

      if (offerProvider.offers.isEmpty &&
          mounted &&
          offerProvider.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد عروض متاحة حالياً، سيتم إضافة عروض قريباً'),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // بدء التحديث الدوري للعروض
      offerProvider.startPeriodicUpdates(context);
    }).catchError((error) {
      print('خطأ في جلب العروض: $error');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('offers')),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: localizations.translate('back'),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/main');
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizations.translate('all_offers')),
            Tab(text: localizations.translate('ending_soon')),
          ],
        ),
      ),
      body: Consumer<OfferProvider>(
        builder: (context, offerProvider, child) {
          final localizations = AppLocalizations.of(context);

          if (offerProvider.isLoading && offerProvider.offers.isEmpty) {
            return const Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جارِ تحميل العروض...')
              ],
            ));
          }

          if (offerProvider.error != null && offerProvider.offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'فشل تحميل العروض\n${offerProvider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      offerProvider.retry();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(localizations.translate('retry')),
                  ),
                ],
              ),
            );
          }

          // الحصول على العروض القريبة من الانتهاء
          final expiringOffers = offerProvider.getExpiringOffers();

          return TabBarView(
            controller: _tabController,
            children: [
              // علامة التبويب الأولى: جميع العروض
              _buildOffersList(offerProvider.offers, offerProvider),

              // علامة التبويب الثانية: العروض القريبة من الانتهاء
              expiringOffers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timelapse,
                              size: 70, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            localizations.translate('no_expiring_offers'),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : _buildOffersList(expiringOffers, offerProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOffersList(
      List<OfferModel> offers, OfferProvider offerProvider) {
    if (offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).translate('no_offers_available'),
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => offerProvider.retry(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: offers.length,
        itemBuilder: (context, index) {
          return _buildOfferCard(context, offers[index]);
        },
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, OfferModel offer) {
    final localizations = AppLocalizations.of(context);
    final daysLeft = offer.endDate.difference(DateTime.now()).inDays;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OfferDetailsScreen(offerId: offer.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة العرض
            SizedBox(
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  offer.imageUrl.isNotEmpty
                      ? Hero(
                          tag: 'offer_image_${offer.id}',
                          child: CachedNetworkImage(
                            imageUrl: offer.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              print('خطأ في تحميل صورة العرض: $error');
                              return Container(
                                color: Colors.amber.withOpacity(0.2),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.local_offer,
                                          size: 48, color: Colors.amber),
                                      SizedBox(height: 8),
                                      Text('عرض خاص',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          color: Colors.amber.withOpacity(0.2),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_offer,
                                    size: 48, color: Colors.amber),
                                SizedBox(height: 8),
                                Text('عرض خاص',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                  // نسبة الخصم
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        '${localizations.translate('discount')} ${offer.discount.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // عقار خاص (إذا كان مرتبط بعقار)
                  if (offer.propertyId != null && offer.propertyTitle != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              localizations.translate('property_offer'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // عدد الأيام المتبقية
                  Positioned(
                    bottom: 0,
                    right: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${localizations.translate('available_until')}: ${dateFormat.format(offer.endDate)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: daysLeft < 3
                                  ? Colors.red
                                  : daysLeft < 7
                                      ? Colors.orange
                                      : Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              daysLeft == 0
                                  ? localizations.translate('last_day')
                                  : '${localizations.translate('days_left')} $daysLeft ${localizations.translate('days')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // تفاصيل العرض
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // إظهار اسم العقار المرتبط إذا كان موجوداً
                  if (offer.propertyId != null &&
                      offer.propertyTitle != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home,
                              size: 16, color: Colors.blue.shade800),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              offer.propertyTitle!,
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  Text(
                    offer.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  // زر عرض التفاصيل
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OfferDetailsScreen(offerId: offer.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility),
                          label: Text(localizations.translate('view_details')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (offer.propertyId != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/property-details',
                              arguments: offer.propertyId,
                            );
                          },
                          icon: const Icon(Icons.home),
                          tooltip: localizations.translate('view_property'),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
