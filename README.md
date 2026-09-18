# keychains-3d

Parametric keychain generator. Each design is rendered from a shared template into multiple variants: plain text, text on a base (embossed or engraved), and text with an integrated ring.

## Description

This repo generates personalised keychains from a single `template.scad` file and a shared `lib/keychain.scad` library.

Variants per name:

| Variant | Description |
|---------|-------------|
| `{name}.stl` | Text only, no base |
| `{name}_base_relieve.stl` | Text on a base, embossed (relieve) |
| `{name}_base_inciso.stl` | Text on a base, engraved (inciso) |
| `{name}_anilla.stl` | Text with integrated ring |

Fonts are grouped into families (e.g., *cursivas*, *manuscritas*) and batch-rendered per group.

## Print Settings

| Setting | Value |
|---------|-------|
| Layer height | 0.2 mm |
| Infill | 15–20 % |
| Supports | No |
| Orientation | Flat on build plate |
| Perimeters | 2 |

**Recommended filament**: PLA or PETG.

## Rendering

### Makefile (default variants)

```bash
cd keychains-3d
make all            # Render all default variants into stl/
make clean          # Remove stl/ and dist/
make dist/entregables  # Create distribution tarball
```

### Render script (extended variants)

```bash
./render.sh                          # Render default font groups
./render.sh marcos                   # Render a specific design
./render.sh --group cursivas         # Render one font group
./render.sh --parallel               # Render in parallel
./render.sh --dist                   # Render all + create tarball
```

Requires [OpenSCAD](https://openscad.org/) (macOS auto-discovered if installed in `/Applications`).

## Adding a new design

1. Create `designs/{name}.scad` (can be empty; the template reads the filename).
2. Run `./render.sh {name}` or `make all`.

## License

CC-BY-4.0
