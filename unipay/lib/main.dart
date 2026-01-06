// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/main_screen.dart'; 

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  // Ensure status bar is visible and transparent
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light, // for iOS
  ));

  // Ensure not in fullscreen immersive mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    const ProviderScope(
      child: UniPayApp(),
    ),
  );
}

class UniPayApp extends StatelessWidget {
  const UniPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniPay',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (isLoggedIn) {
        if (isLoggedIn) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
