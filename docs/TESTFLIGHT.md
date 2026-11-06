# TestFlight

App Store Connect app: **Tennis Buddy Trainer** (bundle ID `com.quentinlynch.tennisbuddy`).

Upload a new build: `tools/testflight.sh` (archives the iPhone + Watch app and uploads; build numbers are automatic).

## Test information (App Store Connect → TestFlight → Test Information)

- **Beta App Description:** Tennis Buddee is a smart racket with a sensor inside the handle. Explore shot history,
  scoring, and physics-based what-if estimates in Simulator mode. The Apple Watch companion can track a tennis workout.
- **What to Test:** Open Live and press Start Session using Simulator. End the session and check History and Insights.
  Open Racket agent settings to enter a Lemonade server address, select **Test connection**, and confirm which engine
  answers. A Tennis Buddee account is only needed for friend sharing. On Apple Watch, start a session from the watch.
- **Feedback Email:** your email
- **Privacy Policy URL:** https://github.com/QuentinL-eng/Tennis-Buddy-Smart-Racket/blob/main/docs/PRIVACY.md
- **Beta App Review notes:** The app connects to a custom Bluetooth sensor in a tennis racket. Without the sensor it
  runs in Simulator mode, so the racket screens can be reviewed without hardware. Lemonade features require a local
  Lemonade server configured by the tester.

## Getting it to friends

- **Today, no review:** App Store Connect → Users and Access → add each friend (any role, e.g. Customer Support,
  with access to this app). After they accept, add them to an **Internal Testing** group in TestFlight.
- **Public link:** TestFlight → External Testing → create a group → add the build → Submit for Review → enable the
  public link. The first build's review usually takes a few hours.

Testers install the **TestFlight** app from the App Store, then accept the invite or open the link.
