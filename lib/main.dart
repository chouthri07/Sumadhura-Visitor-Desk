import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bootstrap.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VisitorStartup());
}

class VisitorStartup extends StatefulWidget {
  const VisitorStartup({super.key});

  @override
  State<VisitorStartup> createState() => _VisitorStartupState();
}

class _VisitorStartupState extends State<VisitorStartup> {
  final _preferences = SharedPreferences.getInstance();
  SharedPreferences? _readyPreferences;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _start();
    }
  }

  Future<void> _start() async {
    await precacheImage(
      const AssetImage('assets/images/sumadhura-logo.png'),
      context,
    );
    if (!mounted) return;
    // Count visible time only after the logo has loaded and a frame is drawn.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    final preferences = await _preferences;
    if (mounted) setState(() => _readyPreferences = preferences);
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _readyPreferences;
    if (preferences != null) {
      return VisitorBootstrap(preferences: preferences);
    }
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
