"""Read provisional pass indicators from a running agent_eval console log.

The final JSON strict score is authoritative: unknown-tool details are not in
the console log. Response errors and target=False are counted as failures here.
"""
import argparse
import json
from pathlib import Path
import re

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('log',type=Path)
a=p.parse_args()
rows=[line for line in a.log.read_text(encoding='utf-8-sig').splitlines()
      if re.match(r'\[\d+/\d+\]',line)]
passed=sum(bool(re.search(r'\bok\s+tools=',line)) and 'target=False' not in line for line in rows)
print(json.dumps({'completed':len(rows),'provisional_pass':passed,
    'provisional_percent':round(100*passed/len(rows),1) if rows else None,
    'response_errors':sum(' ERR ' in line for line in rows),
    'flagged_checks':sum(' CHECK ' in line for line in rows),
    'target_failures':sum('target=False' in line for line in rows)}))
