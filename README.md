# تطبيق عقاري

تطبيق عقاري متكامل مبني بواسطة Flutter و Firebase للتحكم وعرض عقارات للبيع والشراء.

## المكونات الرئيسية

### تطبيق المسؤول (aghari_admin)

لوحة تحكم المسؤول لإدارة المحتوى والمستخدمين. تتضمن:
- إدارة العقارات
- إدارة المستخدمين
- إدارة الطلبات
- إدارة العروض
- إدارة المدن والأحياء
- إدارة الإشعارات

### تطبيق العميل (aghari_customer)

تطبيق المستخدم النهائي للعملاء. يتضمن:
- تصفح العقارات
- إدارة الملف الشخصي
- حفظ المفضلة
- تقديم وتلقي الطلبات
- إدارة عمليات الشراء
- دعم متعدد اللغات

## التقنيات المستخدمة

- **Flutter**: إطار عمل واجهة المستخدم
- **Firebase**: خدمات الخلفية
  - Firebase Authentication للمصادقة
  - Cloud Firestore لتخزين البيانات
  - Firebase Storage لتخزين الملفات
  - Firebase Messaging للإشعارات 

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

## إعداد البناء في Bitrise

### متطلبات البناء

للبناء الناجح في Bitrise، يجب توفير المتطلبات التالية:

#### لبناء تطبيق Android:
1. ملف التوقيع (keystore): يجب رفع ملف `upload-keystore.jks` كملف سري في إعدادات التطبيق على Bitrise.
2. إعدادات التوقيع: يجب تعيين المتغيرات البيئية التالية في Bitrise:
   - `ANDROID_KEYSTORE_PASSWORD`: كلمة مرور مخزن المفاتيح
   - `ANDROID_KEY_PASSWORD`: كلمة مرور المفتاح
   - `ANDROID_KEY_ALIAS`: اسم المفتاح (عادة "upload")

#### لبناء تطبيق iOS:
1. شهادة التوقيع: يجب رفع شهادة توقيع iOS وملف provisioning profile.
2. تأكد من تعيين معرف الحزمة `com.aghari.customer` بشكل صحيح في حساب Apple Developer.

### خطوات إعداد Bitrise:

1. **رفع مفتاح التوقيع لـ Android**:
   - انتقل إلى `Workflow Editor > Code Signing`
   - اختر علامة التبويب `ANDROID` وارفع ملف keystore
   - أدخل كلمات المرور واسم المفتاح

2. **إعداد شهادات iOS**:
   - انتقل إلى `Workflow Editor > Code Signing`
   - اختر علامة التبويب `iOS` وارفع شهادة التوقيع وملف التوزيع

3. **إضافة خطوة بناء Flutter**:
   - قم بتكوين Workflow ليتضمن خطوة `Flutter Build`
   - تأكد من اختيار الأنظمة المطلوبة (Android و/أو iOS)

لمزيد من المعلومات، يرجى زيارة [وثائق Bitrise الرسمية لتطبيقات Flutter](https://devcenter.bitrise.io/builds/flutterio-getting-started/).
