import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/visitor_store.dart';
import '../widgets/common_widgets.dart';
import 'visitor_details_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final camera = MobileScannerController(
    autoStart: false,
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final manualId = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => startCamera());
  }

  Future<void> startCamera() async {
    if (!mounted || busy) return;
    try {
      await camera.start();
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Camera unavailable. Allow camera access in device settings, then retry. You can also enter a visitor ID.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!camera.value.hasCameraPermission) return;
    if (state == AppLifecycleState.resumed && !busy) {
      startCamera();
    } else if (state == AppLifecycleState.inactive) {
      unawaited(camera.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    manualId.dispose();
    unawaited(camera.dispose());
    super.dispose();
  }

  Future<void> lookup(String value) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final visitor = await context.read<VisitorStore>().lookup(value);
      await camera.stop();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VisitorDetailsScreen(id: visitor.id)),
      );
    } catch (e) {
      if (mounted) setState(() => error = VisitorStore.message(e));
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
    // Explicitly re-arm to avoid opening the same pass repeatedly while it is in view.
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan visitor pass')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Point your camera at the QR code',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'The visitor pass will open for you to confirm entry or exit.',
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: camera,
                        onDetect: (capture) {
                          if (capture.barcodes.isNotEmpty) {
                            final value = capture.barcodes.first.rawValue;
                            if (value != null) lookup(value);
                          }
                        },
                        errorBuilder: (context, error) => const ColoredBox(
                          color: Color(0xffe5efeb),
                          child: EmptyState(
                            icon: Icons.no_photography_outlined,
                            title: 'Camera unavailable',
                            message:
                                'Enable camera permission in device settings or use a visitor ID below.',
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      if (busy) const CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        await camera.stop();
                        await startCamera();
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('Scan again / retry camera'),
              ),
              const SizedBox(height: 24),
              const Text('Have a visitor ID instead?'),
              const SizedBox(height: 8),
              TextField(
                controller: manualId,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Visitor ID',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                onSubmitted: busy ? null : lookup,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy ? null : () => lookup(manualId.text),
                child: Text(busy ? 'Finding visitor…' : 'Find visitor'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
