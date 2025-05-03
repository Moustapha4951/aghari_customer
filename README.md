# تطبيق عقاري للعملاء

تطبيق لعرض وإدارة العقارات للعملاء.

## متطلبات النشر على المتاجر

### إنشاء مفتاح التوقيع لأندرويد

1. قم بإنشاء مفتاح التوقيع باستخدام الأمر التالي:

```
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. انقل ملف `upload-keystore.jks` إلى مجلد `android/` في مشروعك

3. قم بتعديل ملف `android/key.properties` وتحديث كلمات المرور:

```
storePassword=<كلمة مرور المخزن>
keyPassword=<كلمة مرور المفتاح>
keyAlias=upload
storeFile=../upload-keystore.jks
```

### النشر على App Store (iOS)

1. التأكد من إعداد حساب مطور Apple Developer
2. تحديث معرف حزمة التطبيق في Xcode
3. إضافة الأيقونات المطلوبة وإعداد LaunchScreen

## بناء التطبيق

### أندرويد

لإنشاء ملف APK للتوزيع:

```
flutter build apk --release
```

لإنشاء حزمة App Bundle للنشر على Google Play:

```
flutter build appbundle
```

### iOS

لإنشاء ملف IPA للتوزيع:

```
flutter build ios --release
```

ثم استخدم Xcode للمزيد من الخطوات للنشر على App Store.

## اختبار التطبيق

تأكد من اختبار التطبيق على مختلف أحجام الشاشات والإصدارات قبل النشر النهائي.

## متطلبات الخصوصية

- إضافة سياسة الخصوصية للتطبيق
- إعداد صفحة دعم للمستخدمين
- تحديد كيفية استخدام بيانات المستخدم في التطبيق
