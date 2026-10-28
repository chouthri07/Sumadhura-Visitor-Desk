import 'api_settings_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/visitor.dart';
import '../providers/visitor_store.dart';
import '../widgets/common_widgets.dart';
import 'visitor_details_screen.dart';
import 'visitor_form_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isDemo,
    this.apiUrl = '',
    this.onConfigure,
  });
  final bool isDemo;
  final String apiUrl;
  final Future<void> Function(String)? onConfigure;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int index = 0;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      context.read<VisitorStore>().load();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void register() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const VisitorFormScreen()),
  );
  Future<void> scan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<VisitorStore>();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SUMADHURA',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 3,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              index == 0 ? 'Visitor desk' : 'Visitors',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          if (widget.onConfigure != null)
            IconButton(
              tooltip: 'API connection',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApiSettingsScreen(
                    url: widget.apiUrl,
                    onSave: widget.onConfigure!,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Refresh visitors',
            onPressed: store.loading ? null : store.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              children: [
                if (widget.isDemo)
                  Container(
                    width: double.infinity,
                    color: const Color(0xffffedc5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: const Text(
                      'LOCAL DEMO  ·  Saved on this device. REST API is not configured.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                if (store.loading) const LinearProgressIndicator(),
                if (store.error != null)
                  MaterialBanner(
                    content: Text(store.error!),
                    actions: [
                      TextButton(
                        onPressed: store.load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                Expanded(child: index == 0 ? dashboard(store) : listing(store)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: index == 1
          ? FloatingActionButton.extended(
              onPressed: register,
              icon: const Icon(Icons.add),
              label: const Text('Register visitor'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          if (value == 2) {
            scan();
          } else {
            setState(() => index = value);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Visitors',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan QR',
          ),
        ],
      ),
    );
  }

  Widget dashboard(VisitorStore store) => RefreshIndicator(
    onRefresh: store.load,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()).toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1.4,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Every visit,\nwell managed.',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text('A clear view of your front desk today.'),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final stats = [
              stat(
                'Visitors today',
                store.registeredToday(DateTime.now()),
                Icons.person_add_alt_1_outlined,
              ),
              stat('Currently checked in', store.checkedIn, Icons.login),
              stat(
                'Checked out today',
                store.checkedOutToday(DateTime.now()),
                Icons.logout,
              ),
            ];
            return constraints.maxWidth < 480
                ? Column(children: stats)
                : Row(children: stats.map((s) => Expanded(child: s)).toList());
          },
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: register,
          icon: const Icon(Icons.add),
          label: const Text('Register visitor'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: scan,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan visitor pass'),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent visitors',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => index = 1),
              child: const Text('View all'),
            ),
          ],
        ),
        if (store.visitors.isEmpty && !store.loading)
          const EmptyState(
            title: 'Ready for your first visitor',
            message:
                'Register a visitor to create a pass and begin their visit.',
          ),
        ...store.visitors
            .take(4)
            .map((v) => VisitorCard(visitor: v, onTap: () => openDetails(v))),
      ],
    ),
  );
  Widget stat(String label, int count, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
  Widget listing(VisitorStore store) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              initialValue: store.query,
              onChanged: (value) => store.filter(search: value),
              decoration: const InputDecoration(
                hintText: 'Search name or mobile number',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: store.projectFilter ?? 'All projects',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Project'),
                    items:
                        ['All projects', 'Project A', 'Project B', 'Project C']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) => store.filter(
                      setFilters: true,
                      project: v == 'All projects' ? null : v,
                      status: store.statusFilter,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: store.statusFilter?.label ?? 'All statuses',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items:
                        [
                              'All statuses',
                              ...VisitStatus.values.map((s) => s.label),
                            ]
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => store.filter(
                      setFilters: true,
                      project: store.projectFilter,
                      status: v == 'All statuses' ? null : VisitStatus.parse(v),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: store.load,
          child: store.filtered.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    EmptyState(
                      title: store.query.isEmpty
                          ? 'No visitors to show'
                          : 'No matching visitors',
                      message:
                          'Register a visitor or adjust your search and filters.',
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                  itemCount: store.filtered.length,
                  itemBuilder: (_, i) {
                    final v = store.filtered[i];
                    return VisitorCard(
                      visitor: v,
                      onTap: () => openDetails(v),
                      onEdit: store.saving
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VisitorFormScreen(visitor: v),
                              ),
                            ),
                      onDelete: store.saving
                          ? null
                          : () => confirmDelete(context, v),
                    );
                  },
                ),
        ),
      ),
    ],
  );
  void openDetails(Visitor visitor) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => VisitorDetailsScreen(id: visitor.id)),
  );
}

Future<bool> confirmDelete(BuildContext context, Visitor visitor) async {
  final store = context.read<VisitorStore>();
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete visitor?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Delete ${visitor.name} and their visitor pass? This cannot be undone.',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  try {
    await store.delete(visitor.id);
    if (context.mounted) showMessage(context, 'Visitor deleted');
    return true;
  } catch (e) {
    if (context.mounted) showMessage(context, VisitorStore.message(e));
    return false;
  }
}
