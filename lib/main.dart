import 'package:flutter/material.dart';

const String kCurrency = '₹'; // change this to $ or € if you like

void main() {
  runApp(const LifeLedgerApp());
}

class LifeLedgerApp extends StatelessWidget {
  const LifeLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeLedger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Entry {
  final String title;
  final double amount;
  final bool isIncome;
  final DateTime date;

  const Entry({
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Entry> _entries = [];

  double get _income =>
      _entries.where((e) => e.isIncome).fold(0, (sum, e) => sum + e.amount);

  double get _expense =>
      _entries.where((e) => !e.isIncome).fold(0, (sum, e) => sum + e.amount);

  double get _balance => _income - _expense;

  Future<void> _addEntry() async {
    final entry = await showDialog<Entry>(
      context: context,
      builder: (_) => const AddEntryDialog(),
    );
    if (entry != null) {
      setState(() => _entries.insert(0, entry));
    }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.inversePrimary,
        title: const Text('LifeLedger'),
      ),
      body: Column(
        children: [
          // Summary card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Balance'),
                  Text(
                    '$kCurrency${_balance.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Income: $kCurrency${_income.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.green),
                      ),
                      Text(
                        'Expenses: $kCurrency${_expense.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Entry list
          Expanded(
            child: _entries.isEmpty
                ? const Center(child: Text('No entries yet. Tap + to add one.'))
                : ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, i) {
                      final e = _entries[i];
                      return Dismissible(
                        key: ObjectKey(e),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => setState(() => _entries.remove(e)),
                        child: ListTile(
                          leading: Icon(
                            e.isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: e.isIncome ? Colors.green : Colors.red,
                          ),
                          title: Text(e.title),
                          subtitle: Text(_fmtDate(e.date)),
                          trailing: Text(
                            '${e.isIncome ? '+' : '-'}$kCurrency${e.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: e.isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        tooltip: 'Add entry',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddEntryDialog extends StatefulWidget {
  const AddEntryDialog({super.key});

  @override
  State<AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _isIncome = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (title.isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'Enter a title and an amount greater than 0');
      return;
    }
    Navigator.pop(
      context,
      Entry(
        title: title,
        amount: amount,
        isIncome: _isIncome,
        date: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Expense')),
              ButtonSegment(value: true, label: Text('Income')),
            ],
            selected: {_isIncome},
            onSelectionChanged: (s) => setState(() => _isIncome = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
            onSubmitted: (_) => _save(),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}