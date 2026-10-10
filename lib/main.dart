import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kCurrency = '₹'; // change this to $ or € if you like

const List<String> kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String money(double v) =>
    '${v < 0 ? '-' : ''}$kCurrency${v.abs().toStringAsFixed(2)}';

String fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

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

  Map<String, dynamic> toJson() => {
        'title': title,
        'amount': amount,
        'isIncome': isIncome,
        'date': date.toIso8601String(),
      };

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        isIncome: json['isIncome'] as bool,
        date: DateTime.parse(json['date'] as String),
      );
}

bool sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

double sumFor(List<Entry> entries, DateTime month, {required bool income}) {
  double total = 0;
  for (final e in entries) {
    if (e.isIncome == income && sameMonth(e.date, month)) {
      total += e.amount;
    }
  }
  return total;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Entry> _entries = [];
  late DateTime _month;

  bool _searching = false;
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  @override
  void initState() {
    super.initState();
    _month = _currentMonth;
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('entries');
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => Entry.fromJson(e as Map<String, dynamic>))
        .toList();
    if (!mounted) return;
    setState(() => _entries.addAll(list));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'entries',
      jsonEncode(_entries.map((e) => e.toJson()).toList()),
    );
  }

  List<Entry> get _monthEntries =>
      _entries.where((e) => sameMonth(e.date, _month)).toList();

  /// Searches ALL entries (not just the selected month) by title, amount or date.
  List<Entry> get _searchResults {
    final q = _query.toLowerCase();
    final results = _entries.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.amount.toStringAsFixed(2).contains(q) ||
          e.amount.toString().contains(q) ||
          fmtDate(e.date).contains(q) ||
          kMonths[e.date.month - 1].toLowerCase().contains(q);
    }).toList();
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  double get _income => sumFor(_entries, _month, income: true);
  double get _expense => sumFor(_entries, _month, income: false);
  double get _net => _income - _expense;

  bool get _isCurrentMonth => sameMonth(_month, _currentMonth);

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _startSearch() => setState(() => _searching = true);

  void _stopSearch() {
    setState(() {
      _searching = false;
      _query = '';
      _searchCtrl.clear();
    });
  }

  Future<void> _addEntry() async {
    final entry = await showDialog<Entry>(
      context: context,
      builder: (_) => const AddEntryDialog(),
    );
    if (entry != null) {
      setState(() {
        _entries.insert(0, entry);
        _month = _currentMonth; // jump to the month the entry was added in
      });
      _save();
    }
  }

  Future<bool> _confirmDelete(Entry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text(
          '${e.title}  (${e.isIncome ? '+' : '-'}$kCurrency${e.amount.toStringAsFixed(2)})\n'
          'on ${fmtDate(e.date)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _removeEntry(Entry e) {
    final index = _entries.indexOf(e);
    if (index < 0) return;
    setState(() => _entries.removeAt(index));
    _save();

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${e.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _entries.insert(math.min(index, _entries.length), e));
            _save();
          },
        ),
      ),
    );
  }

  Widget _entryTile(Entry e) {
    return Dismissible(
      key: ObjectKey(e),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(e),
      onDismissed: (_) => _removeEntry(e),
      child: ListTile(
        leading: Icon(
          e.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: e.isIncome ? Colors.green : Colors.red,
        ),
        title: Text(e.title),
        subtitle: Text(fmtDate(e.date)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${e.isIncome ? '+' : '-'}$kCurrency${e.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: e.isIncome ? Colors.green : Colors.red,
              ),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await _confirmDelete(e)) _removeEntry(e);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBody() {
    if (_query.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Search all your history by title, amount, month or date.\n'
            'Example: "salary", "5000", "Sep" or "10/10/2026"',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final results = _searchResults;
    if (results.isEmpty) {
      return Center(child: Text('No entries match "$_query".'));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${results.length} ${results.length == 1 ? 'result' : 'results'}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final e in results) _entryTile(e),
      ],
    );
  }

  Widget _homeBody() {
    final textTheme = Theme.of(context).textTheme;
    final monthEntries = _monthEntries;

    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        // Welcome banner
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              const Icon(Icons.waving_hand, color: Colors.amber, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, welcome!', style: textTheme.headlineSmall),
                    Text(
                      '${greeting()}. Here is your money at a glance.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Month selector
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              SizedBox(
                width: 150,
                child: Text(
                  '${kMonths[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: _isCurrentMonth ? null : () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),

        // Monthly summary card
        Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Net this month'),
                Text(
                  money(_net),
                  style: textTheme.headlineMedium?.copyWith(
                    color: _net < 0 ? Colors.red : null,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'Income: ${money(_income)}',
                      style: const TextStyle(color: Colors.green),
                    ),
                    Text(
                      'Expenses: ${money(_expense)}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Chart card
        Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Last 6 months', style: textTheme.titleSmall),
                    const Spacer(),
                    const _LegendDot(color: Colors.green, label: 'Income'),
                    const SizedBox(width: 12),
                    const _LegendDot(color: Colors.red, label: 'Expenses'),
                  ],
                ),
                const SizedBox(height: 16),
                MonthlyChart(entries: _entries, endMonth: _month),
              ],
            ),
          ),
        ),

        // Entry list for the selected month
        if (_entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No entries yet. Tap + to add one.')),
          )
        else if (monthEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No entries in this month.')),
          )
        else
          for (final e in monthEntries) _entryTile(e),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.inversePrimary,
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search title, amount or date',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              )
            : const Text('LifeLedger'),
        actions: [
          if (_searching)
            IconButton(
              tooltip: 'Close search',
              icon: const Icon(Icons.close),
              onPressed: _stopSearch,
            )
          else
            IconButton(
              tooltip: 'Search history',
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
            ),
        ],
      ),
      body: _searching ? _searchBody() : _homeBody(),
      floatingActionButton: _searching
          ? null
          : FloatingActionButton(
              onPressed: _addEntry,
              tooltip: 'Add entry',
              child: const Icon(Icons.add),
            ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Simple bar chart: income and expenses for the 6 months ending at [endMonth].
class MonthlyChart extends StatelessWidget {
  final List<Entry> entries;
  final DateTime endMonth;

  const MonthlyChart({
    super.key,
    required this.entries,
    required this.endMonth,
  });

  static const double _chartHeight = 110;

  Widget _bar(double value, double maxValue, Color color) {
    final h = value <= 0 ? 0.0 : math.max(3.0, value / maxValue * _chartHeight);
    return Container(
      width: 14,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = List.generate(
      6,
      (i) => DateTime(endMonth.year, endMonth.month - 5 + i),
    );
    final incomes = [for (final m in months) sumFor(entries, m, income: true)];
    final expenses = [for (final m in months) sumFor(entries, m, income: false)];
    final maxValue = math.max(1.0, [...incomes, ...expenses].reduce(math.max));

    return Row(
      children: [
        for (int i = 0; i < months.length; i++)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: _chartHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _bar(incomes[i], maxValue, Colors.green),
                      const SizedBox(width: 3),
                      _bar(expenses[i], maxValue, Colors.red),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  kMonths[months[i].month - 1],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: sameMonth(months[i], endMonth)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
      ],
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