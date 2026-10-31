import contextlib
import importlib.machinery
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]


def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class InstallerMcpTests(unittest.TestCase):
    def test_merge_preserves_other_servers_and_permissions(self):
        module = load('mcp_merge_test', ROOT / 'scripts/merge-tavily-mcp.py')
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'mcp.json'
            path.write_text(json.dumps({'mcpServers': {'other': {'command': 'existing'}}, 'otherSetting': 7}))
            with mock.patch.object(module.sys, 'argv', ['merge', str(path)]), mock.patch.dict(os.environ, {'TAVILY_API_KEY': 'test-key'}):
                module.main()
            result = json.loads(path.read_text())
            self.assertEqual(result['mcpServers']['other']['command'], 'existing')
            self.assertEqual(result['otherSetting'], 7)
            self.assertEqual(result['mcpServers']['tavily']['env']['TAVILY_API_KEY'], 'test-key')
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_invalid_json_is_left_untouched(self):
        module = load('mcp_merge_invalid_test', ROOT / 'scripts/merge-tavily-mcp.py')
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'mcp.json'
            path.write_text('{invalid')
            with mock.patch.object(module.sys, 'argv', ['merge', str(path)]), mock.patch.dict(os.environ, {'TAVILY_API_KEY': 'test-key'}):
                with self.assertRaises(json.JSONDecodeError):
                    module.main()
            self.assertEqual(path.read_text(), '{invalid')


class VideoDownloadTests(unittest.TestCase):
    def setUp(self):
        self.module = load('video_dl_test', ROOT / 'dotfiles/local/bin/video-dl')
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.module.CACHE_DIR = Path(self.temp.name)
        self.module.STATE_FILE = self.module.CACHE_DIR / 'state.json'
        self.module.HISTORY_FILE = self.module.CACHE_DIR / 'history.json'

    def test_background_starts_detached_state_managing_worker(self):
        process = mock.Mock(pid=123)
        with mock.patch.object(self.module.shutil, 'which', return_value='/usr/bin/yt-dlp'), \
             mock.patch.object(self.module, 'get_download_dir', return_value=Path(self.temp.name)), \
             mock.patch.object(self.module.subprocess, 'Popen', return_value=process) as popen, \
             contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(self.module.run_download('https://example.test/video', background=True), 0)
        args, options = popen.call_args
        self.assertEqual(args[0][2:4], ['download', 'https://example.test/video'])
        self.assertTrue(options['start_new_session'])
        self.assertEqual(self.module.get_state()['phase'], 'downloading')

    def test_worker_updates_state_and_history_on_success_and_failure(self):
        process = mock.Mock(stdout=['[download] Destination: /tmp/result.mp4\n'], returncode=0)
        with mock.patch.object(self.module.shutil, 'which', return_value='/usr/bin/yt-dlp'), \
             mock.patch.object(self.module, 'get_download_dir', return_value=Path(self.temp.name)), \
             mock.patch.object(self.module, 'notify'), \
             mock.patch.object(self.module.subprocess, 'Popen', return_value=process), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(self.module.run_download('https://example.test/video'), 0)
            self.assertEqual(self.module.get_state()['phase'], 'done')
            self.assertEqual(json.loads(self.module.HISTORY_FILE.read_text())[0]['path'], '/tmp/result.mp4')
            process.returncode = 1
            self.assertEqual(self.module.run_download('https://example.test/failure'), 1)
            self.assertEqual(self.module.get_state()['phase'], 'error')


if __name__ == '__main__':
    unittest.main()
