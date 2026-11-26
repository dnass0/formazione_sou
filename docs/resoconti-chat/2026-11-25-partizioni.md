# Resoconto – 2026-11-25 – Lezione sui file system: dal campo `Device:` alle partizioni

## Di cosa abbiamo parlato

1. Ripresa dal resoconto del 19/11: lezione sui file system ferma alla definizione di partizione.
2. Su richiesta, ripasso di come si collega `Device: fd00h/64768d` di `stat` al dispositivo 253:0 (`rlm-root`) in `lsblk`, con la conversione esadecimale spiegata per intero.
3. Domande di verifica su `/boot` (`sda2`, 8:2) e sui numeri major diversi di `sda2` e `rlm-root`.
4. Ragionamento socratico sulle partizioni: traduzione dei blocchi (inizio) e protezione dei confini (dimensione).
5. Domanda su dove sono scritte le partizioni perché sopravvivano al riavvio.

## Concetti spiegati

- Conversione di `Device:`: esadecimale (cifre alte = major, basse = minor) e decimale (major × 256 + minor) → [Capitolo 14 §2](../libro/14-storage-dischi-partizioni-lvm.md)
- Tabella delle partizioni all'inizio del disco, settore, MBR → [Capitolo 14 §5](../libro/14-storage-dischi-partizioni-lvm.md)
- Partizione = intervallo contiguo di blocchi; inizio (offset) per tradurre, dimensione per proteggere; device mapper per i volumi logici → [Capitolo 14 §4](../libro/14-storage-dischi-partizioni-lvm.md)

Esito delle risposte:
- 8:2 per `/boot` ✅; forma di `stat`: `802h` ✅, decimale scritto come `802×256` ❌ (va moltiplicato solo il major e calcolato: 2050).
- Major diversi: driver dei dischi (`sd`) vs device mapper ✅; la traduzione dei blocchi di `rlm-root` la fa il kernel (device mapper) ✅.
- Blocco 100 di `sda2` = 1100 ✅; serve l'inizio ✅; la dimensione inizialmente ritenuta inutile, poi capito che serve a sapere dove finisce → spiegato il controllo dei confini.
- Definizione: "range di blocchi di un disco" ✅ (da precisare: contiguo, con inizio e dimensione).
- Dove sono scritte le partizioni: risposta "file system, fstab e un'altra tabella" → spiegato perché file system e `fstab` sono circolari; "tabella delle partizioni" ✅.
- Posizione della tabella: "primi 512 byte, MBR" ✅. Domanda su `sda1` dal settore 0 inizialmente non capita (formulata male da Claude), riformulata a passi: settore 0 di `sda1` = settore 0 di `sda` ✅, lì c'è l'MBR ✅, `mkfs` lo sovrascriverebbe ✅, minimo inizio settore 1 ✅.
- Verifica in `/sys`: previsione "più di 1" ✅; `size` × 512 = 629145600 ✅ (spiegato MiB); partizioni contigue ✅; inizio a 2048 trovato, motivo da scoprire.
- Allineamento: ipotesi iniziali frammentazione e inode ❌ (spiegato perché); 2048 × 512 = 1 MiB ✅; partizione dal settore 1 → due pezzi fisici, più lento ✅ (aggiunto read-modify-write); 2048 divisibile per 8 → allineata ✅ → [Capitolo 14 §7](../libro/14-storage-dischi-partizioni-lvm.md)
- Domanda dell'utente: `/sys` viene montato prima di `/`, ed è da lì che arrivano le partizioni? Spiegato che `/sys` è una finestra sulla memoria del kernel, non la fonte → [Capitolo 14 §6](../libro/14-storage-dischi-partizioni-lvm.md)

## Decisioni prese

- Il libro ha anche una **versione PDF** (`docs/libro/pdf/`), solo scale di grigi e grassetto. Claude la rigenera e la aggiorna **quando l'utente lo chiede**.

## File creati o modificati

| File | Motivo |
|---|---|
| `docs/resoconti-chat/2026-11-25-partizioni.md` | Questo resoconto |
| `docs/README.md` | Aggiunto questo resoconto |
| `docs/libro/pdf/genera-pdf.sh`, `stile.typ`, `link-come-testo.lua` | Script e stile per generare il PDF del libro (pandoc + typst) |
| `docs/libro/pdf/libro-devops-academy.pdf` | Il libro in PDF (capitoli 03, 04, 07, 08, 14) |
| `docs/libro/README.md` | Link al PDF e istruzioni per rigenerarlo |
| `docs/libro/14-storage-dischi-partizioni-lvm.md` | Ripasso esadecimale in §2, nuovo §4 partizioni, errore comune, domande 4–5 |

## Cose che devo fare io

- [ ] Esercizi 7–12 del capitolo 03
- [ ] Leggere `man 7 hier`
- [ ] Committare il report 6 (`docs/resoconti/11-23-26-REPORT_6.md`), ancora non tracciato

## Domande aperte / da riprendere

- `/proc`: l'utente ha detto "i dati vengono dalla RAM, come `/sys`" (🟨: generati dal kernel alla lettura) e ha chiesto la soluzione per `/etc` → spiegazione di livello 3, esercizi 3–4 del capitolo 14 assegnati.
- Domanda dell'utente: "in che senso unità logica del disco?" → spiegati controller, firmware, LBA, settori logici e fisici, 512e (cap. 14 §7). Non è un argomento d'esame EX200.
- Domanda dell'utente: le partizioni logiche esistono per via dei settori logici? → no, "logico" ha più significati (settore logico, partizione logica, volume logico); avviata la scoperta guidata del limite delle 4 voci MBR → partizione estesa e logiche.
- Domanda dell'utente: perché esiste il volume logico, perché non bastano le partizioni? → spiegazione rapida: limiti delle partizioni (contigue, su un solo disco, difficili da ingrandire), modello LVM (PV → VG → LV, extent). Lezione completa su LVM rimandata al suo turno nel percorso.
- Sequenza per ingrandire `/` con un nuovo disco: risposte dell'utente "ingrandire il VG, poi faccio un LV" → "creo la partizione, poi VG, poi ingrandire rlm-root" → `df` non vede subito i 26 GB ✅ ma "devo aggiornare fstab" ❌ → `apropos xfs` ✅, "estendo il VG" ✅, PV chiamato "partizione logica/fisica" (manca l'inizializzazione per LVM). Su richiesta, spiegazione di livello 3 con i comandi → [Capitolo 14 §8](../libro/14-storage-dischi-partizioni-lvm.md). Esercizio di verifica: cap. 14 esercizio 5.
- Esercizio 5 del cap. 14: domanda 1 ✅ (solo passi 3 e 4, anche solo `lvextend -r`). Domanda 2: l'utente ha chiesto aiuto su come cercare con `apropos` ("faccio sempre difficoltà") → indizi di livello 2 e strategia di ricerca → [Capitolo 03 §7.4](../libro/03-shell-strumenti-essenziali.md). Domanda 3 (`-L` e `+`) rimandata.
- In attesa: limite dei 2 TiB dell'MBR (2^32 × 512) come ingresso a GPT.
- Prossimo: GPT (struttura, MBR protettivo, copia di riserva alla fine del disco), poi `fdisk`/`gdisk`/`parted`.
- Ancora valide dal 19/11: lettura guidata di `index(s, t)` in `man awk`; approfondimenti facoltativi dell'esercizio bonus.
