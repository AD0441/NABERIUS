#!/usr/bin/env python3
"""Update the Spanish source catalog; --check verifies it without changing files."""
from pathlib import Path
import argparse
import json
import re

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / 'Sources/NaberiusCore/Localization/es.lproj/Localizable.strings'
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
keys = {'Integradas', 'Personales', 'Académico', 'Cuadrícula', 'Simple', 'Sistema', 'Claro', 'Oscuro'}
for path in (ROOT / 'Sources').rglob('*.swift'):
    for match in re.finditer(r'L10n\.(?:text|format)\("((?:\\.|[^"\\])*)"', path.read_text()):
        keys.add(json.loads('"' + match[1] + '"'))
existing = {}
for match in re.finditer(r'^"((?:\\.|[^"\\])*)"\s*=\s*"((?:\\.|[^"\\])*)";', CATALOG.read_text(), re.M):
    existing[json.loads('"' + match[1] + '"')] = json.loads('"' + match[2] + '"')
if args.check:
    missing = keys - existing.keys()
    if missing:
        raise SystemExit('Missing Spanish keys: ' + ', '.join(sorted(missing)))
    print(f'Spanish catalog: {len(keys)} source keys verified.')
else:
    quote = lambda value: json.dumps(value, ensure_ascii=False)
    CATALOG.write_text('// Spanish interface catalog. Preserve format placeholders. Document content is not translated.\n' + '\n'.join(quote(key) + ' = ' + quote(existing.get(key, key)) + ';' for key in sorted(keys)) + '\n')
    print(f'Spanish catalog: {len(keys)} source keys synchronized.')
