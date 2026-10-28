import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Image.asset(
                'assets/images/sumadhura-logo.png',
                fit: BoxFit.contain,
                semanticLabel: 'Sumadhura — Foundation of Happiness',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
