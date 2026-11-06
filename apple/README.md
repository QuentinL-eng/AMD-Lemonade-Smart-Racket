# Apple apps

The iPhone and Mac apps share the SwiftUI sources in `Shared/`. The Watch companion lives in `Watch/`, and `RacketKit` contains racket protocol, analysis, and simulation code.

## Run

Open `TennisBuddy.xcodeproj` in Xcode and select the iOS, macOS, or Watch scheme. Recorded sessions and the simulator data source can be used without a physical racket.

Run the shared package tests with:

```bash
swift test --package-path apple/RacketKit
```

## Local agent server

The default agent transport targets a player-configured Lemonade server. Its address and selected model are stored in local app settings. The connection test checks the server's model list and reports latency. The local agent does not require a Supabase account. For server setup, LAN access, and browser CORS, see [docs/LEMONADE.md](../docs/LEMONADE.md).

The deterministic built-in engine remains the fallback when the configured server is unavailable. The UI reports which engine answered and shows the connection failure.

The optional cloud proxy transport is retained for legacy deployments and is not selected by the default app path. Friend sharing and shared session features use Supabase independently of the local agent.

## Agent tools and simulator

The shared tool dispatcher exposes session summaries, shot queries, session comparison, the physics simulator, live racket state, status, and player notes. What-if outputs are estimates from `ShotSimulator`; they do not model flight or landing depth. The tool schemas and simulator are in `Shared/Coach/`.

## Current verification limits

The current development host is Windows and does not have Swift or Xcode installed. Swift build and UI behavior need verification on a Mac before this integration is described as release-ready. The on-device model export, download manager, constrained decoder, and numeric substitution layer remain unfinished; see [docs/ON_DEVICE_MODEL.md](../docs/ON_DEVICE_MODEL.md).
