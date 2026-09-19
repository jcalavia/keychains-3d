// keychain.scad - Generador de llaveros 3D personalizados
//
// Uso:
//   use <keychain.scad>
//   keychain("Tania");
//
// Parámetros:
//   name          - Nombre a renderizar
//   font_size     - Altura de las letras en mm (defecto: 12)
//   base_height   - Grosor de la base en mm (defecto: 3)
//   text_height   - Altura del relieve/inciso en mm (defecto: 2)
//   hole_diameter - Diámetro del agujero en mm (defecto: 5)
//   spacing       - Espaciado entre letras, < 1 las junta (defecto: 0.88)
//   font          - Fuente OpenSCAD (defecto: "Brush Script MT")
//   margin        - Padding alrededor del texto en mm (defecto: 5)
//   corner_r      - Radio de esquinas redondeadas en mm (defecto: 3)
//   engraved      - false = relieve, true = inciso (defecto: false)
//   connect_offset - Expande letras para que se toquen en mm (0 = desactivado, defecto: 0.3)
//   hole_top      - true = agujero arriba-centro (colgante/chapa de mascota, defecto: false)
//   ring           - true añade anilla en lugar de base (defecto: false)
//   ring_outer_r   - Radio exterior de la anilla en mm (defecto: 3.5)
//   ring_inner_r   - Radio interior de la anilla en mm (defecto: 2)

module _render_text(name, font_size, font, spacing, connect_offset, halign = "left", valign = "baseline") {
    if (connect_offset > 0) {
        offset(r = connect_offset)
            text(name, size = font_size, font = font, spacing = spacing, halign = halign, valign = valign);
    } else {
        text(name, size = font_size, font = font, spacing = spacing, halign = halign, valign = valign);
    }
}

module _ring(outer_r, inner_r, height) {
    linear_extrude(height = height, convexity = 4)
        difference() {
            circle(r = outer_r, $fn = 64);
            circle(r = inner_r, $fn = 64);
        }
}

module keychain(
    name,
    font_size = 12,
    base_height = 3,
    text_height = 2,
    hole_diameter = 5,
    spacing = 0.88,
    font = "Brush Script MT",
    margin = 5,
    corner_r = 3,
    engraved = false,
    connect_offset = 0.3,
    base = true,
    ring = false,
    hole_top = false,
    ring_outer_r = 3.5,
    ring_inner_r = 2
) {
    assert(len(name) > 0, "keychain: name no puede estar vacío");
    assert(!hole_top || base, "keychain: hole_top (colgante) requiere base = true");

    if (base) {
        if (hole_top) {
            // Colgante / chapa de mascota: agujero arriba-centro y texto inciso centrado debajo.
            // Siempre inciso: el relieve se desgasta rápido en una chapa de collar.
            text_w = _text_width(name, font_size) * 1.5;
            hole_gap = font_size * 0.6;   // separación vertical agujero-texto

            base_w = max(text_w, hole_diameter) + margin * 2 + 2 * connect_offset;
            base_h = margin + hole_diameter + hole_gap + font_size + margin + 2 * connect_offset;

            hole_x = base_w / 2;
            hole_y = margin + hole_diameter / 2;

            text_x = (base_w - (text_w + 2 * connect_offset)) / 2;
            text_y = margin + hole_diameter + hole_gap + connect_offset;

            difference() {
                linear_extrude(height = base_height, convexity = 10)
                    offset(r = corner_r)
                        square([base_w - corner_r * 2, base_h - corner_r * 2]);

                translate([hole_x, hole_y, -0.1])
                    cylinder(h = base_height + 0.2, r = hole_diameter / 2, $fn = 64);

                translate([text_x, text_y, base_height - text_height])
                    linear_extrude(height = text_height + 0.1, convexity = 10)
                        _render_text(name, font_size, font, spacing, connect_offset);
            }
        } else {
            text_w = _text_width(name, font_size) * 1.5;

            base_w = margin + hole_diameter + margin + text_w + margin + 2 * connect_offset;
            base_h = font_size + margin * 2 + 2 * connect_offset;

            hole_x = margin + hole_diameter / 2;
            hole_y = base_h / 2;

            text_x = margin + hole_diameter + margin;
            text_y = (base_h - (font_size + 2 * connect_offset)) / 2;

            if (engraved) {
                difference() {
                    linear_extrude(height = base_height, convexity = 10)
                        offset(r = corner_r)
                            square([base_w - corner_r * 2, base_h - corner_r * 2]);

                    translate([hole_x, hole_y, -0.1])
                        cylinder(h = base_height + 0.2, r = hole_diameter / 2, $fn = 64);

                    translate([text_x, text_y, base_height - text_height])
                        linear_extrude(height = text_height + 0.1, convexity = 10)
                            _render_text(name, font_size, font, spacing, connect_offset);
                }
            } else {
                difference() {
                    linear_extrude(height = base_height, convexity = 10)
                        offset(r = corner_r)
                            square([base_w - corner_r * 2, base_h - corner_r * 2]);

                    translate([hole_x, hole_y, -0.1])
                        cylinder(h = base_height + 0.2, r = hole_diameter / 2, $fn = 64);
                }

                translate([text_x, text_y, base_height])
                    linear_extrude(height = text_height, convexity = 10)
                        _render_text(name, font_size, font, spacing, connect_offset);
            }
        }
    } else if (ring) {
        total_w = _text_width(name, font_size);
        first_char_x = -total_w / 2;
        first_char_top = font_size * 0.35;

        union() {
            linear_extrude(height = text_height, convexity = 10)
                _render_text(name, font_size, font, spacing, connect_offset, "center", "center");

            translate([first_char_x, first_char_top, 0])
                _ring(ring_outer_r, ring_inner_r, text_height);
        }
    } else {
        // Solo texto centrado, sin base ni agujero
        linear_extrude(height = text_height, convexity = 10)
            _render_text(name, font_size, font, spacing, connect_offset, "center", "center");
    }
}

function _text_width(name, fs) = _sum([for (i = [0 : len(name) - 1]) _char_width(name[i]) * fs]);

function _sum(v, i = 0) = i < len(v) ? v[i] + _sum(v, i + 1) : 0;

function _char_width(c) =
    c == "I" ? 0.30 :
    c == "J" ? 0.38 :
    c == "L" ? 0.40 :
    c == "T" ? 0.50 :
    c == "M" || c == "W" ? 0.72 :
    c == "O" || c == "Q" || c == "S" ? 0.55 :
    c == "B" || c == "D" || c == "P" || c == "R" ? 0.55 :
    c == "C" || c == "G" ? 0.52 :
    c == "A" || c == "H" || c == "N" || c == "U" ? 0.58 :
    c == "E" || c == "F" || c == "K" || c == "V" || c == "X" || c == "Y" || c == "Z" ? 0.50 :
    c == "i" || c == "l" ? 0.22 :
    c == "j" || c == "t" || c == "r" ? 0.28 :
    c == "f" ? 0.30 :
    c == "m" || c == "w" ? 0.62 :
    0.45;

