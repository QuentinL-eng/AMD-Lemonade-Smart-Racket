# Before you submit (things only you can do)

Checked against the challenge page text (printed 2026-11-05). Nothing here has been done for you.

- [ ] **AMD Developer Program membership.** The challenge is open only to current members.
- [ ] **Lemonade Discord.** Join the channel and follow #AMDDevChallenge (listed as step 1 of "How to Enter").
- [ ] **GitHub ID.** The form field was blank when printed. Fill it with your public profile.
- [ ] **Discord ID.** Also blank when printed.
- [ ] **Public repo.** The rules require open-source access. The repo is MIT licensed (see `LICENSE`); make the GitHub repo public. The adapter weights are kept outside Git on purpose. Decide where to host them (for example a release asset or a Hugging Face model page) so a judge can reproduce.
- [ ] **Remove anything private** before going public: the address and phone number on the form must not appear in any file, and `data/` holds personal session recordings. Review `git status` and `.gitignore` first.
- [ ] **Eligibility.** The fine print requires being 18+ and a legal resident of the 50 US states, DC, or Canada. Confirm current prize availability, since it ends when supplies run out.
- [ ] **Demo video.** The form gives bonus points for recorded demos or links. The `video/` folder has a work in progress.
- [ ] **Paste the project description** from `SUBMISSION.md` into the form and link the repo.
- [ ] **Re-read the numbers.** Every score quoted in `SUBMISSION.md` should match `docs/ADAPTER_EVAL.md` and the JSON reports in `evaluation/`.
- [ ] **Training data is not in Git.** `data/whatif/` is gitignored, so a judge cannot retrain from the repo alone. Decide whether to publish the synthetic what-if conversations (they are synthetic, player-split) or document how to regenerate them.
