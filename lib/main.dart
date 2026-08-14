import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/language_screen.dart';
import 'services/notification_service.dart';
import 'services/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();
  final languageController = AppLanguageController();
  await languageController.load();
  runApp(HarvestGuardAI(languageController: languageController));
}

class HarvestGuardAI extends StatelessWidget {
  const HarvestGuardAI({super.key, required this.languageController});

  final AppLanguageController languageController;

  @override
  Widget build(BuildContext context) {
    return AppLocalizations(
      controller: languageController,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HarvestGuard AI',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B5E20),
            brightness: Brightness.light,
          ),
        ),
        home: const LanguageScreen(),
      ),
    );
  }
}
