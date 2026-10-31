#!/usr/bin/env python3
"""Offline integration tests for the reminders command and timer worker."""
import json
import datetime as dt
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "dotfiles/local/bin/niri-reminders"


class ReminderTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="niri-reminders-test-")
        self.root = Path(self.tmp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "notifications.log"
        self.notifier = self.bin / "notify-send"
        self.notifier.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$REMINDER_TEST_LOG"\nexit "${REMINDER_TEST_NOTIFY_EXIT:-0}"\n')
        self.notifier.chmod(0o755)
        self.env = os.environ.copy()
        self.env.update(XDG_DATA_HOME=str(self.root / "data"), PATH=str(self.bin) + os.pathsep + self.env.get("PATH", ""), REMINDER_TEST_LOG=str(self.log))
        self.db = self.root / "data/niri-reminders/reminders.sqlite3"

    def tearDown(self):
        self.tmp.cleanup()

    def run_cli(self, *args, ok=True):
        result = subprocess.run([sys.executable, str(SCRIPT), *args], env=self.env, text=True, capture_output=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr)
            return json.loads(result.stdout)
        self.assertNotEqual(result.returncode, 0)
        return result

    def due_now(self, ident):
        with sqlite3.connect(self.db) as db:
            db.execute("UPDATE reminders SET due=0 WHERE id=?", (ident,))

    def test_create_list_snooze_complete_and_persistence(self):
        ident = self.run_cli("add", "--in", "15", "--", "- Take a break")['id']
        rows = self.run_cli("list")['reminders']
        self.assertEqual([row['title'] for row in rows], ["- Take a break"])
        self.assertEqual(self.db.stat().st_mode & 0o777, 0o600)
        self.due_now(ident)
        self.assertEqual(self.run_cli("tick"), {"delivered": 1, "failed": 0})
        self.assertIn("- Take a break", self.log.read_text())
        self.assertEqual(self.run_cli("tick"), {"delivered": 0, "failed": 0})
        self.assertEqual(len(self.log.read_text().splitlines()), 1)
        self.run_cli("snooze", ident, "10")
        row = self.run_cli("list")['reminders'][0]
        self.assertEqual(row['notified'], 0)
        self.assertGreater(row['due'], 0)
        self.run_cli("done", ident)
        self.assertEqual(self.run_cli("list")['reminders'], [])

    def test_failed_notification_is_retried_not_lost(self):
        ident = self.run_cli("add", "Retry", "--in", "1")['id']
        self.due_now(ident)
        self.env['REMINDER_TEST_NOTIFY_EXIT'] = '1'
        self.run_cli("tick", ok=False)
        self.assertEqual(self.run_cli("list")['reminders'][0]['notified'], 0)
        self.env['REMINDER_TEST_NOTIFY_EXIT'] = '0'
        self.assertEqual(self.run_cli("tick")['delivered'], 1)
        self.assertEqual(self.run_cli("list")['reminders'][0]['notified'], 1)

    def test_partial_failure_retries_only_undelivered_reminders(self):
        first = self.run_cli("add", "Deliver", "--in", "1")['id']
        second = self.run_cli("add", "Retry", "--in", "1")['id']
        self.due_now(first)
        self.due_now(second)
        self.notifier.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$REMINDER_TEST_LOG"\ncase "$*" in *Retry*) exit 1;; esac\nexit 0\n')
        self.run_cli("tick", ok=False)
        rows = {row['title']: row for row in self.run_cli("list")['reminders']}
        self.assertEqual(rows['Deliver']['notified'], 1)
        self.assertEqual(rows['Retry']['notified'], 0)
        self.assertEqual(self.run_cli("tick", ok=False).returncode, 1)
        log = self.log.read_text()
        self.assertEqual(log.count('Deliver'), 1)
        self.assertEqual(log.count('Retry'), 2)

    def test_validation_and_delete(self):
        for args in [("add", "", "--in", "1"), ("add", "Later", "--in", "0"), ("add", "Old", "--at", "2000-01-01 12:00"), ("add", "Invalid", "--at", "tomorrow"), ("done", "missing")]:
            self.run_cli(*args, ok=False)
        ident = self.run_cli("add", "Delete me", "--in", "60")['id']
        self.run_cli("delete", ident)
        self.assertEqual(self.run_cli("list")['reminders'], [])

    def test_absolute_local_time_and_plain_text_notifications(self):
        when = (dt.datetime.now() + dt.timedelta(days=2)).strftime("%Y-%m-%d %H:%M")
        title = "<important> & tea"
        ident = self.run_cli("add", title, "--at", when)['id']
        row = self.run_cli("list")['reminders'][0]
        self.assertEqual(dt.datetime.fromtimestamp(row['due']).strftime("%Y-%m-%d %H:%M"), when)
        self.due_now(ident)
        self.run_cli("tick")
        self.assertIn("&lt;important&gt; &amp; tea", self.log.read_text())

    def test_concurrent_checks_do_not_duplicate_delivery(self):
        ident = self.run_cli("add", "Once", "--in", "1")['id']
        self.due_now(ident)
        jobs = [subprocess.Popen([sys.executable, str(SCRIPT), "tick"], env=self.env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True) for _ in range(2)]
        outputs = [job.communicate(timeout=15) for job in jobs]
        self.assertTrue(all(job.returncode == 0 for job in jobs), outputs)
        self.assertEqual(sum(json.loads(output[0])['delivered'] for output in outputs), 1)
        self.assertEqual(len(self.log.read_text().splitlines()), 1)


if __name__ == '__main__':
    unittest.main()
