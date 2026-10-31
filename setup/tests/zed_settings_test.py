import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "zed-settings.py"


class ZedSettingsTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        root = Path(self.directory.name)
        spec = importlib.util.spec_from_file_location("zed_settings", SCRIPT)
        self.settings = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.settings)
        self.settings.SHARED = root / "settings.shared.json"
        self.settings.ACTIVE = root / "settings.json"
        self.settings.SHARED.write_text('{\n  "read_ssh_config": true\n}\n')

    def test_sync_preserves_local_connections_after_shared_update(self):
        self.settings.sync()
        active = self.settings.ACTIVE
        active.write_text(
            active.read_text().replace(
                '"ssh_connections": [],',
                '"ssh_connections": [{"host": "machine-a"}],',
            )
        )
        self.settings.SHARED.write_text('{\n  "read_ssh_config": false\n}\n')

        self.settings.sync()

        self.assertIn("machine-a", active.read_text())
        self.assertIn('"read_ssh_config": false', active.read_text())

    def test_promote_shared_edit_without_connections(self):
        self.settings.sync()
        active = self.settings.ACTIVE
        active.write_text(
            active.read_text()
            .replace('"ssh_connections": [],', '"ssh_connections": [{"host": "local"}],')
            .replace('"read_ssh_config": true', '"read_ssh_config": false')
        )

        with self.assertRaisesRegex(ValueError, "promote"):
            self.settings.sync()
        self.settings.promote()

        self.assertIn('"read_ssh_config": false', self.settings.SHARED.read_text())
        self.assertNotIn("local", self.settings.SHARED.read_text())
        self.assertIn("local", active.read_text())

    def test_promote_refuses_newer_shared_source(self):
        self.settings.sync()
        self.settings.SHARED.write_text('{\n  "read_ssh_config": false\n}\n')

        with self.assertRaisesRegex(ValueError, "merge"):
            self.settings.promote()

    def test_promote_refuses_connections_in_shared_section(self):
        self.settings.sync()
        active = self.settings.ACTIVE
        active.write_text(
            active.read_text().replace(
                '"read_ssh_config": true',
                '"ssh_connections": [],\n  "read_ssh_config": true',
            )
        )

        with self.assertRaisesRegex(ValueError, "LOCAL section"):
            self.settings.promote()

    def test_sync_refuses_unmarked_active_file(self):
        self.settings.ACTIVE.write_text('{"ssh_connections": []}\n')

        with self.assertRaisesRegex(ValueError, "no recognized sections"):
            self.settings.sync()


if __name__ == "__main__":
    unittest.main()
