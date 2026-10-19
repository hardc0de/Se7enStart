#!/usr/bin/env python3
"""Extract, merge, and compile this applet's catalogs without changing the desktop."""
import argparse
import gettext
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
TRANSLATE = ROOT / "translate"
DOMAIN = "plasma_applet_" + json.loads((ROOT / "metadata.json").read_text())["KPlugin"]["Id"]
METADATA = ROOT / "metadata.json"


def run(tool, *args):
    path = shutil.which(tool)
    if not path:
        raise SystemExit(f"Missing {tool}; install gettext before running this command.")
    subprocess.run([path, *map(str, args)], check=True, cwd=ROOT)


def build():
    metadata = json.loads(METADATA.read_text())
    for po in sorted(TRANSLATE.glob("*.po")):
        target = ROOT / "contents" / "locale" / po.stem / "LC_MESSAGES"
        target.mkdir(parents=True, exist_ok=True)
        catalog = target / f"{DOMAIN}.mo"
        run("msgfmt", "--check", "-o", catalog, po)
        with catalog.open("rb") as stream:
            translations = gettext.GNUTranslations(stream)
        metadata["KPlugin"][f"Description[{po.stem}]"] = translations.gettext(metadata["KPlugin"]["Description"])
    METADATA.write_text(json.dumps(metadata, ensure_ascii=False, indent=4) + "\n")
    print(f"Built {DOMAIN} catalogs. Reload the applet to use them.")


def extract(template):
    sources = sorted(p.relative_to(ROOT) for p in (ROOT / "contents").rglob("*") if p.suffix in (".qml", ".js"))
    run("xgettext", "--language=JavaScript", "--from-code=UTF-8", "--add-comments=i18n",
        "--keyword=i18n:1", "--keyword=i18nc:1c,2", "--keyword=QT_TR_NOOP:1",
        "--flag=i18n:1:kde-format", "--flag=i18nc:2:kde-format",
        "--package-name=Se7enStart", "--msgid-bugs-address=https://github.com/hardc0de/Se7enStartissues",
        "--output", template, *sources)
    # KPlugin reads localized JSON keys rather than calling i18n at runtime.
    # Add its description to the same catalog so PO files remain the source of truth.
    description = json.loads(METADATA.read_text())["KPlugin"]["Description"]
    with template.open("a") as stream:
        stream.write('\n#: metadata.json\nmsgid ' + json.dumps(description, ensure_ascii=False) + '\nmsgstr ""\n')


def merge():
    extract(TRANSLATE / "template.pot")
    for po in sorted(TRANSLATE.glob("*.po")):
        run("msgmerge", "--update", "--backup=none", "--no-fuzzy-matching", po, TRANSLATE / "template.pot")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("build", "merge"))
    args = parser.parse_args()
    try:
        {"build": build, "merge": merge}[args.action]()
    except subprocess.CalledProcessError as error:
        sys.exit(error.returncode)
