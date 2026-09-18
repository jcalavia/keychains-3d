use <lib/keychain.scad>

// --- Parameters ---
NOMBRE = "Nombre";        // Text to render on the keychain
BASE = true;              // true = with base plate, false = text only
ENGRAVED = false;         // true = engraved text, false = embossed text
FONT = "Brush Script MT"; // OpenSCAD font name
RING = false;             // true = integrated ring instead of base plate

keychain(NOMBRE, base = BASE, engraved = ENGRAVED, font = FONT, ring = RING);
