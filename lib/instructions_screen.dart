import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Ekran z instrukcją obsługi aplikacji.
/// Tekst jest tłumaczony na podstawie języka (pl / es).
class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context); // dostęp do tłumaczeń

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('instructions_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            loc.translate('instructions_content'),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
