import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/visitor.dart';
import '../providers/visitor_store.dart';

String displayTime(DateTime? value) => value == null
    ? 'Not yet'
    : DateFormat('dd MMM yyyy, h:mm a').format(value.toLocal());
OverlayEntry? _messageToast;

void showMessage(BuildContext context, String text) {
  _messageToast?.remove();
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry toast;
  toast = OverlayEntry(
    builder: (context) => _ToastLifetime(
      onDismiss: () {
        toast.remove();
        if (identical(_messageToast, toast)) _messageToast = null;
      },
      child: Positioned(
        left: 24,
        right: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            80,
        child: IgnorePointer(
          child: Center(
            child: Semantics(
              liveRegion: true,
              child: Material(
                color: const Color(0xee323232),
                borderRadius: BorderRadius.circular(24),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  _messageToast = toast;
  overlay.insert(toast);
}

class _ToastLifetime extends StatefulWidget {
  const _ToastLifetime({required this.child, required this.onDismiss});
  final Widget child;
  final VoidCallback onDismiss;

  @override
  State<_ToastLifetime> createState() => _ToastLifetimeState();
}

class _ToastLifetimeState extends State<_ToastLifetime> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), widget.onDismiss);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> runAction(
  BuildContext context,
  Future<void> Function() action,
  String success,
) async {
  try {
    await action();
    if (context.mounted) showMessage(context, success);
  } catch (e) {
    if (context.mounted) showMessage(context, VisitorStore.message(e));
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final VisitStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      VisitStatus.registered => const Color(0xff926400),
      VisitStatus.checkedIn => const Color(0xff126b50),
      VisitStatus.checkedOut => const Color(0xff53647b),
    };
    return Chip(
      label: Text(status.label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withValues(alpha: .09),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.icon = Icons.people_outline,
  });
  final String title, message;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null)
            Padding(padding: const EdgeInsets.only(top: 20), child: action),
        ],
      ),
    ),
  );
}

class VisitorCard extends StatelessWidget {
  const VisitorCard({
    super.key,
    required this.visitor,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });
  final Visitor visitor;
  final VoidCallback onTap;
  final VoidCallback? onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xffe5efeb),
                  child: Text(visitor.name.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visitor.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        visitor.mobile,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                StatusChip(visitor.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.apartment_outlined, size: 17),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${visitor.project} · ${visitor.visitorType}'),
                ),
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Edit visitor',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Delete visitor',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
