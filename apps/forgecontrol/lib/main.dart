import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'store/system_store.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: AnimatedBuilder(
        animation: store,
        builder: (_, _) {
          if (!store.loaded) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return DashboardScreen(store: store);
        },
      ),
    );
  }
}
