# Resoconto – 2026-11-19 – Lezione sui file system

## Di cosa abbiamo parlato

1. Ripresa dal resoconto del 18/11 ([2026-11-18-file-system-directory](2026-11-18-file-system-directory.md)): inizio della lezione sui file system.
2. Domanda: `/` e `/boot` stanno su dischi diversi o sullo stesso disco? Risposta: stesso disco, verificata dall'utente di sua iniziativa con `lsblk`.
3. Lettura di `lsblk` e collegamento tra `fd00h` di `stat` e il dispositivo 253:0.
4. Pausa della lezione: **esercizio bonus** assegnato dall'Academy (estrarre i cognomi da un CSV, prima lettera maiuscola, solo due cognomi, tutto in pipe, solo `awk`, `grep` e `sed`). Richiesta: studiare gli strumenti necessari, senza ricevere la soluzione. Iniziato da `awk`.

## Concetti spiegati

- Dispositivi a blocchi, file in `/dev`, numeri major e minor; `fd00h` = 253:0 = `rlm-root` → [Capitolo 14 §1–3](../libro/14-storage-dischi-partizioni-lvm.md)
- `awk`: record e campi, `-F`, `$0`/`$1`/`$NF`, `NR`, pattern `{ azione }`, programma tra apici singoli, primo argomento non-opzione = programma → [Capitolo 03 §8](../libro/03-shell-strumenti-essenziali.md). Esercizi su `/etc/passwd` 1–4 ✅ dopo questi errori: `$1` scambiato per la prima riga; pattern `/bin/bash` (regex `/bin/` + variabile vuota → vero ovunque) e stampa di `$NF` invece di `$1`; `[1-3]` invece di `NR <= 3`; `F:` senza trattino; un apice rimasto aperto (`riga com.:3`).
- `sed`: ciclo riga per riga in un solo passaggio, stampa automatica e `-n`, sintassi `[indirizzo]comando[argomenti]`, indirizzi per numero e per contenuto, `d` interrompe lo script, separatore di `s` (trovato in `info sed`), `-i` → [Capitolo 03 §9](../libro/03-shell-strumenti-essenziali.md). L'utente ha segnalato due volte spiegazioni a metà (sintassi non spiegata; ordine del ciclo non spiegato): **regola n. 1 resa prioritaria in `CLAUDE.md`** con lista di controllo.
- Lettura di `lsblk`: disco `sda` da 20 GB con tre partizioni (`/boot/efi`, `/boot`, LVM), volumi logici `rlm-root` e `rlm-swap`, lettore CD `sr0`.

## Decisioni prese

- `CLAUDE.md`: "Non dare mai niente per scontato" spostata in cima come **regola n. 1**, con lista di controllo (modello di funzionamento, sintassi, contesto, conoscenze, completezza).
- Creato il glossario dell'inglese tecnico delle pagine `man`.

## File creati o modificati

| File | Motivo |
|---|---|
| `docs/resoconti-chat/2026-11-19-lezione-file-system.md` | Questo resoconto |
| `docs/README.md` | Aggiunto questo resoconto |
| `docs/libro/14-storage-dischi-partizioni-lvm.md` | Nuovo capitolo: dispositivi a blocchi, major/minor, `lsblk` |
| `docs/libro/README.md` | Capitolo 14 in corso |
| `docs/glossario/inglese-tecnico-man.md` | Nuovo: glossario dell'inglese delle pagine `man` (difficoltà con i termini tecnici in inglese) |
| `docs/libro/03-shell-strumenti-essenziali.md` | Nuovi §8 `awk` e §9 `sed`, errori comuni, tabella dei comandi |
| `CLAUDE.md` | Regola n. 1 in cima |
| `docs/resoconti/` → `docs/resoconti-chat/` | Cartella dei resoconti delle chat rinominata su richiesta; aggiornati i riferimenti in `CLAUDE.md`, `docs/README.md` e nei resoconti |
| `README.md` (radice, nuovo) | Presentazione del repository per GitHub: struttura, libro, laboratorio, come è prodotto il materiale, flusso Git |
| `docs/resoconti/` (nuova) | Report settimanali dell'utente copiati da `~/Desktop/Academy#8` (`.md` e `.pdf`) |
| `esercizi/extras/` | Copiata da `~/Desktop/Academy#8/extras` su richiesta (esercizi extra e corretti, immagini, script), senza i file `.DS_Store` |
| `esercizi/rubrica.csv`, `esercizi/esercizio_bonus_Paolo.md` | Copiati dalla VM (`~/condivisa/esercizi`, via `scp`) su richiesta: soluzione dell'esercizio bonus scritta dall'utente |

## Cose che devo fare io

- [ ] Esercizi 7–12 del capitolo 03
- [ ] Leggere `man 7 hier`

## Domande aperte / da riprendere

- Esercizio bonus: interpretazione scelta dall'utente: (a) **trasformare** la prima lettera in maiuscola; due cognomi **scelti da lui** (per nome); file **senza** intestazione. Da fare: creare un CSV di prova sulla VM; studio di `awk`, poi `sed`, poi `grep` e regex, poi composizione.
- Esercizio bonus, **prima versione dell'utente** (funzionante sui suoi dati): `grep -E 'paoli|nasso' rubrica.csv | awk -F, '{ print $2 }' | sed 's/^./\U&/'`. Trovato da solo `\U` (estensione GNU). Secondo tentativo bloccato da apici tipografici (‘ ’) → prompt `>`, uscito correttamente con Ctrl+C. Da rivedere: `grep` su tutta la riga prima di `awk` (trova il nome anche in nome/indirizzo o dentro parole più lunghe), maiuscole/minuscole nella selezione, spiegazione di `^.` e `\U&`.
- Esercizio bonus, **versione finale dell'utente**: `awk -F, '{ print $2 }' rubrica.csv | grep -Eix 'paoli|de mattia' | sed 's/./\U&/'`. Passaggi: file letto dal primo comando (prima era su `grep` e `awk` restava in attesa della tastiera), `grep` spostato dopo `awk`, `-i`, poi `-w` (parola intera: accetterebbe `de paoli`) e infine `-x` (riga intera). Errore sul `sed`: `^*` (in BRE `*` dopo `^` è un asterisco letterale). In attesa: output finale e risposte su `\U`/`\u`/`&` e sul perché `^` non serve.
- ✅ Esercizio bonus completato e documentato dall'utente (`-x` aggiunto, "oppure" corretto: aveva scambiato `|` per `&&`; spiegati i tre significati di `|`). Ancora aperte, facoltative: righe di prova per mostrare `-x`, ipotesi di interpretazione, spiegazione di `\U`/`&` e perché `s/^/\U&/` non cambia niente.
- ✅ Repository Git creato dall'utente con i comandi dati da Claude su richiesta esplicita ("dimmi proprio i comandi, ho poco tempo"): identità globale, `init.defaultBranch main`, `git init`, `.gitignore` (`.DS_Store`, `.claude/settings.local.json`), primo commit `04861a2`. Spiegato il modello: repository, `.git/`, working tree, staging area, commit. Collegato a GitHub: chiave SSH `id_ed25519` registrata, remoto `origin` = `git@github.com:dnass0/formazione_sou.git` (il repo su GitHub era vuoto, nessun merge necessario), `git push -u origin main`, secondo commit `e632fe6` di prova. Ciclo quotidiano: `git status`, `git add .`, `git commit -m "..."`, `git push`.
- Da riprendere: lettura guidata di `index(s, t)` in `man awk` (tre domande: argomenti, cosa restituisce, indici che partono da 1) e altre due funzioni di *String Functions* lette da solo con il glossario.
- Lezione sui file system sospesa alla domanda su `fd00h` → 253:0 e sulla definizione di partizione.

- In attesa: definizione di **partizione** con parole sue.
- Percorso della lezione: partizioni (tabella delle partizioni, GPT); LVM; swap; `mkfs` (ext4 e XFS); mount e opzioni; `/etc/fstab` e UUID; `umount` e *target is busy*; `xfs_info`, gruppi di allocazione, `xfs_db` (richiesta esplicita: voci di `link/` byte per byte, shortform e formato a blocchi, confronto con ext4).
