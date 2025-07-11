import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:provider/provider.dart';
import 'package:aghari_customer/providers/language_provider.dart'; // For localization
import 'package:aghari_customer/localization/app_localizations.dart'; // For localization

class RestartPromptScreen extends StatelessWidget {
  const RestartPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the language provider
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context);

    // Determine text based on current language
    String titleText = localizations?.translate('restart_required_title') ?? 'Restart Required';
    String messageText = localizations?.translate('restart_required_message') ?? 'To ensure all your data is loaded correctly, please restart the application.';
    String buttonText = localizations?.translate('restart_app_button') ?? 'Restart App';

    // Fallback for French if Arabic is not fully set up or key is missing
    if (languageProvider.locale.languageCode == 'fr') {
      titleText = 'Redémarrage requis';
      messageText = 'Pour garantir que toutes vos données sont correctement chargées, veuillez redémarrer l\'application.';
      buttonText = 'Redémarrer l\'application';
    }
    // Fallback for Arabic if French is not fully set up or key is missing
     else if (languageProvider.locale.languageCode == 'ar') {
      titleText = 'إعادة تشغيل مطلوبة';
      messageText = 'لضمان تحميل جميع بياناتك بشكل صحيح، يرجى إعادة تشغيل التطبيق.';
      buttonText = 'إعادة تشغيل التطبيق';
    }


    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.info_outline,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                titleText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                messageText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                onPressed: () {
                  Phoenix.rebirth(context);
                },
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
