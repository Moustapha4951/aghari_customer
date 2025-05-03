import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/offer_model.dart';
import '../services/offer_service.dart';

class OfferProvider with ChangeNotifier {
  final OfferService _offerService = OfferService();
  List<OfferModel> _offers = [];
  bool _isLoading = false;
  String? _error;
  DateTime _lastFetched =
      DateTime(2000); // تاريخ قديم للتأكد من أن العروض ستُجلب أول مرة

  List<OfferModel> get offers => _offers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // جلب جميع العروض النشطة
  Future<void> fetchActiveOffers({bool forceRefresh = false}) async {
    // تحديث العروض فقط إذا مر وقت كافي أو تم طلب تحديث إجباري
    final now = DateTime.now();
    print('بدء جلب العروض النشطة | التحديث الإجباري: $forceRefresh');
    print(
        'آخر تحديث: ${_lastFetched.toString()}، المدة منذ آخر تحديث: ${now.difference(_lastFetched).inMinutes} دقيقة');

    if (!forceRefresh &&
        now.difference(_lastFetched).inMinutes < 15 &&
        _offers.isNotEmpty) {
      // استخدام البيانات المخزنة محلياً إذا تم تحديثها مؤخراً (أقل من 15 دقيقة)
      print(
          'استخدام البيانات المخزنة مؤقتًا لأنها حديثة (${_offers.length} عرض)');
      return;
    }

    // إذا كانت هناك عملية تحميل حالية، لا تبدأ عملية أخرى
    if (_isLoading) {
      print('هناك عملية تحميل حالية بالفعل، انتظر حتى تنتهي');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    print('جاري تحميل العروض...');

    try {
      // التحقق من الاتصال بالإنترنت أولاً
      bool hasConnection = await _checkInternetConnection();
      if (!hasConnection) {
        _error = 'يرجى التحقق من اتصالك بالإنترنت وإعادة المحاولة';
        _isLoading = false;
        notifyListeners();
        print('فشل الاتصال بالإنترنت - لا يمكن جلب العروض');
        return;
      }

      print('تم التحقق من الاتصال بالإنترنت بنجاح');
      final newOffers = await _offerService.getActiveOffers();
      print('تم استلام ${newOffers.length} عرض من الخدمة');

      // إذا كانت القائمة فارغة ولكن لدينا بيانات محلية، احتفظ بالبيانات المحلية
      if (newOffers.isEmpty && _offers.isNotEmpty && !forceRefresh) {
        print(
            'لم يتم العثور على عروض جديدة، الاحتفاظ بالعروض المحلية الحالية (${_offers.length} عرض)');
        _isLoading = false;
        notifyListeners();
        return;
      }

      _offers = newOffers;
      _lastFetched = now;
      _isLoading = false;
      _error = null; // إعادة تعيين حالة الخطأ عند النجاح
      notifyListeners();
      print('تم تحديث العروض: ${_offers.length} عرض');

      // إذا لم تكن هناك عروض، قم بتعيين رسالة خطأ لإخبار المستخدم
      if (_offers.isEmpty) {
        _error = 'لا توجد عروض متاحة حالياً';
        notifyListeners();
        print('تم تعيين رسالة: لا توجد عروض متاحة حالياً');
      }
    } catch (e) {
      String errorMessage = 'فشل في جلب العروض';

      if (e is SocketException || e is HttpException) {
        errorMessage = 'تعذر الاتصال بالخادم، يرجى التحقق من اتصالك بالإنترنت';
      } else if (e is TimeoutException) {
        errorMessage = 'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى';
      } else if (e is FormatException) {
        errorMessage = 'تنسيق البيانات غير صحيح، يرجى الاتصال بالدعم الفني';
      }

      _error = errorMessage;
      _isLoading = false;
      notifyListeners();
      print('خطأ في جلب العروض: $e');
    }
  }

  // التحقق من الاتصال بالإنترنت
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      print('خطأ في التحقق من الاتصال بالإنترنت: $e');
      return true; // نفترض أن هناك اتصال في حالة وجود خطأ غير متوقع
    }
  }

  // جلب العروض الخاصة بعقار معين
  Future<List<OfferModel>> getOffersForProperty(String propertyId) async {
    try {
      // التحقق من الاتصال بالإنترنت أولاً
      bool hasConnection = await _checkInternetConnection();
      if (!hasConnection) {
        return [];
      }

      return await _offerService.getOffersForProperty(propertyId);
    } catch (e) {
      print('خطأ في جلب عروض العقار: $e');
      // إرجاع مصفوفة فارغة بدلاً من إعادة رمي الخطأ
      return [];
    }
  }

  // جلب تفاصيل عرض محدد
  Future<OfferModel?> getOfferDetails(String offerId) async {
    // التحقق أولاً من وجود العرض في المصفوفة المحلية
    final cachedOffer = _offers.firstWhere(
      (offer) => offer.id == offerId,
      orElse: () => OfferModel(
          id: '',
          title: '',
          description: '',
          discount: 0,
          imageUrl: '',
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          isActive: false,
          createdAt: DateTime.now(),
          createdBy: ''),
    );

    // إذا وجدنا العرض في الذاكرة، استخدمه بدلاً من جلبه مجدداً من Firestore
    if (cachedOffer.id.isNotEmpty) {
      return cachedOffer;
    }

    try {
      // التحقق من الاتصال بالإنترنت أولاً
      bool hasConnection = await _checkInternetConnection();
      if (!hasConnection) {
        throw Exception('لا يوجد اتصال بالإنترنت');
      }

      final offer = await _offerService.getOfferById(offerId);
      return offer;
    } catch (e) {
      print('خطأ في جلب تفاصيل العرض: $e');
      return null;
    }
  }

  // تحديث العروض دورياً
  void startPeriodicUpdates(BuildContext context) {
    // تحديث العروض كل 15 دقيقة تلقائياً
    Future.delayed(const Duration(minutes: 15), () {
      if (context.mounted) {
        fetchActiveOffers(forceRefresh: true);
        startPeriodicUpdates(context);
      }
    });
  }

  // الحصول على العروض القريبة من الانتهاء (أقل من 3 أيام)
  List<OfferModel> getExpiringOffers() {
    final now = DateTime.now();
    return _offers
        .where((offer) => offer.endDate.difference(now).inDays < 3)
        .toList();
  }

  // إعادة تعيين حالة الخطأ
  void resetError() {
    _error = null;
    notifyListeners();
  }

  // إعادة المحاولة
  Future<void> retry() async {
    await fetchActiveOffers(forceRefresh: true);
  }
}
