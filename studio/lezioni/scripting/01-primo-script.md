---
tags:
  - lezione
  - scripting
aliases:
  - Scripting 01 — Il primo script
---
# Scripting 01 — Il primo script

Prima di programmare serve capire cosa la shell fa di ciò che scrivi: dove finisce un argomento, quando una variabile si spezza, cosa significa «eseguibile».

```sh
./prepara.sh 01 && cd palestra/l01
```

## La mappa

| #   | Problema                                     | Stato |
| --- | -------------------------------------------- | ----- |
| 0   | Previsioni — carta e penna, poi la prova     | — |
| 1   | `scheda.sh` — inquadrare una macchina        | — |
| 2   | `argomenti.sh` — cosa riceve uno script      | — |
| 3   | `salva-conf.sh` — copia prima di toccare     | — |
| 4   | `conta-righe.sh` — riparare uno script rotto | — |

---

## Problema 0 — Previsioni

**Situazione.** Prima di scrivere script conviene sapere cosa fa la shell con una riga sola. Ogni previsione sbagliata è una regola che ancora non conosci.

> [!info] Il contesto
> **Lo scenario.** Chi amministra macchine Linux lavora soprattutto scrivendo comandi in un terminale, e presto mette i comandi che ripete in un file.
> - **Shell** (inglese, «guscio»): il programma che legge ciò che scrivi e lancia i comandi. Avvolge il nucleo del sistema come un guscio.
> - **Script** (latino *scriptum*, «scritto», poi il copione degli attori): un file di testo con una lista di comandi, che la shell esegue in ordine.
>
> **Perché conta.** Uno script fa esattamente ciò che la shell capisce, non ciò che intendevi. Se non sai come legge una riga, non sai cosa farà il tuo script.

**Compito.** Per ogni riga scrivi **prima** cosa stampa e perché, poi lanciala.

```sh
echo ciao      mondo
echo "ciao      mondo"
echo 'ciao $HOME' "ciao $HOME"
nome=mario; echo "ciao $nome"; echo "ciao $nomeX"; echo "ciao ${nome}X"
nome = mario
x=5 echo "[$x]"
x=5; echo "[$x]"
ls /nessuno; echo $?
true; echo $?; false; echo $?
echo $0 $$ $#
type echo cd ls
cat /etc/hostname | wc -c
echo uno; echo due > /dev/null; echo tre
echo "$(date +%Y)" e `date +%Y`
```

**Verifica.** Si controlla a mano, con Claude: spiega ogni errore di previsione.

**Dopo.** Perché `nome = mario` dà errore e `nome=mario` no? Cosa vuol dire che in shell una variabile è sempre una stringa? Che differenza c'è fra un comando interno e un programma su disco, secondo `type`?

---

## Problema 1 — `scheda.sh`

**Situazione.** Ti danno l'accesso a un server che non hai mai visto. Prima di toccare qualsiasi cosa vuoi sapere dove sei, e lo vuoi sapere con un solo comando su ogni macchina.

> [!info] Il contesto
> **Lo scenario.** Un nuovo incarico, o un cliente nuovo: ricevi l'accesso a un **server** (il computer che offre servizi ad altri) e non sai niente di lui. Prima di toccarlo fai una ricognizione, la stessa su ogni macchina.
> - **Kernel** (inglese, «nocciolo»): il nucleo del sistema operativo, che gestisce hardware e processi. La sua versione dice quali funzioni ha.
> - **CPU** (*Central Processing Unit*) e **core** («nucleo»): il processore e le unità di calcolo indipendenti che contiene.
> - **RAM** (*Random Access Memory*): la memoria di lavoro. **MiB** (*mebibyte*, «mega binario»): 1024 × 1024 byte.
> - **`/`**: la radice (*root*) dell'albero dei file, da cui partono tutte le cartelle.
>
> **Perché conta.** Un disco quasi pieno o una macchina con poca memoria cambiano cosa puoi fare senza rischi. Raccogliere i dati a mano, macchina per macchina, porta a confonderli.

**Compito.** Lo script stampa esattamente queste sei righe, senza argomenti:

```text
host: <nome della macchina>
kernel: <versione del kernel>
utente: <chi sta eseguendo lo script>
core: <numero di CPU>
ram_mib: <RAM totale in MiB, solo il numero>
disco_root_libero: <spazio libero su />, come 12G
```

**Verifica.** `../../verifica.sh 01 1`

> [!question]- Indizio 1
> Riesci a farlo prima a mano, un dato alla volta? Quale comando ti ha già risposto a domande simili negli appunti di [[orientarsi-documentarsi|Orientarsi e documentarsi]]?

> [!question]- Indizio 2
> Ti manca il nome di un comando. Come chiedi al sistema «quale comando parla di memoria»? Cosa cerca `apropos`, e dove?

> [!question]- Indizio 3
> Un comando stampa una tabella e a te serve una casella. Come isoli prima la riga e poi la colonna? E come fai finire l'output di un comando in mezzo a una frase?

**Dopo.** Perché il file parte con `#!`, e chi legge quella riga: la shell o il kernel? Cosa cambia fra `bash scheda.sh` e `./scheda.sh`? Perché `./` è necessario?

---

## Problema 2 — `argomenti.sh`

**Situazione.** Ogni comando Linux riceve una lista di argomenti. Prima di scrivere script che ne accettano, vuoi vedere con i tuoi occhi cosa arriva.

> [!info] Il contesto
> **Lo scenario.** Quasi tutti gli script ricevono qualcosa da chi li lancia: un nome di file, un utente, un numero. Il collega che lo usa scrive la riga, lo script deve capire cosa gli è arrivato.
> - **Comando** (latino *mandare*, «affidare un incarico»): la prima parola della riga, il programma a cui affidi il lavoro.
> - **Argomento** (latino *argumentum*, «ciò che chiarisce»; in matematica il valore dato a una funzione): ciascuna parola che segue il nome del comando sulla riga.
>
> **Perché conta.** Se uno script vede due argomenti dove l'utente ne ha scritto uno, per esempio un nome di file con uno spazio, lavora sul file sbagliato o su un file che non esiste.

**Compito.** `./argomenti.sh uno "due tre" quattro cinque` deve stampare:

```text
script: argomenti.sh
quanti: 4
1: uno
2: due tre
3: quattro
```

Il nome va stampato senza percorso, anche se lanci lo script con `../l01/argomenti.sh`.

**Verifica.** `../../verifica.sh 01 2`

> [!question]- Indizio 1
> Prova `echo` con un argomento fra virgolette e uno senza. Chi toglie le virgolette: la shell o `echo`? Cosa riceve quindi lo script?

> [!question]- Indizio 2
> Lancia lo script da un'altra cartella e guarda cosa contiene la variabile col suo nome. Il percorso è un testo: quale comando visto nel manuale Bash ne tiene solo l'ultimo pezzo?

**Dopo.** Scrivi una prova in cui `"$*"` e `"$@"` danno risultati diversi. Il manuale dice che la differenza si vede cambiando `IFS`: è l'unico modo? Cosa fanno le virgolette?

---

## Problema 3 — `salva-conf.sh`

**Situazione.** Regola di ogni sistemista: prima di modificare una configurazione se ne salva una copia datata. Il manuale parte da uno script simile, ma con i nomi di file scritti dentro: il tuo deve funzionare con qualsiasi file.

> [!info] Il contesto
> **Lo scenario.** Devi cambiare il comportamento di un servizio, per esempio la porta di un server web. Il servizio legge le sue regole da un file di testo, quasi sempre sotto `/etc`.
> - **Configurazione** (latino *configurare*, «dare forma insieme»): il file che decide come si comporta un programma.
> - **`/etc`** (da *et cetera*, «e il resto»): nei primi Unix era la cartella delle cose varie, oggi raccoglie le configurazioni del sistema.
> - **Copia datata**: una copia con la data nel nome, così sai a quale momento risale.
>
> **Perché conta.** Se la modifica rompe il servizio, la copia ti fa tornare indietro in un minuto. Senza, devi ricostruire il file a memoria mentre il servizio è fermo.

**Compito.** `./salva-conf.sh FILE CARTELLA` copia `FILE` in `CARTELLA/<nome del file>.AAAAMMGG`, con la data di oggi.

- La cartella si crea se manca, anche con più livelli.
- Nomi con spazi devono funzionare.
- Se il file non esiste, lo script esce con un codice diverso da 0. Ti basta ciò che già fanno i comandi: `if` arriva nella prossima lezione.

**Verifica.** `../../verifica.sh 01 3`

> [!question]- Indizio 1
> Prova: `./salva-conf.sh "dati/conf di prova.ini" "dati/le copie"`. Quanti argomenti riceve ogni comando dentro lo script? Come lo controlli?

> [!question]- Indizio 2
> Con quale codice esce uno script che non chiama `exit`? Cosa succederebbe se dopo la copia aggiungessi un `echo "fatto"`?

> [!question]- Indizio 3
> Quali opzioni di `date` conosci per scegliere il formato? Cosa dice `man date` sui segnaposto?

**Dopo.** Lancia lo script due volte lo stesso giorno. Cosa succede alla prima copia? È accettabile, per una copia di sicurezza?

---

## Problema 4 — `conta-righe.sh`

**Situazione.** Un collega ti lascia uno script che «funzionava». Lo trovi già in `palestra/l01/conta-righe.sh`. Deve stampare:

```text
dati/nome con spazi.log: 12 righe
```

> [!info] Il contesto
> **Lo scenario.** Chi lavora in un gruppo eredita script scritti da altri: un collega cambia ufficio, lascia una cartella di strumenti e la frase «funzionava». Tocca a te farli ripartire.
> - **Log** (dal *logbook*, il giornale di bordo delle navi): un file in cui un programma annota gli eventi, una riga per evento.
> - **Riparare**, in gergo **fare debug** (*de-bug*, «togliere gli insetti»): trovare e correggere gli errori. Il termine *bug* era in uso già nell'Ottocento; resta famosa la falena trovata nel 1947 dentro il calcolatore Harvard Mark II.
>
> **Perché conta.** Correggere a caso cambia più cose di quelle rotte. Capire ogni errore prima di toccarlo evita di aggiungerne di nuovi.

**Compito.** Ripara lo script. Prima di correggere un errore, prevedi a voce cosa succederà e controlla con `bash -x`, poi passa al successivo. Gli errori sono più d'uno, e uno non è dentro il testo.

**Verifica.** `../../verifica.sh 01 4`

> [!question]- Indizio 1
> Leggi il primo messaggio d'errore parola per parola: cosa ha creduto di dover eseguire la shell?

> [!question]- Indizio 2
> Se assegni a una variabile il nome di un comando, la shell esegue il comando? Cosa stai mettendo in `righe`?

> [!question]- Indizio 3
> Il messaggio finale stampa letteralmente i nomi delle variabili. Quali caratteri decidono se `$` viene interpretato?

**Dopo.** Cosa fa esattamente `bash -x`? E `shellcheck conta-righe.sh`, sullo script ancora rotto? Quanti di questi errori avrebbe trovato al posto tuo?

---

## Diario

Domande numerate, risposte e correzioni di questa lezione.

## Sintesi

Da scrivere a lezione finita, con le tue parole.

---

↑ [[00-percorso|Il percorso]] · → [[13-espansioni|Lezione 13]]
