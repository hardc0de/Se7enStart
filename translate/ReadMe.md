Se7enStart uses the `plasma_applet_Se7enStart` translation domain from metadata.json.

From any directory, run `sh /path/to/Se7enStart/translate/merge.sh` to extract the current QML/JavaScript strings and update existing PO files. Edit your locale's PO file, then run `sh /path/to/Se7enStart/translate/build.sh` to compile and install the bundled catalogs. These commands require Python 3 and gettext. They never install packages or restart Plasma.

The applet description in `metadata.json` is included in the PO files too. The build command updates its localized `Description[language]` keys from those catalogs. Keep English source messages in `i18n(...)` calls; put translations in the matching PO file. For static list models, mark messages with `QT_TR_NOOP(...)` and translate them with `i18n(...)` in the delegate.

After building, run `python3 tests/test_package.py` from the project root to check that every current message has a non-fuzzy translation in every language, placeholders are preserved, and bundled catalogs and metadata match the PO files.

Reload the applet to test installed translations. With Plasma 6 plasma-sdk and an enabled system locale, `sh translate/plasmoidlocaletest.sh pl_PL.UTF-8` opens a local preview. Build and locale-test commands use their own script directory rather than the caller's working directory.

Report translation issues in the Se7enStart repository: https://github.com/hardc0de/Se7enStart/issues