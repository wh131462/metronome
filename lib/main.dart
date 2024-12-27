import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/metronome_screen.dart';
import 'providers/metronome_provider.dart';

void main() {
  runApp(const MetronomeApp());
}

class MetronomeApp extends StatelessWidget {
  const MetronomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MetronomeProvider(),
      child: MaterialApp(
        title: '节拍器',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const MetronomeScreen(),
      ),
    );
  }
} 