# Tennis Buddee privacy

_Updated November 2026_

Tennis Buddee uses a sensor inside the racket handle to measure shots.

- **Shot history:** racket readings and computed sessions are stored on the player's devices. When iCloud is enabled, sessions sync through the player's private iCloud account.
- **Friend sharing:** account sign-in and Supabase are used only for profile, friend, match, and session totals that the player chooses to share.
- **Lemonade agent:** when the player enables the agent and chooses a Lemonade server, the app sends the question and the tool requests/results needed to answer to that configured server. The local agent path does not use Supabase sign-in. The server may be on the same device or another device on the player's network.
- **Player notes:** notes remain in the local app data and iCloud. If the player enables note access for the agent, relevant notes are included in the request to the configured Lemonade server.
- **Health data:** workout data is used to show the player's workout stats and is saved to Apple Health only with permission. It is not sent to the agent server.
- **Optional glasses integration:** live racket information can be shown on a paired display when that optional integration is enabled.
- **Ads and tracking:** the app has no ads or analytics tracking.

To remove local session data, delete sessions in the app or remove the app and its iCloud data through Apple settings. To remove shared account data, use the account support process in the repository's issue tracker.

For the history of third-party model hosting, video labeling, and wearable SDKs, see [Acknowledgements](../ACKNOWLEDGEMENTS.md).
