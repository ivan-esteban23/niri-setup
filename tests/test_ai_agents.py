import importlib.machinery
import importlib.util
import json
from pathlib import Path
import tempfile
import time
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'dotfiles/local/bin/antigravity-agent-usage'
loader = importlib.machinery.SourceFileLoader('antigravity_usage', str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)

class AntigravityUsageTests(unittest.TestCase):
    def test_missing_and_newest_snapshot(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertEqual(module.snapshot(root)['limits'], [])
            def write(name, updated, remaining):
                (root / name).write_text(json.dumps({'version': 1, 'source': 'local', 'updatedAt': updated, 'models': [{'id': 'gemini', 'remainingFraction': remaining, 'resetTime': '2030-01-01T00:00:00Z'}]}))
            now = time.time() * 1000
            write('old.json', now - 600000, .2)
            write('new.json', now - 120000, .75)
            (root / 'broken.json').write_text('{')
            result = module.snapshot(root)
            self.assertEqual(result['limits'][0]['used'], 25)
            self.assertEqual(result['limits'][0]['label'], 'gemini')
            self.assertIn('2 min old', result['status'])
            self.assertIsNotNone(result['limits'][0]['reset'])

    def test_invalid_and_authorized_records_are_ignored(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'a.json').write_text(json.dumps({'version': 1, 'source': 'authorized', 'updatedAt': 123, 'models': []}))
            (root / 'b.json').write_text(json.dumps({'version': 1, 'source': 'local', 'updatedAt': 123, 'models': [{'id': 'bad', 'remainingPercentage': True}]}))
            self.assertEqual(module.snapshot(root)['limits'], [])

if __name__ == '__main__': unittest.main()
