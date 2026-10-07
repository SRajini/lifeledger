import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../services/api_service.dart';

class ClaimScreen extends StatefulWidget {
  const ClaimScreen({super.key});
  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  List<Bill> _bills = [];
  int? _billId;
  final _policy = TextEditingController();
  final _diagnosis = TextEditingController();
  bool _discharge = false, _rx = false, _preauth = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    ApiService.bills().then((list) => setState(() {
          _bills = list.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
          if (_bills.isNotEmpty) _billId = _bills.first.id;
        }));
  }

  Future<void> _check() async {
    final res = await ApiService.checkClaim({
      'bill_id': _billId,
      'policy_number': _policy.text,
      'diagnosis': _diagnosis.text,
      'has_discharge_summary': _discharge,
      'has_prescription': _rx,
      'pre_authorized': _preauth,
    });
    setState(() => _result = res);
  }

  Color _riskColor(String level) =>
      level == 'high' ? const Color(0xFFB3261E) : level == 'medium' ? const Color(0xFFE8A33D) : const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check your claim')),
      body: _bills.isEmpty
          ? const Center(child: Text('Scan a bill first to prepare a claim.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _billId,
                  decoration: const InputDecoration(labelText: 'Bill', border: OutlineInputBorder()),
                  items: [
                    for (final b in _bills)
                      DropdownMenuItem(value: b.id, child: Text('${b.provider} · ${rupees(b.total)}')),
                  ],
                  onChanged: (v) => setState(() => _billId = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: _policy,
                    decoration: const InputDecoration(labelText: 'Policy number', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _diagnosis,
                    decoration: const InputDecoration(labelText: 'Diagnosis', border: OutlineInputBorder())),
                SwitchListTile(title: const Text('Discharge summary attached'), value: _discharge,
                    onChanged: (v) => setState(() => _discharge = v)),
                SwitchListTile(title: const Text('Prescription attached'), value: _rx,
                    onChanged: (v) => setState(() => _rx = v)),
                SwitchListTile(title: const Text('Insurer pre-approved'), value: _preauth,
                    onChanged: (v) => setState(() => _preauth = v)),
                const SizedBox(height: 8),
                FilledButton(onPressed: _check, child: const Text('Check rejection risk')),
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  Row(children: [
                    Text('${_result!['risk_score']}%',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800,
                            color: _riskColor(_result!['risk_level'] as String))),
                    const SizedBox(width: 12),
                    Text('${_result!['risk_level']} risk of rejection'),
                  ]),
                  const SizedBox(height: 8),
                  for (final s in (_result!['suggestions'] as List<dynamic>))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.arrow_right_alt),
                      title: Text(s as String),
                    ),
                ],
              ],
            ),
    );
  }
}
