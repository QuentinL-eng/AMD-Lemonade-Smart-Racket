# Acknowledgements

Tennis Buddee is a smart racket project. Its agent and integrations have changed over time; these notes record the origins of the current implementation accurately.

- **Meta Muse Spark** was used in an earlier cloud agent prototype and in the historical baseline evaluation. It is not the current target engine for the AMD Lemonade Developer Challenge.
- **Baseten** hosted the open Muse Spark model used by that prototype and its historical evaluation. The Supabase `muse` function remains available as an optional legacy proxy, but it is not required for local operation.
- **SAM 3.1** video and image APIs were used by labeling scripts to prefill racket and ball tracks for human review. The scripts that call the service upload bounded video clips; see `tools/sam_*.py` and `ml/stroke_system/sam_contacts.py` before using them.
- **Meta Wearables Device Access Toolkit**, including `MWDATCore` and `MWDATDisplay`, powers the optional Ray-Ban Display integration. It remains an optional integration and is not part of the default product story. The SDK is Meta's and retains its original name.

The project retains its MIT license and acknowledges the idea's starting point in the MIT-licensed [Smart-Tennis-Racket repository](https://github.com/AahanPrajapati/Smart-Tennis-Racket).
