import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/visitor.dart';
import '../providers/visitor_store.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';
import 'visitor_form_screen.dart';

class VisitorDetailsScreen extends StatelessWidget {
  const VisitorDetailsScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<VisitorStore>();
    final v = store.find(id);
    if (v == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visitor details')),
        body: const EmptyState(
          title: 'Visitor unavailable',
          message: 'This visitor may have been deleted.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor pass'),
        actions: [
          IconButton(
            tooltip: 'Edit visitor',
            onPressed: store.saving
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VisitorFormScreen(visitor: v),
                    ),
                  ),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete visitor',
            onPressed: store.saving
                ? null
                : () async {
                    if (await confirmDelete(context, v) && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 36,
                          color: Color(0xff175c51),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          v.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        Text('${v.visitorType} · ${v.project}'),
                        const SizedBox(height: 8),
                        StatusChip(v.status),
                        const SizedBox(height: 16),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(8),
                          child: QrImageView(
                            data: v.id,
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          v.id,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Show this pass at the security desk',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        info('Mobile number', v.mobile),
                        if (v.email != null && v.email!.isNotEmpty)
                          info('Email', v.email!),
                        info('Purpose of visit', v.purpose),
                        info('Registered', displayTime(v.createdAt)),
                        info('Check-in', displayTime(v.checkInTime)),
                        info('Check-out', displayTime(v.checkOutTime)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (v.status != VisitStatus.checkedOut)
                  FilledButton.icon(
                    onPressed: store.saving
                        ? null
                        : () => runAction(
                            context,
                            () => store.changeStatus(
                              id,
                              v.status == VisitStatus.registered
                                  ? VisitStatus.checkedIn
                                  : VisitStatus.checkedOut,
                            ),
                            v.status == VisitStatus.registered
                                ? 'Visitor checked in'
                                : 'Visitor checked out',
                          ),
                    icon: store.saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            v.status == VisitStatus.registered
                                ? Icons.login
                                : Icons.logout,
                          ),
                    label: Text(
                      store.saving
                          ? 'Saving…'
                          : v.status == VisitStatus.registered
                          ? 'Check in visitor'
                          : 'Check out visitor',
                    ),
                  )
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.task_alt, color: Color(0xff175c51)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Visit completed. Register a new visit for a return arrival.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget info(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        SelectableText(value),
      ],
    ),
  );
}
