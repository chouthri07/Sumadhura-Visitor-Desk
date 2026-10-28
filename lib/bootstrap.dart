import 'repositories/local_visitor_repository.dart';
import 'repositories/api_visitor_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'repositories/visitor_repository.dart';
import 'providers/visitor_store.dart';

class VisitorBootstrap extends StatefulWidget {
  const VisitorBootstrap({super.key, required this.preferences});
  final SharedPreferences preferences;
  
  @override
  State<VisitorBootstrap> createState() => _VisitorBootstrapState();
}

class _VisitorBootstrapState extends State<VisitorBootstrap> {
  late String url;
  @override
  void initState() {
    super.initState();
    url =
        widget.preferences.getString('api_url') ??
        const String.fromEnvironment('API_BASE_URL');
  }

  Future<void> configure(String value) async {
    if (!await widget.preferences.setString('api_url', value)) {
      throw const VisitorException('Unable to save API configuration.');
    }
    if (mounted) setState(() => url = value);
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    key: ValueKey(url),
    create: (_) => VisitorStore(
      url.isEmpty
          ? LocalVisitorRepository(widget.preferences)
          : ApiVisitorRepository(url),
    )..load(),
    child: VisitorApp(isDemo: url.isEmpty, apiUrl: url, onConfigure: configure),
  );
}
