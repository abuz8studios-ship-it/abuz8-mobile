import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_controller.dart';

class ConnectionSettings extends StatefulWidget {
  const ConnectionSettings({super.key});
  @override
  State<ConnectionSettings> createState() => _ConnectionSettingsState();
}

class _ConnectionSettingsState extends State<ConnectionSettings> {
  final _urlCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<ChatController>();
    _urlCtrl.text = ctrl._gatewayUrl;
    _tokenCtrl.text = ctrl._token;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<ChatController>().saveSettings(
          _urlCtrl.text.trim(),
          _tokenCtrl.text.trim(),
        );
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Gateway Connection', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'Gateway URL',
              hintText: 'http://100.x.x.x:18789',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Auth Token',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save & Connect'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
