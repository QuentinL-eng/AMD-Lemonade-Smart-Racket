// Writes src/config/generated/facts.json: the proof numbers on screen, read from git and hackathon.json so they
// can't drift from the repo. Runs before studio and every render (npm run assets).
import { execFileSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '..', '..');
const hackathon = JSON.parse(readFileSync(join(root, 'hackathon.json'), 'utf8'));

const git = (...args) => execFileSync('git', args, { cwd: root, encoding: 'utf8' }).trim().split('\n').filter(Boolean);
// `date|subject`, oldest first
const log = git('log', '--reverse', '--date=short', '--format=%ad|%s').map((l) => {
  const at = l.indexOf('|');
  return { date: l.slice(0, at), subject: l.slice(at + 1) };
});

// Every calendar day from first to last commit, so quiet days show as gaps.
const counts = new Map();
for (const c of log) counts.set(c.date, (counts.get(c.date) ?? 0) + 1);
const first = log[0].date, last = log[log.length - 1].date;
const days = [];
for (let d = new Date(`${first}T00:00:00Z`); d <= new Date(`${last}T00:00:00Z`); d.setUTCDate(d.getUTCDate() + 1)) {
  const date = d.toISOString().slice(0, 10);
  days.push({ date, commits: counts.get(date) ?? 0 });
}

// Subjects for the scrolling log: sentences that describe work, no merges or file-name uploads, and the
// anti-project words stay off screen.
const usable = log.map((c) => c.subject).filter((s) => /^[A-Z]/.test(s) && s.split(' ').length >= 4 && !/^merge|coach|analy[sz]|judge/i.test(s) && s.length <= 72);
const step = Math.max(1, Math.floor(usable.length / 40));
const subjects = usable.filter((_, i) => i % step === 0);

const e = hackathon.evidence;
const facts = {
  git: { commits: log.length, first, last, days, subjects },
  tests: { swift: e.swift_tests, python: e.python_unittest_ml + e.python_unittest_tools + e.python_pytest_robot },
  parityClips: e.firmware_python_parity_clips,
  sweetSpot: { accuracy: e.sweet_spot_accuracy, baseline: e.sweet_spot_baseline, errorCm: e.sweet_spot_mean_distance_error_cm },
  clubMinutes: e.real_club_session_minutes,
  model: hackathon.meta_technology[0].model,
  agentTools: hackathon.agent_tools,
  agentLimits: hackathon.agent_limits,
  links: hackathon.links,
};
mkdirSync(join(here, '..', 'src/config/generated'), { recursive: true });
writeFileSync(join(here, '..', 'src/config/generated/facts.json'), `${JSON.stringify(facts, null, 2)}\n`);
console.log(`facts: ${log.length} commits, ${first} to ${last}, ${hackathon.agent_tools.length} Muse tools`);
