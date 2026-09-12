import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'store/system_store.dart';
import 'theme.dart';
import 'splash.dart';

void main() {
  runApp(const ForgeApp());
}

class ForgeApp extends StatefulWidget {
  const ForgeApp({super.key});

  @override
  State<ForgeApp> createState() => _ForgeAppState();
}

class _ForgeAppState extends State<ForgeApp> {
  final store = SystemStore();

  @override
  void initState() {
    super.initState();
    store.init();
  }

  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forge Control',
      debugShowCheckedModeBanner: false,
      theme: forgeDarkTheme(),
      home: ForgeSplash(
        title: 'Forge Control',
        tagline: 'Know your rig.',
        next: AnimatedBuilder(
          animation: store,
          builder: (_, _) {
            if (!store.loaded) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            return DashboardScreen(store: store);
          },
        ),
      ),
    );
  }
}