import 'package:flutter/material.dart';
import 'screens/library_screen.dart';
import 'store/library_store.dart';

void main() {
  runApp(const OmniApp());
}

class OmniApp extends StatefulWidget {
  const OmniApp({super.key});

  @override
  State<OmniApp> createState() => _OmniAppState();
}

class _OmniAppState extends State<OmniApp> {
  final store = LibraryStore();

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniLauncher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
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
          return LibraryScreen(store: store);
        },
      ),
    );
  }
}
