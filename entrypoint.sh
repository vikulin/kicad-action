#!/bin/bash

set -e

mkdir -p $HOME/.config
cp -r /home/kicad/.config/kicad $HOME/.config/

erc_violation=0 # ERC exit code
drc_violation=0 # DRC exit code

# Run ERC if requested
if [[ -n $INPUT_KICAD_SCH ]] && [[ -n $INPUT_SCH_ERC_FILE ]]
then
  kicad-cli sch erc \
    --output "`dirname $INPUT_KICAD_SCH`/$INPUT_SCH_ERC_FILE" \
    --format $INPUT_REPORT_FORMAT \
    --severity-error \
    --exit-code-violations \
    "$INPUT_KICAD_SCH"
  erc_violation=$?
fi

# Export schematic PDF if requested
if [[ -n $INPUT_KICAD_SCH ]] && [[ -n $INPUT_SCH_PDF_FILE ]]
then
  kicad-cli sch export pdf \
    --output "`dirname $INPUT_KICAD_SCH`/$INPUT_SCH_PDF_FILE" \
    "$INPUT_KICAD_SCH"
fi

# Export schematic BOM if requested
if [[ -n $INPUT_KICAD_SCH ]] && [[ -n $INPUT_SCH_BOM_FILE ]]
then
  kicad-cli sch export bom \
    --output "`dirname $INPUT_KICAD_SCH`/$INPUT_SCH_BOM_FILE" \
    --preset "$INPUT_SCH_BOM_PRESET" \
    "$INPUT_KICAD_SCH"
fi

# Run DRC if requested
if [[ -n $INPUT_KICAD_PCB ]] && [[ -n $INPUT_PCB_DRC_FILE ]]
then
  kicad-cli pcb drc \
    --output "`dirname $INPUT_KICAD_PCB`/$INPUT_PCB_DRC_FILE" \
    --format $INPUT_REPORT_FORMAT \
    --severity-error \
    --exit-code-violations \
    "$INPUT_KICAD_PCB"
  drc_violation=$?
fi

# Export Gerbers if requested
if [[ -n $INPUT_KICAD_PCB ]] && [[ -n $INPUT_PCB_GERBERS_FILE ]]
then
  GERBERS_DIR=`mktemp -d`
  if [[ -n $INPUT_PCB_GERBERS_LAYERS ]]; then
    kicad-cli pcb export gerbers \
      --layers "$INPUT_PCB_GERBERS_LAYERS" \
      --output "$GERBERS_DIR/" \
      "$INPUT_KICAD_PCB"
  else
    kicad-cli pcb export gerbers \
      --output "$GERBERS_DIR/" \
      "$INPUT_KICAD_PCB"
  fi
  kicad-cli pcb export drill \
    --output "$GERBERS_DIR/" \
    "$INPUT_KICAD_PCB"
  zip -j \
    "`dirname $INPUT_KICAD_PCB`/$INPUT_PCB_GERBERS_FILE" \
    "$GERBERS_DIR"/*
fi

# Export centroid (placement) file if requested
if [[ -n "$INPUT_KICAD_PCB" ]] && [[ -n "$INPUT_PCB_CENTROIDS_FILE" ]]
then
  echo "Exporting centroid (placement) file to $INPUT_PCB_CENTROIDS_FILE..."
  kicad-cli pcb export pos \
    --format "$INPUT_PCB_CENTROIDS_FORMAT" \
    --output "`dirname $INPUT_KICAD_PCB`/$INPUT_PCB_CENTROIDS_FILE" \
    --units mm \
    "$INPUT_KICAD_PCB"
fi

if [[ -n $INPUT_KICAD_PCB ]] && [[ -n $INPUT_PCB_TOP_IMAGE_FILE ]]; then
  mkdir -p "`dirname $INPUT_KICAD_PCB`/`dirname $INPUT_PCB_TOP_IMAGE_FILE`"
  
  CMD_TOP=(kicad-cli pcb render --side top)
  CMD_TOP+=(--output "`dirname $INPUT_KICAD_PCB`/$INPUT_PCB_TOP_IMAGE_FILE")
  
  if [[ -n $INPUT_PCB_TOP_IMAGE_ZOOM ]]; then
    CMD_TOP+=(--zoom "$INPUT_PCB_TOP_IMAGE_ZOOM")
  fi
  
  if [[ -n $INPUT_PCB_TOP_IMAGE_WIDTH ]]; then
    CMD_TOP+=(--width "$INPUT_PCB_TOP_IMAGE_WIDTH")
  fi

  if [[ -n $INPUT_PCB_TOP_IMAGE_HEIGHT ]]; then
    CMD_TOP+=(--height "$INPUT_PCB_TOP_IMAGE_HEIGHT")
  fi
  
  if [[ -n $INPUT_PCB_TOP_IMAGE_QUALITY ]]; then
    CMD_TOP+=(--quality "$INPUT_PCB_TOP_IMAGE_QUALITY")
  fi
  
  "${CMD_TOP[@]}" "$INPUT_KICAD_PCB"
fi

if [[ -n $INPUT_KICAD_PCB ]] && [[ -n $INPUT_PCB_BOTTOM_IMAGE_FILE ]]; then
  mkdir -p "`dirname $INPUT_KICAD_PCB`/`dirname $INPUT_PCB_BOTTOM_IMAGE_FILE`"
  
  CMD_BOTTOM=(kicad-cli pcb render --side bottom)
  CMD_BOTTOM+=(--output "`dirname $INPUT_KICAD_PCB`/$INPUT_PCB_BOTTOM_IMAGE_FILE")
  
  if [[ -n $INPUT_PCB_BOTTOM_IMAGE_ZOOM ]]; then
    CMD_BOTTOM+=(--zoom "$INPUT_PCB_BOTTOM_IMAGE_ZOOM")
  fi
  
  if [[ -n $INPUT_PCB_BOTTOM_IMAGE_WIDTH ]]; then
    CMD_BOTTOM+=(--width "$INPUT_PCB_BOTTOM_IMAGE_WIDTH")
  fi

  if [[ -n $INPUT_PCB_BOTTOM_IMAGE_HEIGHT ]]; then
    CMD_BOTTOM+=(--height "$INPUT_PCB_BOTTOM_IMAGE_HEIGHT")
  fi

  if [[ -n $INPUT_PCB_BOTTOM_IMAGE_QUALITY ]]; then
    CMD_BOTTOM+=(--quality "$INPUT_PCB_BOTTOM_IMAGE_QUALITY")
  fi

  "${CMD_BOTTOM[@]}" "$INPUT_KICAD_PCB"
fi

if [[ -n $INPUT_KICAD_PCB ]] && [[ -n $INPUT_PCB_MODEL_FILE ]]
then
  kicad-cli pcb export step $INPUT_PCB_MODEL_FLAGS \
    --output "`dirname $INPUT_KICAD_PCB`/$INPUT_PCB_MODEL_FILE" \
    "$INPUT_KICAD_PCB"
fi

# Return non-zero exit code for ERC or DRC violations
if [[ $erc_violation -gt 0 ]] || [[ $drc_violation -gt 0 ]]
then
  exit 1
else
  exit 0
fi
