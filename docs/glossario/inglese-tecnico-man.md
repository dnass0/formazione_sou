# Glossario – Inglese tecnico delle pagine di manuale

All'esame EX200 la documentazione è in inglese. Questo glossario raccoglie le parole che ricorrono nelle pagine `man`, con il significato **nel contesto** dei comandi. Cresce man mano che le incontriamo.

## Come leggere una pagina `man` senza tradurre tutto

1. **SYNOPSIS** prima di tutto: dice come si scrive il comando. `[ ]` = facoltativo, `...` = si può ripetere, `|` = in alternativa.
2. **EXAMPLES** (se c'è, in fondo): spesso basta un esempio per capire.
3. Cerca con `/parola` solo la parte che ti serve; `n` passa al risultato successivo.
4. Nella descrizione di un'opzione o funzione, cerca il **verbo** (*return*, *print*, *remove*…): è lì che sta cosa fa.
5. Prova: un comando su un file di prova chiarisce più di tre letture.
6. Aiuti in italiano: molti comandi hanno `--help` e i messaggi tradotti (la VM è in italiano). La pagina `man` resta però la fonte completa.

## Struttura delle pagine

| Inglese | Significato |
|---|---|
| NAME | nome e descrizione in una riga |
| SYNOPSIS | sintassi del comando |
| DESCRIPTION | descrizione |
| OPTIONS | opzioni |
| EXAMPLES | esempi |
| EXIT STATUS | codice di uscita (0 = successo) |
| FILES | file usati dal comando |
| SEE ALSO | pagine collegate |

## Parole frequenti

| Inglese | Significato nel contesto |
|---|---|
| argument | argomento, il valore passato a un comando o a una funzione |
| case-sensitive / ignore case | distingue / non distingue maiuscole e minuscole |
| default | valore predefinito, usato se non specifichi niente |
| field | campo (una colonna di una riga) |
| field separator | separatore dei campi |
| index | posizione (in `awk` i caratteri si contano da 1) |
| input / output | dati in ingresso / in uscita |
| line / record | riga |
| lowercase / uppercase | minuscolo / maiuscolo |
| match | corrispondere a un pattern; "una corrispondenza" |
| omitted / if not supplied | se non lo indichi |
| optional | facoltativo (in SYNOPSIS è tra `[ ]`) |
| pattern | modello da cercare (spesso un'espressione regolare) |
| regular expression (regexp) | espressione regolare |
| replace / substitute | sostituire |
| return | restituire (il risultato di una funzione) |
| string | stringa, sequenza di caratteri |
| substring | sottostringa, un pezzo di una stringa |
| standard input / output | stdin / stdout (capitolo 03) |
| suppress | sopprimere, non mostrare |
| translate / convert | trasformare (es. da minuscolo a maiuscolo) |
| whitespace | spazi e tabulazioni |

## Cronologia

- 2026-11-19: creato durante lo studio di `man awk` (sezione *String Functions*), perché i termini tecnici in inglese rendevano difficile la lettura.
