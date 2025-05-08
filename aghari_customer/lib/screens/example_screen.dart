import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('screen_title')),
      ),
      body: Column(
        children: [
          Text(localizations.translate('some_text')),
          ElevatedButton(
            onPressed: () {},
            child: Text(localizations.translate('button_text')),
          ),
        ],
      ),
    );
  }
} 