import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../services/api_service.dart';

class FinancingScreen extends StatefulWidget {
  const FinancingScreen({super.key});
  @override
  State<FinancingScreen> createState() => _FinancingScreenState();
}

class _FinancingScreenState extends State<FinancingScreen> {
  late Future<Map<String, dynamic>?> _future;
  int? _billId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>?> _load() async {
    final bills = await ApiService.bills();
    if (bills.isEmpty) return null;
    _billId = Bill.fromJson(bills.first as Map<String, dynamic>).id;
    return ApiService.offers(_billId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay for your bill')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Could not load offers: ${snap.error}'));
          final data = snap.data;
          if (data == null) return const Center(child: Text('Scan a bill to see payment options.'));
          final loans = data['loan_offers'] as List<dynamic>;
          final topups = data['insurance_topups'] as List<dynamic>;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Latest bill: ${rupees(data['bill_total'] as num)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text('Your health-credit score: ${data['credit_score']}'),
              const SizedBox(height: 16),
              for (final o in loans)
                Card(
                  child: ListTile(
                    title: Text(o['title'] as String),
                    subtitle: Text('${rupees(o['emi'] as num)} per month · '
                        '${o['tenure_months']} months · ${o['rate']}% a year'),
                    trailing: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(80, 40)),
                      onPressed: () async {
                        final res = await ApiService.acceptOffer({
                          'bill_id': _billId,
                          'offer_type': o['offer_type'],
                          'amount': o['amount'],
                          'tenure_months': o['tenure_months'],
                        });
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Approved. EMI ${rupees(res['emi'] as num)}')));
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text('Add cover', style: TextStyle(fontWeight: FontWeight.w700)),
              for (final t in topups)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.shield_outlined),
                  title: Text(t['name'] as String),
                  subtitle: Text('Cover ${rupees(t['cover'] as num)}'),
                  trailing: Text('${rupees(t['premium_per_month'] as num)}/mo'),
                ),
            ],
          );
        },
      ),
    );
  }
}
