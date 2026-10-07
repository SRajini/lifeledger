import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../services/api_service.dart';
import 'scan_bill_screen.dart';
import 'claim_screen.dart';
import 'financing_screen.dart';
import 'savings_screen.dart';

/// Bottom-nav shell that hosts the five main tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      DashboardScreen(),
      ScanBillScreen(),
      ClaimScreen(),
      FinancingScreen(),
      SavingsScreen(),
    ];
    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.document_scanner_outlined), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.verified_outlined), label: 'Claims'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Pay'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), label: 'Savings'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<dynamic>> _data;

  @override
  void initState() {
    super.initState();
    _data = Future.wait([ApiService.forecast(), ApiService.refills(), ApiService.bills()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your health spending')),
      body: FutureBuilder<List<dynamic>>(
        future: _data,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Could not load: ${snap.error}'));
          final fc = snap.data![0] as Map<String, dynamic>;
          final refills = snap.data![1] as List<dynamic>;
          final bills = (snap.data![2] as List<dynamic>)
              .map((e) => Bill.fromJson(e as Map<String, dynamic>))
              .toList();
          final history = (fc['history'] as List<dynamic>);
          final maxV = history.isEmpty
              ? 1.0
              : history.map((h) => (h['total'] as num).toDouble()).reduce((a, b) => a > b ? a : b);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: const Color(0xFF0E4D4A),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Expected next month',
                          style: TextStyle(color: Colors.white70)),
                      Text(rupees(fc['predicted_next_month'] as num),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Set aside ${rupees(fc['recommended_saving'] as num)} to stay covered',
                          style: const TextStyle(color: Color(0xFFE8A33D))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Monthly spending', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final h in history)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: 90 * ((h['total'] as num).toDouble() / maxV),
                                color: const Color(0xFF0E4D4A),
                              ),
                              const SizedBox(height: 4),
                              Text((h['month'] as String).substring(5),
                                  style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Scan your first bill to see your forecast.'),
                ),
              const SizedBox(height: 16),
              const Text('Refills due', style: TextStyle(fontWeight: FontWeight.w700)),
              for (final r in refills)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.medication_outlined),
                  title: Text(r['medicine'] as String),
                  subtitle: Text('Due ${r['next_refill_date']}'
                      '${r['generic_alternative'] != null ? ' · generic available' : ''}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final res = await ApiService.order(r['medicine'] as String, 1);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Order placed. +${res['points_earned']} points')));
                    },
                    child: const Text('Reorder'),
                  ),
                ),
              if (refills.isEmpty) const Text('No refills due.'),
              const SizedBox(height: 16),
              const Text('Recent bills', style: TextStyle(fontWeight: FontWeight.w700)),
              for (final b in bills.take(5))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(b.provider),
                  subtitle: Text(b.date),
                  trailing: Text(rupees(b.total),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          );
        },
      ),
    );
  }
}
