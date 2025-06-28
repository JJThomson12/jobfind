import 'package:flutter/material.dart';
import 'package:jobfind/pages/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ucgikrtiwmpydfdejdlg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjZ2lrcnRpd21weWRmZGVqZGxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxNjQxODIsImV4cCI6MjA2NTc0MDE4Mn0.j939G4PFBa56lca6nidBJgBgdPIIuryOcOKb1Gd6Bf8',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Job Finder',
      home: const SplashScreen(),
    );
  }
}
