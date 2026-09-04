# ABUZ8 Mobile

A Flutter app (chat + voice) that connects to your OpenClaw/Hermes gateway over WebSocket and talks to your brain from your phone.

## What it does
- Real-time chat with your AI agent (Hermes / OpenClaw)
- Connects via WebSocket to your gateway
- Sets gateway URL + auth token on the phone
- Free to build and test — no Mac needed (GitHub Actions builds in Apple's cloud)

## Files
- `lib/main.dart` — chat UI (chat bubbles, composer, connection banner)
- `lib/chat_controller.dart` — WebSocket connection, JSON-RPC auth + chat.run
- `lib/connection_settings.dart` — set gateway URL + auth token
- `.github/workflows/ios.yml` — builds iOS + uploads to Appetize on push
- `pubspec.yaml` — dependencies

## Test on iPhone (free, no Mac, no Apple fee)
1. Push `main` → GitHub Actions builds the iOS Simulator app on a free Mac runner
2. It uploads to Appetize.io (needs an `APPETIZE_API_KEY` secret)
3. Open the link → tap the app live in your browser (cloud iPhone)

## Connect to your brain
1. Open the app → tap ⚙ (top right)
2. Gateway URL: your gateway address (e.g. `wss://100.x.x.x:18789` via Tailscale, or public URL)
3. Auth Token: your gateway token (from `~/.openclaw/openclaw.json`, `gateway.auth.token`)
4. Save & Connect → chat

## How it connects
- The app connects via WebSocket (`ws://` or `wss://`)
- Authenticates with the JSON-RPC `connect` method + token
- Sends chat via `chat.run` method
- Listens for `chat.run` responses and displays them

## Notes
- Camera/gyro need a real device — cloud sim can't use physical hardware
- Later: add voice recording + camera for a full native app
