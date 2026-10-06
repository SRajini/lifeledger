import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/bill.dart';
import '../services/api_service.dart';

class ScanBillScreen extends StatefulWidget {
  const ScanBillScreen({super.key});
  @override
  State<ScanBillScreen> createState() => _ScanBillScreenState();
}

class _ScanBillScreenState extends State<ScanBillScreen> {
  Bill? _bill;
  bool _busy = false;
  String? _error;

  Future<void> _scan(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      final json = await ApiService.uploadBill(file.path);
      setState(() => _bill = Bill.fromJson(json));
    } catch (e) {
      setState(() => _error = 'Could not read this bill. Try a clearer photo.');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a bill')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : () => _scan(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Take photo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: _busy ? null : () => _scan(ImageSource.gallery),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Upload'),
              ),
            ),
          ]),
          if (_busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (_error != null)
            Padding(padding: const EdgeInsets.only(top: 16),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFB3261E)))),
          if (_bill == null && !_busy)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Text('Add a hospital bill, lab report or pharmacy receipt. '
                  'We read it, check prices and update your forecast.'),
            ),
          if (_bill != null) ...[
            const SizedBox(height: 20),
            Text(_bill!.provider, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text('${_bill!.date} · Total ${rupees(_bill!.total)}'),
            const SizedBox(height: 12),
            if (_bill!.flags.isNotEmpty)
              Card(
                color: const Color(0xFFFCE8E6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Check these prices', style: TextStyle(fontWeight: FontWeight.w700)),
                      for (final f in _bill!.flags) Padding(padding: const EdgeInsets.only(top: 4), child: Text(f)),
                    ],
                  ),
                ),
              ),
            for (final it in _bill!.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(it.name),
                subtitle: Text('${it.category} · qty ${it.qty}'),
                trailing: Text(rupees(it.price)),
              ),
          ],
        ],
      ),
    );
  }
}
