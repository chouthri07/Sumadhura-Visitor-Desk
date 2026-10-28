import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key, required this.url, required this.onSave});
  final String url;
  final Future<void> Function(String) onSave;
  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController controller = TextEditingController(
    text: widget.url,
  );
  bool busy = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('API connection')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Connect your mock service',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create a visitors resource in MockAPI and paste its full HTTPS collection URL below. No separate backend code is needed. Leave blank to use the local demo.',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: controller,
                  enabled: !busy,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Visitors collection URL',
                    hintText: 'https://your-project.mockapi.io/api/v1/visitors',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final uri = Uri.tryParse(value.trim());
                    return uri != null &&
                            uri.scheme == 'https' &&
                            uri.host.isNotEmpty &&
                            !uri.hasQuery &&
                            !uri.hasFragment
                        ? null
                        : 'Enter a valid HTTPS collection URL';
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Local and API records are kept separate. Switching the connection does not upload or delete your local demo data. Use test data only; no API secrets are needed for a public mock resource.',
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if (!form.currentState!.validate()) return;
                          setState(() => busy = true);
                          try {
                            // Pop before replacing the application provider and navigator.
                            final value = controller.text.trim().replaceAll(
                              RegExp(r'/+$'),
                              '',
                            );
                            final save = widget.onSave;
                            Navigator.pop(context);
                            await save(value);
                          } catch (e) {
                            if (context.mounted) {
                              showMessage(context, 'Unable to save connection');
                              setState(() => busy = false);
                            }
                          }
                        },
                  child: const Text('Save connection'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
