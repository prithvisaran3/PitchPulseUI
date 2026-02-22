import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/firebase_options.dart';
import 'core/theme.dart';
import 'core/auth_gate.dart';
import 'providers/auth_provider.dart';
import 'providers/workspace_provider.dart';
import 'providers/player_provider.dart';
import 'core/route_observer.dart';
import 'services/presage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Dark status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Dismiss any Presage native screen left on top after a hot restart.
  // This is a no-op when no overlay is present.
  await PresageService.dismissIfPresented();

  runApp(const PitchPulseApp());
}

class PitchPulseApp extends StatelessWidget {
  const PitchPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: MaterialApp(
        title: 'PitchPulse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        navigatorObservers: [AppRouteObserver()],
        home: const AuthGate(),
        builder: (context, child) {
          // Clamp text scale for consistent UI
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler:
                  TextScaler.linear(mq.textScaler.scale(1.0).clamp(0.8, 1.15)),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
