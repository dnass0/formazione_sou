#!/bin/sh
# Genera il libro in PDF unendo tutti i capitoli di docs/libro/ (NN-*.md) in ordine.
# Uso: sh docs/libro/pdf/genera-pdf.sh   (da qualsiasi directory)
# Serve: pandoc (>= 3.1) e typst.
set -e
DIR=$(cd "$(dirname "$0")" && pwd)
LIBRO=$(dirname "$DIR")
OGGI=$(date +%d/%m/%Y)

pandoc "$LIBRO"/[0-9][0-9]-*.md \
  --from=gfm \
  --pdf-engine=typst \
  --lua-filter="$DIR/link-come-testo.lua" \
  --include-in-header="$DIR/stile.typ" \
  --toc --toc-depth=1 \
  -V papersize=a4 \
  -V margin.x=2.2cm -V margin.y=2.5cm \
  -M title="Libro di testo – DevOps Academy" \
  -M subtitle="Linux System Administration e preparazione all'esame EX200" \
  -M author="Domenico Nasso" \
  -M date="Aggiornato al $OGGI" \
  -M lang=it \
  -o "$DIR/libro-devops-academy.pdf"

echo "Creato: $DIR/libro-devops-academy.pdf"
