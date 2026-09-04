import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_controller.dart';
import 'connection_settings.dart';

void main() {
  runApp(const ABUZ8App());
}

class ABUZ8App extends StatelessWidget {
  const ABUZ8App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatController(),
      child: MaterialApp(
        title: 'ABUZ8',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC8A55C),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFAF8F5),
        ),
        home: const ChatScreen(),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final ctrl = context.read<ChatController>();
    ctrl.pushUser(text);
    _controller.clear();
    setState(() => _sending = true);
    final reply = await ctrl.send();
    setState(() => _sending = false);
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 200,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ChatController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ABUZ8'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!ctrl.connected)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Not connected to gateway. Tap ⚙ → set URL + token.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: ctrl.messages.length,
              itemBuilder: (c, i) {
                final m = ctrl.messages[i];
                return _Bubble(
                  text: m.text,
                  isUser: m.role == 'user',
                  time: m.time,
                );
              },
            ),
          ),
          _Composer(
            controller: _controller,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ConnectionSettings(),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String time;
  const _Bubble({required this.text, required this.isUser, required this.time});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUser ? 16 : 4),
            topRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(text, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(fontSize: 10, opacity: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !sending,
                decoration: const InputDecoration(
                  hintText: 'Message ABUZ8…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
