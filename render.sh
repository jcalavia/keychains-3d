#!/usr/bin/env bash
#
# render.sh - Renderiza 3 variantes OpenSCAD por diseno
#
# Variantes por diseno:
#   {nombre}-base-relieve.stl   - Base + texto en relieve
#   {nombre}-base-inciso.stl    - Base + texto inciso
#   {nombre}.stl                - Solo texto, sin base
#
# Uso:
#   ./render.sh                    - Renderiza todos los disenos
#   ./render.sh marcos             - Renderiza solo un diseno
#   ./render.sh --clean marcos     - Limpia y renderiza
#   ./render.sh --parallel         - Renderiza todos en paralelo
#   ./render.sh --dist             - Renderiza todos y genera distribucion
#

set -euo pipefail

TEMPLATE="template.scad"
LIB_DIR="lib"
STL_DIR="stl"
DIST_DIR="dist"
DIST_ARCHIVE="${DIST_DIR}/keychains-3d.tar.gz"
SHARED_LIB="${LIB_DIR}/keychain.scad"

OPENSCAD="${OPENSCAD:-openscad}"

if ! command -v "$OPENSCAD" &>/dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        found=$(find /Applications -maxdepth 4 -name "OpenSCAD" -path "*/MacOS/OpenSCAD" 2>/dev/null | head -1) || true
        if [[ -n "$found" ]]; then
            OPENSCAD="$found"
        fi
    fi
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CLEAN=false
PARALLEL=false
DIST=false
SPECIFIC=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean)     CLEAN=true; shift ;;
        --parallel)  PARALLEL=true; shift ;;
        --dist)      DIST=true; shift ;;
        --help|-h)   sed -n '2,13p' "$0"; exit 0 ;;
        *)
            if [[ -z "$SPECIFIC" ]]; then
                SPECIFIC="$1"
            else
                echo -e "${RED}Error: argumento inesperado: $1${NC}" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if ! command -v "$OPENSCAD" &>/dev/null && [[ ! -x "$OPENSCAD" ]]; then
    echo -e "${RED}Error: OpenSCAD no encontrado.${NC}" >&2
    echo "Instalalo con: brew install openscad" >&2
    exit 1
fi

if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}Limpiando directorios de salida...${NC}"
    rm -rf "$STL_DIR" "$DIST_DIR"
    echo -e "${GREEN}Hecho.${NC}"
fi

mkdir -p "$STL_DIR"

if [ -n "$SPECIFIC" ]; then
    if [ ! -f "designs/${SPECIFIC}.scad" ]; then
        echo -e "${RED}Error: no se encuentra designs/${SPECIFIC}.scad${NC}" >&2
        exit 1
    fi
    DESIGN_NAMES=("$SPECIFIC")
    echo -e "${CYAN}Diseno especifico: ${SPECIFIC}${NC}"
else
    DESIGN_FILES=($(ls designs/*.scad 2>/dev/null))
    if [ ${#DESIGN_FILES[@]} -eq 0 ]; then
        echo -e "${RED}Error: no se encontraron archivos designs/*.scad${NC}" >&2
        exit 1
    fi
    DESIGN_NAMES=()
    for f in "${DESIGN_FILES[@]}"; do
        DESIGN_NAMES+=("$(basename "$f" .scad)")
    done
    echo -e "${CYAN}Total de disenos: ${#DESIGN_NAMES[@]}${NC}"
fi

VARIANTS=(
    "base-relieve:true:false"
    "base-inciso:true:true"
    "texto:false:false"
)

get_output_name() {
    local name="$1"
    local variant="$2"
    if [ "$variant" = "texto" ]; then
        echo "${name}.stl"
    else
        echo "${name}-${variant}.stl"
    fi
}

render_one() {
    local name="$1"
    local variant="$2"
    local base_val="$3"
    local engraved_val="$4"
    local out_name
    out_name="$(get_output_name "$name" "$variant")"
    local dst="${STL_DIR}/${out_name}"

    local src_mtime=0 dst_mtime=0

    if [ -f "$TEMPLATE" ]; then
        tmpl_mtime=$(stat -f "%m" "$TEMPLATE" 2>/dev/null || echo 0)
        [ "$tmpl_mtime" -gt "$src_mtime" ] && src_mtime=$tmpl_mtime
    fi
    if [ -f "$SHARED_LIB" ]; then
        lib_mtime=$(stat -f "%m" "$SHARED_LIB" 2>/dev/null || echo 0)
        [ "$lib_mtime" -gt "$src_mtime" ] && src_mtime=$lib_mtime
    fi
    if [ -f "$dst" ]; then
        dst_mtime=$(stat -f "%m" "$dst" 2>/dev/null || echo 0)
    fi

    if [ "$dst_mtime" -ge "$src_mtime" ] && [ -f "$dst" ]; then
        echo -e "${YELLOW}  [SKIP]${NC} $out_name ya esta actualizado"
        return 0
    fi

    echo -e "${BLUE}  [RENDER]${NC} $out_name..."
    "$OPENSCAD" -o "$dst" \
        -D "NOMBRE=\"$name\"" \
        -D "BASE=$base_val" \
        -D "ENGRAVED=$engraved_val" \
        "$TEMPLATE"

    if [ -f "$dst" ]; then
        local size
        size=$(du -h "$dst" | cut -f1)
        echo -e "${GREEN}  [OK]${NC} $out_name ($size)"
    else
        echo -e "${RED}  [FAIL]${NC} $out_name" >&2
        return 1
    fi
}

echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${CYAN}  Renderizando disenos OpenSCAD${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"

TOTAL_JOBS=$(( ${#DESIGN_NAMES[@]} * 3 ))
echo -e "${CYAN}Total: ${#DESIGN_NAMES[@]} disenos x 3 variantes = ${TOTAL_JOBS} STLs${NC}"

RENDER_ERRORS=0

render_design() {
    local name="$1"
    for variant_info in "${VARIANTS[@]}"; do
        IFS=':' read -r variant base_val engraved_val <<< "$variant_info"
        render_one "$name" "$variant" "$base_val" "$engraved_val" || RENDER_ERRORS=$((RENDER_ERRORS + 1))
    done
}

if [ "$PARALLEL" = true ] && [ ${#DESIGN_NAMES[@]} -gt 1 ]; then
    echo -e "${YELLOW}Modo paralelo habilitado${NC}"
    for name in "${DESIGN_NAMES[@]}"; do
        render_design "$name" &
    done
    wait
else
    for name in "${DESIGN_NAMES[@]}"; do
        render_design "$name"
    done
fi

echo -e "${CYAN}═══════════════════════════════════════════${NC}"

if [ "$DIST" = true ]; then
    echo -e "${YELLOW}Generando archivo de distribucion...${NC}"
    mkdir -p "$DIST_DIR"
    tar -czf "$DIST_ARCHIVE" "$STL_DIR"
    echo -e "${GREEN}Distribucion creada: ${DIST_ARCHIVE}${NC}"
fi

if [ "$RENDER_ERRORS" -gt 0 ]; then
    echo -e "${RED}  Finalizado con ${RENDER_ERRORS} error(es)${NC}"
    exit 1
else
    echo -e "${GREEN}Todos los disenos renderizados correctamente.${NC}"
fi
