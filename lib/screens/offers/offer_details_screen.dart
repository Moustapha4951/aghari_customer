import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/offer_model.dart';
import '../../providers/offer_provider.dart';
import 'package:intl/intl.dart';
import '../../localization/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class OfferDetailsScreen extends StatefulWidget {
  final String offerId;

  const OfferDetailsScreen({Key? key, required this.offerId}) : super(key: key);

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  bool _isLoading = false;
  OfferModel? _offer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferDetails();
  }

  Future<void> _loadOfferDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final offerProvider = Provider.of<OfferProvider>(context, listen: false);
      final offer = await offerProvider.getOfferDetails(widget.offerId);

      if (offer == null) {
        setState(() {
          _error = 'لم يتم العثور على العرض، ربما تم حذفه أو لم يعد متاحًا';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _offer = offer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // مشاركة تفاصيل العرض
  void _shareOffer() {
    if (_offer == null) return;

    final text = '''
${_offer!.title}
خصم: ${_offer!.discount.toInt()}%
${_offer!.description}

العرض ساري حتى: ${DateFormat('dd/MM/yyyy').format(_offer!.endDate)}

تطبيق عقاري - أفضل تطبيق للعقارات
''';

    Share.share(text);
  }

  // لفتح الهاتف للاتصال
  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).translate('cannot_call_number')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('خطأ في محاولة الاتصال: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر إجراء المكالمة، يرجى المحاولة لاحقًا'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('offer_details')),
        centerTitle: true,
        actions: _offer != null
            ? [
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: localizations.translate('share'),
                  onPressed: _shareOffer,
                ),
              ]
            : null,
      ),
      floatingActionButton: _offer?.propertyId != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/property-details',
                  arguments: _offer!.propertyId,
                );
              },
              icon: const Icon(Icons.home),
              label: Text(localizations.translate('view_property')),
              backgroundColor: theme.primaryColor,
            )
          : null,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جارِ تحميل تفاصيل العرض...')
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 50, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        '${localizations.translate('error_loading_offer_details')}\n$_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadOfferDetails,
                        icon: const Icon(Icons.refresh),
                        label: Text(localizations.translate('retry')),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(localizations.translate('back')),
                      ),
                    ],
                  ),
                )
              : _offer == null
                  ? Center(
                      child: Text(
                        localizations.translate('offer_not_found'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  : _buildOfferDetails(context),
    );
  }

  Widget _buildOfferDetails(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final daysLeft = _offer!.endDate.difference(DateTime.now()).inDays;
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadOfferDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة العرض
            Hero(
              tag: 'offer_image_${_offer!.id}',
              child: SizedBox(
                height: 250,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _offer!.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _offer!.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              print('خطأ في تحميل صورة العرض: $error');
                              return Image.asset(
                                  'assets/images/placeholder.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.amber.withOpacity(0.2),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                              });
                            },
                          )
                        : Container(
                            color: Colors.amber.withOpacity(0.2),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_offer,
                                      size: 48, color: theme.primaryColor),
                                  const SizedBox(height: 8),
                                  Text(
                                    'عرض خاص',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    // معلومات العرض على الصورة
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${localizations.translate('discount')} ${_offer!.discount.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // معلومات العرض
                    Positioned(
                      bottom: 0,
                      right: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _offer!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
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
            ),

            // تفاصيل العرض
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // فترة العرض
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations.translate('start_date'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  dateFormat.format(_offer!.startDate),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(start: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizations.translate('end_date'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    dateFormat.format(_offer!.endDate),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: daysLeft < 3
                                          ? Colors.red
                                          : theme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // وصف العرض
                  Text(
                    localizations.translate('offer_description'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _offer!.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // زر عرض العقار (إذا كان العرض مرتبط بعقار)
                  if (_offer!.propertyId != null) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/property-details',
                          arguments: _offer!.propertyId,
                        );
                      },
                      icon: const Icon(Icons.home),
                      label: Text(localizations.translate('view_property')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // معلومات إضافية
                  Card(
                    elevation: 0,
                    color: Colors.blue[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.blue[100]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${localizations.translate('offer_valid_until')} ${dateFormat.format(_offer!.endDate)}',
                                  style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations.translate('contact_seller_for_offer'),
                            style: TextStyle(color: Colors.blue[700]),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _makePhoneCall('+966500000000');
                              },
                              icon: const Icon(Icons.phone),
                              label: Text(localizations.translate('call_now')),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                                backgroundColor: Colors.blue[700],
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
          ],
        ),
      ),
    );
  }
}
