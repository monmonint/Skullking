import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/game_controller.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'update/update_prompt.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SkullKingApp(checkUpdatesOnLaunch: true));
}

class SkullKingApp extends StatelessWidget {
  final GameStorage? storage;

  /// Les tests laissent ce drapeau à faux pour ne pas interroger GitHub.
  final bool checkUpdatesOnLaunch;

  const SkullKingApp({
    super.key,
    this.storage,
    this.checkUpdatesOnLaunch = false,
  });

  @override
  Widget build(BuildContext context) {
    return UpdateLaunch(
      enabled: checkUpdatesOnLaunch,
      child: ChangeNotifierProvider(
        create: (_) => GameController(storage ?? StorageService())..init(),
        child: MaterialApp(
          title: 'Skull King — Score',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: const HomeScreen(),
          locale: const Locale('fr'),
        ),
      ),
    );
  }
}
