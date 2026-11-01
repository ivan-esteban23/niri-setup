import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'dotfiles/local/bin/niri-gcal'
loader = importlib.machinery.SourceFileLoader('calendar_widget', str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
calendar = importlib.util.module_from_spec(spec)
loader.exec_module(calendar)
TSV = 'start_date\tstart_time\tend_date\tend_time\ttitle\tconference_uri\thtml_link\n2030-04-01\t09:00\t2030-04-01\t10:00\tTeam sync\thttps://meet.google.com/abc\thttps://calendar.google.com/event\n2030-04-02\t\t2030-04-03\t\tAll day\tjavascript:bad\t\n'

class CalendarTests(unittest.TestCase):
    def test_tsv_and_safe_links(self):
        events = calendar.parse_events(TSV)
        self.assertEqual([e['title'] for e in events], ['Team sync', 'All day'])
        self.assertEqual(events[0]['meet'], 'https://meet.google.com/abc')
        self.assertTrue(events[1]['allDay'])
        self.assertEqual(events[1]['meet'], '')
        self.assertEqual(calendar.safe_url('https://user:password@example.com'), '')

    def test_refresh_cache_and_failed_refresh_retains_events(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            binary = root / 'gcalcli'
            binary.write_text('#!/usr/bin/env python3\nprint(' + repr(TSV) + ', end="")\n')
            binary.chmod(0o755)
            env = {**os.environ, 'PATH': str(root) + os.pathsep + os.environ['PATH'], 'XDG_CACHE_HOME': str(root / 'cache'), 'XDG_CONFIG_HOME': str(root / 'config')}
            first = json.loads(subprocess.check_output([str(SCRIPT), '--refresh'], env=env, text=True))
            self.assertEqual(first['status'], 'Calendar synced')
            self.assertEqual(len(first['events']), 2)
            self.assertEqual((root / 'cache/niri-gcal/agenda.json').stat().st_mode & 0o777, 0o600)
            binary.write_text('#!/bin/sh\nexit 1\n')
            second = json.loads(subprocess.check_output([str(SCRIPT), '--refresh'], env=env, text=True))
            self.assertIn('failed', second['status'])
            self.assertEqual(second['events'], first['events'])

    def test_reminders_retry_on_failure_and_deduplicate(self):
        with tempfile.TemporaryDirectory() as tmp, mock.patch.object(calendar, 'CACHE', Path(tmp)):
            event = {'title': 'Test', 'start': int(calendar.time.time()) + 30, 'allDay': False, 'link': ''}
            with mock.patch.object(calendar.subprocess, 'run') as run:
                run.return_value.returncode = 1
                calendar.reminders({'events': [event]})
                run.return_value.returncode = 0
                calendar.reminders({'events': [event]})
                calendar.reminders({'events': [event]})
                self.assertEqual(run.call_count, 2)

if __name__ == '__main__': unittest.main()
