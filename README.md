# kicad-action

GitHub Action to automate KiCad tasks, e.g. check ERC/DRC on pull requests or
generate production files for releases.

## Features

- Run Electrical Rules Check (ERC) on schematic
- Run Design Rules Check (DRC) on PCB
- Generate PDF and BOM from schematic
- Generate Gerbers ZIP from PCB
- Generate raytraced board images

## Example

```yaml
on: [push]

jobs:
  kicad_job:
    runs-on: ubuntu-latest
    name: My KiCad job
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Export production files
        id: production
        uses: sparkengineering/kicad-action@v4
        if: '!cancelled()'
        with:
          kicad_sch: my-project.kicad_sch
          sch_pdf: true # Generate PDF
          sch_bom: true # Generate BOM
          kicad_pcb: my-project.kicad_pcb
          pcb_gerbers: true # Generate Gerbers

      # Upload production files only if generation succeeded
      - name: Upload production files
        uses: actions/upload-artifact@v4
        if: ${{ !cancelled() && steps.production.conclusion == 'success' }}
        with:
          name: Production files
          path: |
            ${{ github.workspace }}/sch.pdf
            ${{ github.workspace }}/bom.csv
            ${{ github.workspace }}/gbr.zip

      - name: Run KiCad ERC
        id: erc
        uses: sparkengineering/kicad-action@v4
        if: '!cancelled()'
        with:
          kicad_sch: my-project.kicad_sch
          sch_erc: true

      - name: Run KiCad DRC
        id: drc
        uses: sparkengineering/kicad-action@v4
        if: '!cancelled()'
        with:
          kicad_pcb: my-project.kicad_pcb
          pcb_drc: true

      # Upload ERC report only if ERC failed
      - name: Upload ERC report
        uses: actions/upload-artifact@v4
        if: ${{ failure() && steps.erc.conclusion == 'failure' }}
        with:
          name: erc.rpt
          path: ${{ github.workspace }}/erc.rpt

      # Upload DRC report only if DRC failed
      - name: Upload DRC report
        uses: actions/upload-artifact@v4
        if: ${{ failure() && steps.drc.conclusion == 'failure' }}
        with:
          name: drc.rpt
          path: ${{ github.workspace }}/drc.rpt
```

See this example working in the action runs of this repository.

## Configuration
| Option               | Description                                                      | Default                      |
|----------------------|------------------------------------------------------------------|------------------------------|
| `kicad_sch`          | Path to the `.kicad_sch` file                                    |                              |
| `sch_erc`            | Whether to run ERC (Electrical Rules Check) on the schematic     | `false`                      |
| `sch_erc_file`       | Output filename for the ERC report                               | `erc.rpt`                    |
| `sch_pdf`            | Whether to generate a PDF from the schematic                     | `false`                      |
| `sch_pdf_file`       | Output filename for the schematic PDF                            | `sch.pdf`                    |
| `sch_bom`            | Whether to generate a BOM (Bill of Materials) from the schematic | `false`                      |
| `sch_bom_file`       | Output filename for the BOM                                      | `bom.csv`                    |
| `sch_bom_preset`     | Name of a BOM preset to use                                      |                              |
| `report_format`      | Format for ERC/DRC reports (`json` or `report`)                  | `report`                     |
|                      |                                                                  |                              |
| `kicad_pcb`          | Path to the `.kicad_pcb` file                                    |                              |
| `pcb_drc`            | Whether to run DRC (Design Rules Check) on the PCB               | `false`                      |
| `pcb_drc_file`       | Output filename for the DRC report                               | `drc.rpt`                    |
| `pcb_gerbers`        | Whether to generate Gerber files from the PCB                    | `false`                      |
| `pcb_gerbers_file`   | Output filename for the Gerber archive                           | `gbr.zip`                    |
| `pcb_gerbers_layers` | Comma-separated list of PCB layers to include in Gerber output:  |                              |
|                      | `F.Cu,B.Cu,F.SilkS,B.SilkS,F.Mask,B.Mask,Edge.Cuts`              |                              |
| `pcb_centroids`      | Whether to generate centroid (component placement) files from PCB| `false`                      |
| `pcb_centroids_file` | Output filename of centroid (component placement)                | `cnt.pos`                    |
| `pcb_centroids_format`| Output format to generate centroid files from PCB               | `ascii`                      |
| `pcb_image`          | Whether to render top and bottom PCB images                      | `false`                      |
| `pcb_image_path`     | Output directory for `top.png` and `bottom.png`                  | `images`                     |
| `pcb_model`          | Whether to export a 3D model of the PCB                          | `false`                      |
| `pcb_model_file`     | Output filename for the 3D model                                 | `pcb.step`                   |
| `pcb_model_flags`    | Additional flags to use when exporting the STEP model            | See [action.yml](action.yml) |

## Roadmap

- [ ] Add support for more configuration options, e.g. BOM format
- [ ] Add a way to specify KiCad version to use
- [ ] Better detect if steps of this action fail
- [ ] Find a better way to enforce the default output files extensions depending on the format requested

## Contributing

Contributions, e.g. in the form of issues or pull requests, are greatly appreciated.
