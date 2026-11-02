# TestFlight

App Store Connect app: **Tennis Buddy Trainer** (bundle ID `com.quentinlynch.tennisbuddy`).

**Public beta link:** https://testflight.apple.com/join/137F7kvd (works once Beta App Review approves the build;
build 1.0 (1) submitted 2:30 PM, Oct 17). Internal group: "Team & Friends" (automatic distribution). External group: "Public Beta".
Upload a new build: `tools/testflight.sh` (archives the iPhone + Watch app and uploads; build numbers are automatic).

## Test information (App Store Connect → TestFlight → Test Information)

- **Beta App Description:** Tennis Buddee reads a sensor-equipped tennis racket: swing speed, ball speed, spin and
  sweet-spot hits, explained by Muse (Meta's Muse Spark) with a 3D what-if of your swing. No racket? The app starts in
  Simulator mode so you can try every screen. The Apple Watch app taps your wrist for each shot and runs a tennis workout.
- **What to Test:** Open the Live tab and press Start Session; the simulated racket hits a shot every few seconds.
  End the session, then check History and Insights. Sign in under Racket → Account, then in Insights → Muse try
  "Analyze session", "Plan my next drill" and What if → "Show me the best change". On Apple Watch, start a session
  from the watch.
- **Feedback Email:** your email
- **Privacy Policy URL:** https://github.com/QuentinL-eng/Tennis-Buddy-Smart-Racket/blob/main/docs/PRIVACY.md
- **Beta App Review notes:** The app connects to a custom Bluetooth sensor in a tennis racket (hackathon project).
  Without the sensor it runs in Simulator mode by default, so all features can be reviewed without hardware.

## Getting it to friends

- **Today, no review:** App Store Connect → Users and Access → add each friend (any role, e.g. Customer Support,
  with access to this app). After they accept, add them to an **Internal Testing** group in TestFlight.
- **Public link:** TestFlight → External Testing → create a group → add the build → Submit for Review → enable the
  public link. The first build's review usually takes a few hours.

Testers install the **TestFlight** app from the App Store, then accept the invite or open the link.
