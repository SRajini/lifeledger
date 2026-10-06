import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../services/api_service.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});
  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  late Future<Map<String, dynamic>> _future = ApiService.savings();

  Future<void> _add(double amount) async {
    await ApiService.contribute(amount);
    setState(() => _future = ApiService.savings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health savings')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final p = snap.data!;
          final saved = (p['saved'] as num).toDouble();
          final target = (p['target'] as num).toDouble();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(p['goal'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: (saved / target).clamp(0, 1), minHeight: 12),
              const SizedBox(height: 8),
              Text('${rupees(saved)} of ${rupees(target)}'),
              Text('Auto-debit ${rupees(p['monthly_autodebit'] as num)} each month'),
              const SizedBox(height: 20),
              Wrap(spacing: 8, children: [
                for (final a in [500.0, 1000.0, 2000.0])
                  ActionChip(label: Text('Add ${rupees(a)}'), onPressed: () => _add(a)),
              ]),
            ],
          );
        },
      ),
    );
  }
}
