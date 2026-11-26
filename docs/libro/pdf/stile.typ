// Stile del libro: solo scale di grigi e grassetto.
#set text(lang: "it", size: 10.5pt, fill: black)
#set par(justify: true, leading: 0.65em)
#show link: set text(fill: black)
#show link: underline

// Ogni capitolo (titolo di primo livello) inizia su una pagina nuova.
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(1em)
  text(size: 20pt, weight: "bold", it.body)
  v(0.3em)
  line(length: 100%, stroke: 0.8pt + luma(60))
  v(0.8em)
}
#show heading.where(level: 2): it => {
  v(0.8em)
  text(size: 14pt, weight: "bold", it.body)
  v(0.2em)
}
#show heading: set text(fill: black)

// Codice: sfondo grigio chiaro, carattere monospazio.
#show raw: set text(font: ("DejaVu Sans Mono", "Menlo"), size: 8.5pt)
#show raw.where(block: true): it => block(
  fill: luma(238), inset: 8pt, width: 100%, stroke: 0.5pt + luma(180), it)
#show raw.where(block: false): box.with(fill: luma(235), inset: (x: 2pt), outset: (y: 2pt))

// Citazioni (le note "> ...") con un filetto grigio a sinistra.
#show quote.where(block: true): it => block(
  stroke: (left: 2pt + luma(150)), inset: (left: 10pt, y: 4pt), it.body)

// Tabelle: bordi grigi, intestazione in grassetto su grigio.
#set table(stroke: 0.5pt + luma(150), fill: (_, y) => if y == 0 { luma(225) })
#show table.cell.where(y: 0): set text(weight: "bold")

#set page(numbering: "1", footer: context [
  #set text(size: 9pt, fill: luma(90))
  Libro di testo – DevOps Academy #h(1fr) #counter(page).display()
])
