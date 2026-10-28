import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/visitor.dart';
import '../providers/visitor_store.dart';
import '../widgets/common_widgets.dart';
import 'visitor_details_screen.dart';

class VisitorFormScreen extends StatefulWidget {
  const VisitorFormScreen({super.key, this.visitor});
  final Visitor? visitor;
  @override
  State<VisitorFormScreen> createState() => _VisitorFormScreenState();
}

class _VisitorFormScreenState extends State<VisitorFormScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, mobile, email, purpose;
  late String type, project;
  @override
  void initState() {
    super.initState();
    final v = widget.visitor;
    name = TextEditingController(text: v?.name);
    mobile = TextEditingController(text: v?.mobile);
    email = TextEditingController(text: v?.email);
    purpose = TextEditingController(text: v?.purpose);
    type = v?.visitorType ?? 'Customer';
    project = v?.project ?? 'Project A';
  }

  @override
  void dispose() {
    name.dispose();
    mobile.dispose();
    email.dispose();
    purpose.dispose();
    super.dispose();
  }

  String? requiredValue(String? v) =>
      v == null || v.trim().isEmpty ? 'This field is required' : null;
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    try {
      final visitor = await context.read<VisitorStore>().save({
        'name': name.text.trim(),
        'mobile': mobile.text.trim(),
        'email': email.text.trim().isEmpty ? null : email.text.trim(),
        'visitor_type': type,
        'project': project,
        'purpose': purpose.text.trim(),
      }, id: widget.visitor?.id);
      if (!mounted) return;
      showMessage(
        context,
        widget.visitor == null
            ? 'Visitor registered. Their QR pass is ready.'
            : 'Visitor updated',
      );
      if (widget.visitor != null) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VisitorDetailsScreen(id: visitor.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, VisitorStore.message(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<VisitorStore>().saving;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.visitor == null ? 'Register visitor' : 'Edit visitor',
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: form,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Text(
                      'Visitor information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Create a pass for a smooth arrival. * Required fields',
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: name,
                      enabled: !busy,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Visitor name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: requiredValue,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: mobile,
                      enabled: !busy,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Mobile number *',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => RegExp(r'^\d{10}$').hasMatch(v ?? '')
                          ? null
                          : 'Enter exactly 10 digits',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: email,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) =>
                          v == null ||
                              v.trim().isEmpty ||
                              RegExp(
                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                              ).hasMatch(v.trim())
                          ? null
                          : 'Enter a valid email address',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Visitor type *',
                      ),
                      items: ['Customer', 'Vendor', 'Other']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: busy ? null : (v) => setState(() => type = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: project,
                      decoration: const InputDecoration(labelText: 'Project *'),
                      items: ['Project A', 'Project B', 'Project C']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: busy
                          ? null
                          : (v) => setState(() => project = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: purpose,
                      enabled: !busy,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Purpose of visit *',
                        alignLabelWithHint: true,
                      ),
                      validator: requiredValue,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: busy ? null : save,
                      icon: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        busy
                            ? 'Saving…'
                            : widget.visitor == null
                            ? 'Register & generate pass'
                            : 'Save changes',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: busy ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
