import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/game_controller.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SkullKingApp());
}

class SkullKingApp extends StatelessWidget {
  const SkullKingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameController(StorageService())..init(),
      child: MaterialApp(
        title: 'Skull King — Score',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const HomeScreen(),
        locale: const Locale('fr'),
      ),
    );
  }
}
