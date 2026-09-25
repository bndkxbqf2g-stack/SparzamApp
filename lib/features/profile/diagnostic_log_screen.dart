import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/diagnostic_log_entry.dart';
import '../../services/diagnostic_log_service.dart';

class DiagnosticLogScreen extends StatefulWidget {
  const DiagnosticLogScreen({super.key, required this.service});

  final DiagnosticLogService service;

  @override
  State<DiagnosticLogScreen> createState() => _DiagnosticLogScreenState();
}

class _DiagnosticLogScreenState extends State<DiagnosticLogScreen> {
  final category = TextEditingController(text: 'Praxistest');
  final message = TextEditingController();
  final details = TextEditingController();
  List<DiagnosticLogEntry> entries = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    category.dispose();
    message.dispose();
    details.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final loaded = await widget.service.load();
    if (mounted) setState(() => entries = loaded);
  }

  Future<void> _record() async {
    if (message.text.trim().isEmpty) return;
    await widget.service.record(
      category: category.text,
      message: message.text,
      details: details.text,
    );
    message.clear();
    details.clear();
    await _reload();
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(text: await widget.service.exportText()),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnoseprotokoll kopiert.')),
      );
    }
  }

  Future<void> _clear() async {
    await widget.service.clear();
    await _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Diagnoseprotokoll')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Fehler hier erfassen und das Protokoll anschließend kopieren und im Chat einfügen.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: category,
              decoration: const InputDecoration(labelText: 'Bereich'),
            ),
            TextField(
              controller: message,
              decoration: const InputDecoration(labelText: 'Kurzbeschreibung'),
            ),
            TextField(
              controller: details,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Details / Schritte'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _record,
              icon: const Icon(Icons.add),
              label: const Text('Fehler speichern'),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copy,
                    icon: const Icon(Icons.copy),
                    label: const Text('Log kopieren'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clear,
                  tooltip: 'Log löschen',
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const Divider(height: 28),
            if (entries.isEmpty)
              const Text('Noch keine Diagnoseeinträge.')
            else
              ...entries.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${entry.category}: ${entry.message}'),
                  subtitle: Text(
                    '${entry.timestamp.toLocal()}\n${entry.details ?? ''}',
                  ),
                ),
              ),
          ],
        ),
      );
}
