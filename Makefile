OPENSCAD ?= openscad

ifeq ($(shell command -v $(OPENSCAD) 2>/dev/null),)
  OPENSCAD := $(firstword $(wildcard /Applications/OpenSCAD*.app/Contents/MacOS/OpenSCAD))
  ifeq ($(OPENSCAD),)
    $(error OpenSCAD not found. Set OPENSCAD=<path> or install with: brew install openscad)
  endif
endif

TEMPLATE := template.scad
LIB := lib/keychain.scad
DESIGNS_DIR := designs
STL_DIR := stl
DIST_DIR := dist
DIST_ARCHIVE := $(DIST_DIR)/keychains-3d.tar.gz

DESIGN_NAMES := $(basename $(notdir $(wildcard $(DESIGNS_DIR)/*.scad)))

STLS_RELIEVE := $(addprefix $(STL_DIR)/, $(addsuffix -base-relieve.stl, $(DESIGN_NAMES)))
STLS_INCISO  := $(addprefix $(STL_DIR)/, $(addsuffix -base-inciso.stl, $(DESIGN_NAMES)))
STLS_NOBASE  := $(addprefix $(STL_DIR)/, $(addsuffix .stl, $(DESIGN_NAMES)))
ALL_STLS     := $(STLS_RELIEVE) $(STLS_INCISO) $(STLS_NOBASE)

.PHONY: all clean dist/entregables

capitalize = $(shell echo $(1) | awk '{print toupper(substr($$0,1,1)) substr($$0,2)}')

all: $(ALL_STLS)

$(STL_DIR)/%-base-relieve.stl: $(TEMPLATE) $(LIB)
	@mkdir -p $(STL_DIR)
	$(OPENSCAD) -o "$@" -D 'NOMBRE="$(call capitalize,$*)"' -D 'BASE=true' -D 'ENGRAVED=false' "$<"

$(STL_DIR)/%-base-inciso.stl: $(TEMPLATE) $(LIB)
	@mkdir -p $(STL_DIR)
	$(OPENSCAD) -o "$@" -D 'NOMBRE="$(call capitalize,$*)"' -D 'BASE=true' -D 'ENGRAVED=true' "$<"

$(STL_DIR)/%.stl: $(TEMPLATE) $(LIB)
	@mkdir -p $(STL_DIR)
	$(OPENSCAD) -o "$@" -D 'NOMBRE="$(call capitalize,$*)"' -D 'BASE=false' "$<"

$(DIST_ARCHIVE): $(ALL_STLS)
	@mkdir -p $(DIST_DIR)
	@echo "Creando archivo de distribucion: $@"
	tar -czf "$@" $(STL_DIR)

dist/entregables: $(DIST_ARCHIVE)
	@echo "Distribucion lista: $(DIST_ARCHIVE)"

clean:
	rm -rf $(STL_DIR) $(DIST_DIR)
