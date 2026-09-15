# Changelog

## v1.0.0 — 2026-09-15

First stable release. The patches are the same as in v0.1.0.

- Releases are now built by GitHub Actions when a `v*` tag is pushed. The
  workflow checks that every `LOAD` target exists and that the install script
  parses before it attaches the zip.
- README adds a reMarkable trademark notice.

## v0.1.0 — 2026-09-15

First public release.

- `split_doc` ported to reMarkable Paper Pro Move firmware 3.27.1.0 / 3.27.3.0.
- Per-document memo notebook (`Memo` folder, `📝` tag, auto-open in split,
  trash cleanup).
- Zoom indicator hides ~1.5 s after a zoom change.
- `scripts/install-xovi-persist.sh` loads xovi on every boot and refuses to run
  without a hashtab.
