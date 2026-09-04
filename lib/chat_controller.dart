import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Msg {
  final String role; // 'user' | 'assistant' | 'system'
  final String text;
  final String time;
  Msg({required this.role, required this.text, required this.time});
}

class ChatController extends ChangeNotifier {
  final List<Msg> messages = [];
  bool _connected = false;
  bool get connected => _connected;

  String _gatewayUrl = 'ws://localhost:18789';
  String _token = '';
  static const _prefsKeyUrl = 'abuz8_gateway_url';
  static const _prefsKeyToken = 'abuz8_gateway_token';

  WebSocket? _ws;
  int _idSeq = 0;
  bool _connecting = false;

  ChatController() {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _gatewayUrl = p.getString(_prefsKeyUrl) ?? 'ws://localhost:18789';
    _token = p.getString(_prefsKeyToken) ?? '';
    if (_token.isNotEmpty) {
      await connect();
    }
    notifyListeners();
  }

  Future<void> saveSettings(String url, String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKeyUrl, url);
    await p.setString(_prefsKeyToken, token);
    _gatewayUrl = url;
    _token = token;
    notifyListeners();
    await connect();
  }

  void pushUser(String text) {
    messages.add(Msg(role: 'user', text: text, time: _now()));
    notifyListeners();
  }

  String _now() {
    final d = DateTime.now();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  // Connects to the OpenClaw gateway over WebSocket and authenticates.
  // The gateway speaks JSON-RPC 2.0 with a connect.challenge handshake:
  //   server -> {"type":"event","event":"connect.challenge","payload":{"nonce":"..."}}
  //   client -> {"jsonrpc":"2.0","id":1,"method":"connect","params":{"auth":{"token":"..."}}}
  // Then chat via {"method":"chat.run","params":{"message":"..."}}.
  Future<void> connect() async {
    if (_ws != null || _connecting) return;
    if (_token.isEmpty) {
      _connected = false;
      notifyListeners();
      return;
    }
    _connecting = true;
    notifyListeners();
    try {
      final uri = Uri.parse(_gatewayUrl);
      _ws = await WebSocket.connect(uri.toString(), headers: {});
      _ws!.listen(
        (data) => _onData(data),
        onError: (e) {
          _connected = false;
          messages.add(Msg(role: 'system', text: '⚠ WS error: $e', time: _now()));
          notifyListeners();
        },
        onDone: () {
          _connected = false;
          notifyListeners();
        },
      );
      // Wait for the challenge, then send auth token.
      final completer = Completer<void>();
      final handler = _ws!.listen((data) {
        if (completer.isCompleted) return;
        try {
          final d = jsonDecode(data);
          if (d['event'] == 'connect.challenge') {
            _ws!.add(jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'method': 'connect',
              'params': {
                'role': 'node',
                'client': {'name': 'ABUZ8 Mobile', 'version': '1.0.0'},
                'auth': {'token': _token},
              },
            }));
            completer.complete();
          }
        } catch (_) {}
      });
      await completer.future.timeout(const Duration(seconds: 10));
      handler.cancel();
      _connected = true;
    } catch (e) {
      _connected = false;
      messages.add(
        Msg(
          role: 'system',
          text: '⚠ Connection failed: $e\nCheck URL + token (must be ws:// or wss://).',
          time: _now(),
        ),
      );
      _ws = null;
    }
    _connecting = false;
    notifyListeners();
  }

  void _onData(dynamic data) {
    try {
      final d = jsonDecode(data);
      // After connect, the gateway sends hello-ok or auth results.
      if (d.containsKey('result') || d['event'] == 'auth.result') {
        _connected = true;
        notifyListeners();
        return;
      }
      // chat.run responses.
      final result = d['result'];
      if (result != null && result['event'] == 'chat.run' && result.containsKey('data')) {
        final rdata = result['data'];
        final text = rdata['content'] ?? rdata['message'] ?? rdata['text'] ?? '';
        messages.add(Msg(role: 'assistant', text: text.toString(), time: _now()));
        notifyListeners();
      }
    } catch (_) {
      // ignore non-JSON control frames
    }
  }

  Future<String> send() async {
    if (_ws == null || !_connected) {
      final err = 'Not connected. Tap ⚙ → set URL + token → Save & Connect.';
      messages.add(Msg(role: 'system', text: err, time: _now()));
      notifyListeners();
      return err;
    }
    final userMsg = messages.lastWhere((m) => m.role == 'user', orElse: () => Msg(role: 'user', text: '', time: _now()));
    final id = ++_idSeq;
    _ws!.add(jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': 'chat.run',
      'params': {
        'message': userMsg.text,
        'sessionKey': 'abuz8-mobile',
        'options': {'thinking': 'medium', 'stream': false},
      },
    }));
    return userMsg.text;
  }

  void disconnect() {
    _ws?.close();
    _ws = null;
    _connected = false;
    notifyListeners();
  }
}

