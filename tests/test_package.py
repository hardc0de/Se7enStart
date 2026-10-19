# SPDX-License-Identifier: GPL-3.0-or-later
import gettext
from collections import Counter
import json
from pathlib import Path
import re
import runpy
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent


class PackageTests(unittest.TestCase):
    def test_runtime_and_ui_configuration_keys_exist(self):
        tree = ET.parse(ROOT / "contents/config/main.xml")
        keys = {entry.attrib["name"] for entry in tree.findall(".//{*}entry")}
        references = set()
        for source in (ROOT / "contents/ui").rglob("*.qml"):
            text = source.read_text()
            references.update(re.findall(r"Plasmoid\.configuration\.([A-Za-z]+)", text))
            references.update(re.findall(r"property (?:string|bool|alias) cfg_([A-Za-z]+)", text))
        self.assertFalse(references - keys, references - keys)
        self.assertNotIn("showFavoritesFirst", keys)

    def test_translation_domain_and_polish_labels(self):
        plugin_id = json.loads((ROOT / "metadata.json").read_text())["KPlugin"]["Id"]
        domain = f"plasma_applet_{plugin_id}"
        files = list((ROOT / "contents/locale").rglob("*.mo"))
        self.assertTrue(files)
        self.assertTrue(all(file.name == f"{domain}.mo" for file in files))
        with (ROOT / f"contents/locale/pl/LC_MESSAGES/{domain}.mo").open("rb") as stream:
            translations = gettext.GNUTranslations(stream)
        for source, polish in {"All Programs": "Wszystkie programy", "Back": "Wstecz", "Shut Down": "Zamknij", "Documents": "Dokumenty"}.items():
            self.assertEqual(translations.gettext(source), polish)

    def test_all_catalogs_cover_current_sources_and_match_bundled_translations(self):
        messages = runpy.run_path(str(ROOT / "translate/messages.py"))
        metadata = json.loads((ROOT / "metadata.json").read_text())["KPlugin"]
        domain = messages["DOMAIN"]
        with tempfile.TemporaryDirectory(prefix="se7en-translations-") as directory:
            template = Path(directory) / "current.pot"
            messages["extract"](template)
            catalogs = sorted((ROOT / "translate").glob("*.po"))
            self.assertTrue(catalogs)
            for po in catalogs:
                with self.subTest(language=po.stem):
                    # msgcmp rejects missing, empty, and fuzzy translations.
                    result = subprocess.run(["msgcmp", str(po), str(template)], capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    compiled = Path(directory) / f"{po.stem}.mo"
                    subprocess.run(["msgfmt", "--check", "-o", str(compiled), str(po)], check=True)
                    bundled = ROOT / "contents/locale" / po.stem / "LC_MESSAGES" / f"{domain}.mo"
                    self.assertEqual(bundled.read_bytes(), compiled.read_bytes(), f"Rebuild {po.stem}")
                    with compiled.open("rb") as stream:
                        translations = gettext.GNUTranslations(stream)
                    self.assertEqual(translations.info()["language"], po.stem)
                    for source, translated in translations._catalog.items():
                        if source:
                            self.assertEqual(Counter(re.findall(r"%L?\d+", source)),
                                             Counter(re.findall(r"%L?\d+", translated)), source)
                    description = metadata["Description"]
                    self.assertNotEqual(translations.gettext(description), description)
                    self.assertEqual(metadata[f"Description[{po.stem}]"], translations.gettext(description))

    def test_no_file_xhr_or_legacy_model_roles(self):
        text = "\n".join(path.read_text() for path in (ROOT / "contents/ui").rglob("*.qml"))
        self.assertNotIn("XMLHttpRequest", text)
        self.assertNotIn("Qt.UserRole +", text)
        self.assertNotIn("systemctl", text)
        self.assertNotIn("qdbus", text)
        self.assertNotIn("executeSystemAction", text)


if __name__ == "__main__":
    unittest.main()
