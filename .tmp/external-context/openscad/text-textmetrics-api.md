---
source: Wikibooks OpenSCAD User Manual + GitHub issues
library: OpenSCAD
package: openscad
topic: text() and textmetrics() API
fetched: 2026-05-24T12:00:00Z
official_docs: https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Text
---

# OpenSCAD `text()` and `textmetrics()` API Reference

## 1. `text()` Module

The `text` module creates text as a 2D geometric object, using fonts installed on the local system or provided as separate font file.

**Requires version:** 2015.03+

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `text` | String | (required) | The text to generate |
| `size` | Number | 10 | Approximately the height of capital letters (western script). Sets em size to 100/72 × this value. |
| `font` | String | "Liberation Sans" | Logical font name (via fontconfig). Can include style, e.g. `"Liberation Sans:style=Bold Italic"` |
| `direction` | String | "ltr" | Text flow: `"ltr"`, `"rtl"`, `"ttb"`, `"btt"` |
| `language` | String | "en" | Language (e.g., "en", "ar", "ch") |
| `script` | String | "latin" | Script (e.g., "latin", "arabic", "hani") |
| `halign` | String | "left" | Horizontal alignment: `"left"`, `"center"`, `"right"` |
| `valign` | String | "baseline" | Vertical alignment: `"top"`, `"center"`, `"baseline"`, `"bottom"` |
| `spacing` | Number | 1 | Factor to increase/decrease character spacing. Default 1 = normal spacing; > 1 = wider; < 1 = tighter |
| `em` | Number | — | Size of the em-square (industry-standard font sizing). **Note:** Requires Development snapshot |
| `$fn`, `$fs`, `$fa` | — | — | Used for subdividing curved segments of glyphs |

### Alignment Details

#### Vertical Alignment
- **top** — Top of tallest character at given Y coordinate
- **center** — Center of bounding box at given Y coordinate
- **baseline** — Font baseline at given Y coordinate (default; best for multi-line alignment)
- **bottom** — Bottom of lowest character at given Y coordinate

#### Horizontal Alignment
- **left** — Left of bounding box at given X coordinate (default)
- **center** — Center of bounding box at given X coordinate
- **right** — Right of bounding box at given X coordinate

> **Note:** `text()` does NOT support multi-line text. For multiple lines, use separate `text()` calls with `translate()`. Use `valign="baseline"` for even line spacing. Minimum spacing of `1.4 * size` prevents overlapping; `1.6 * size` ≈ typical single-spacing.

---

## 2. `textmetrics()` Function

**Requires version:** Development snapshot (not yet in a stable release)

### Version History
- **2021-02-21:** Introduced in [PR #3684](https://github.com/openscad/openscad/pull/3684) by jordanbrown0
- **2024-05-25:** Still experimental; requires `--enable textmetrics` flag on command line ([Issue #5150](https://github.com/openscad/openscad/issues/5150))
- **2024-12-22:** Issue [#5516](https://github.com/openscad/openscad/issues/5516) opened to make it "release ready" — includes final API validation, moving out of experimental, and validating test coverage
- **Status:** Still flagged as "Development snapshot" / experimental as of May 2026

The `textmetrics()` function accepts the **same parameters** as `text()`, and returns an **object** describing how that text would be rendered.

### Return Value (Object)

| Member | Type | Description |
|--------|------|-------------|
| `position` | [x, y] | Lower-left corner of the smallest box that completely surrounds the rendered text |
| `size` | [x, y] | Width and height of that bounding box |
| `ascent` | Number | Vertical distance (normally positive) from the baseline to the highest point in the text |
| `descent` | Number | Vertical distance (normally zero or negative) from the baseline to the lowest point in the text |
| `offset` | [x, y] | Distance from the origin to the starting point of the baseline. Normally [0, 0] except with non-default alignments |
| `advance` | [x, y] | Distance from the starting point of this text to the starting point for subsequent text. Tells you how far to "move the pen" before the next piece of text |

> **Note:** You can use either array indexing or object notation for [x,y] pairs: `tm.size[0]` or `tm.size.x` / `tm.size.y`.

### Example

```openscad
s = "Hello, World!";
size = 20;
font = "Liberation Serif";

tm = textmetrics(s, size=size, font=font);
echo(tm);
translate([0,0,1]) text("Hello, World!", size=size, font=font);
color("black") translate(tm.position) square(tm.size);
```

**Output** (reformatted for readability):
```
ECHO: {
    position = [0.7936, -4.2752];
    size = [149.306, 23.552];
    ascent = 19.2768;
    descent = -4.2752;
    offset = [0, 0];
    advance = [153.09, 0];
}
```

### Command-Line Usage

When running OpenSCAD from the command line, you must explicitly enable textmetrics:

```bash
openscad --enable textmetrics -o output.stl script.scad
```

---

## 3. Getting Bounding Box / Position of Individual Characters

`textmetrics()` returns metrics for the **entire text string as a whole**. To get per-character bounding boxes, you must call `textmetrics()` on **each character individually**. There is no built-in function that returns an array of per-character metrics.

### Example: Per-Character Bounding Boxes

```openscad
text_str = "Hello";
size = 20;
font = "Liberation Sans";

for (i = [0 : len(text_str) - 1]) {
    char = text_str[i];
    tm = textmetrics(text=char, size=size, font=font);
    
    // Position this character using the advance of all previous characters
    // This is an approximation — proper kerning would need per-pair advance tracking
    translate([offset, 0, 0]) {
        color("black") translate(tm.position) square(tm.size);
        color("blue") text(char, size=size, font=font);
    }
    offset = offset + tm.advance.x;
}
```

> **Limitation:** Using `tm.advance.x` to position successive characters doesn't account for kerning between character pairs. For fully accurate per-character layout, you'd need to track pairwise advances yourself. However, for most purposes, this approach is sufficient.

### Alternative: Use `search()` + `textmetrics()` for Spacing Arrays

You can build a list of per-character advances and positions:

```openscad
text_str = "Hello";
sizes = [for (c = text_str) textmetrics(text=c, size=20).size];
advances = [for (c = text_str) textmetrics(text=c, size=20).advance.x];
positions = [for (i = [0 : len(advances) - 1]) 
    i == 0 ? 0 : sum([for (j = [0 : i - 1]) advances[j]])
];
```

---

## 4. Pre-`textmetrics()` Equivalents (Before Development Snapshots)

Before `textmetrics()` existed, there was **no built-in way** to query text dimensions from within OpenSCAD. Common workarounds included:

1. **`fontmetrics()`** — Provides font-level metrics (ascent, descent, interline spacing) but NOT per-text-string measurements. Available in the same Development snapshot as `textmetrics()`.

2. **External measurement** — Use an external script/tool to render text and measure it, then pass the dimensions back into OpenSCAD as parameters.

3. **Known font sizing** — Hard-code dimensions based on the font family and size. E.g., for Liberation Sans at size 10, capital letters are ~7 units tall. This was unreliable across different fonts.

4. **Trial and error** — Render text, check visually, adjust positioning.

5. **Custom font data** — Use a font file parser library in a separate script to extract glyph metrics.

### `fontmetrics()` Function (for reference)

Also requires Development snapshot. Returns font-level (not text-string-level) metrics:

| Member | Type | Description |
|--------|------|-------------|
| `nominal` | {ascent, descent} | "Usual" ascent/descent for the font (e.g., uppercase ascent, lowercase descender depth) |
| `max` | {ascent, descent} | Maximum ascent/descent across all glyphs in the font |
| `interline` | Number | Designed inter-line spacing (positive number) |
| `font` | {family, style} | Actual font family and style name (may differ from what was requested if fallback occurred) |

**Example:**
```openscad
echo(fontmetrics(font="Liberation Serif"));
// Output:
// ECHO: {
//     nominal = { ascent = 12.3766; descent = -3.0043; };
//     max = { ascent = 13.6312; descent = -4.2114; };
//     interline = 15.9709;
//     font = { family = "Liberation Serif"; style = "Regular"; };
// }
```

---

## 5. `text()` `spacing` Parameter — Detailed Notes

The `spacing` parameter controls **inter-character spacing** (also known as tracking in typography).

| Value | Effect |
|-------|--------|
| `spacing = 1` | Default — normal font spacing |
| `spacing > 1` | Letters spaced further apart (expanded tracking) |
| `spacing < 1` | Letters spaced closer together (condensed tracking) |
| `spacing = 0` | Letters would overlap significantly (typically not useful) |

### How it works
- The value is a **multiplicative factor** applied to the font's built-in character advance widths.
- `spacing = 1.5` means 50% additional space between characters.
- `spacing = 0.8` means 20% less space between characters.
- It does NOT affect the characters' own glyph widths — only the space *between* them.
- The `textmetrics()` function **respects** the `spacing` parameter, so you can measure spacing-adjusted text.

### Example
```openscad
// Normal spacing
text("Hello", size=20);

// Widely spaced
translate([0, -30, 0]) text("Hello", size=20, spacing=1.5);

// Tight spacing
translate([0, -60, 0]) text("Hello", size=20, spacing=0.7);
```

---

## Quick Reference Summary

| Function | Availability | Returns |
|----------|-------------|---------|
| `text()` | 2015.03+ | 2D geometry (module, not function) |
| `textmetrics()` | Development snapshot (experimental) | Object with position, size, ascent, descent, offset, advance |
| `fontmetrics()` | Development snapshot | Object with nominal, max, interline, font family/style |
| `text()` `spacing` param | 2015.03+ | Multiplicative factor (default 1) for inter-character spacing |
| `text()` `em` param | Development snapshot | Sets em-square size directly |
