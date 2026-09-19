# keychains-3d — AGENTS.md

Repo-specific rules and design decisions for the personalized keychain generator.
Applies on top of the parent [`/Users/jcalavia/Development/Github/3d-design/AGENTS.md`](../AGENTS.md) conventions.

## Purpose

Generates personalized keychains (names) from a **single shared template** into multiple
variants: plain text, text on a base (embossed or engraved), and text with an integrated
ring. Parts are small, flat, support-free prints on an Ender 3 V3 Plus.

## Repo Layout

```
template.scad            # THE render source — reads -D NOMBRE/BASE/ENGRAVED/RING/FONT
lib/keychain.scad        # Shared design system: keychain() module + text-width tables
designs/{name}.scad      # Per-name stubs (e.g. marcos.scad) for direct OpenSCAD use
fonts/*.txt              # Font-name lists, one group per file (cursivas, manuscritas)
render.sh                # Extended batch renderer: groups, specific names, --parallel, --dist
Makefile                 # Canonical 3 variants per name; `make all` / `make clean` / `make dist/entregables`
stl/                     # Generated STLs (gitignored — NEVER commit)
dist/                    # Distribution tarball (gitignored)
```

A new design is a **filename**, not a new model: adding `designs/{name}.scad` is enough —
both `make all` and `render.sh` derive `NOMBRE` from it. Design stubs may be nearly empty
(they only exist for opening a design directly in OpenSCAD).

## Design Decisions (read before changing geometry)

### Template-driven generation (the core rule)

- One source of truth: `template.scad` + `lib/keychain.scad`. Never fork per-name geometry
  into `designs/{name}.scad` — those files are stubs that call `keychain("Name")`.
- Render parameters are passed as `-D` overrides: `NOMBRE`, `BASE` (base plate on/off),
  `ENGRAVED` (inciso=true / relieve=false), `RING` (integrated ring replaces base), `FONT`.
- STL naming is the contract (standardized from hyphenated names in the 2026-09 alignment):
  `{name}.stl` (text only), `{name}_base_relieve.stl`, `{name}_base_inciso.stl`,
  `{name}_anilla.stl`. Do not introduce naming variants; render.sh encodes these.

### Text rendering (invariants)

- Letters on the base are spaced with `spacing = 0.88` and expanded with
  `connect_offset = 0.3` so adjacent letters touch — the continuous-script look.
- `_char_width()` is a hand-maintained per-character width table (meters of the average
  letterbox); it sizes the base around the text. If characters render wrong on a base,
  the table — not the font metrics — is the first suspect. Add missing characters there.
- Relieve = text extruded ABOVE the base (`union`); inciso = text subtracted INTO the base
  (`difference`). Both use the same `_render_text` path.
- Ring variant: text centered with a ring (`ring_outer_r 3.5 / ring_inner_r 2`) attached at
  the first character's top.
- Circles use `$fn = 64` (ring, hole); keep resolution sane — keychains are small,
  heavy meshes add slicing time without visible benefit.
- Fonts come from the OS font list (default "Brush Script MT"); `fonts/*.txt` group names
  for batch rendering. Prefer fonts installed on macOS; a missing font degrades silently.

### Makefile vs render.sh (when to use which)

- `make all` is the canonical CI/build path: 3 variants per name (text, relieve, inciso).
- `render.sh` adds the `_anilla` variant, font groups (`--group cursivas|manuscritas`),
  per-name batches, `--parallel`, and `--clean`/`--dist`. Keep the variant lists in both
  in sync (`VARIANTS` in render.sh vs the Makefile rules).
- `make dist/entregables` tarballs `stl/` into `dist/keychains-3d.tar.gz` (gitignored).

## Working Rules for Agents

- Never edit `designs/{name}.scad` to change geometry — edit `lib/keychain.scad` or
  `template.scad`. Add a name only as a stub file.
- English in commit messages; Spanish is already pervasive in comments/scripts — either is fine.
- Verify after ANY change to the library: render one name with all variants
  (`make all` and/or `./render.sh marcos`), confirm naming, and check the relieve/inciso
  and base/no-base variants all produce distinct expected STLs.
- Docs split: **README.md** = maker-facing (variants table, print settings, usage);
  **AGENTS.md** = author-facing (this file, the design system). Do not duplicate facts —
  cross-reference instead.
- Commit conventions: semantic English messages (`feat:`/`fix:`/`chore:`/`test:`), one
  concern per commit. Use the git-master skill workflow beyond plain commit+push.