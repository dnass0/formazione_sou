# Resoconto – 2026-11-18 – Capitolo 04: date, hard link tra file system, com'è fatta una directory

## Di cosa abbiamo parlato

1. Ripresa della chat di ieri ([2026-11-17-esercizi-cap04](2026-11-17-esercizi-cap04.md)): esercizio 5 del capitolo 04.
2. Esercizio 5 (date e `relatime`) ed esercizio 6 (hard link verso un altro file system): capitolo 04 completato.
3. Domanda rimasta aperta: come cambiano mtime e ctime di una directory quando si crea o cancella un file.
4. Approfondimento nato dall'output di `stat`: dove stanno davvero i nomi di una directory, com'è fatta una voce, directory *shortform* di XFS, link count delle directory.
5. Inizio della lezione sui file system: presentato il percorso e fatta la prima domanda (dischi e partizioni).

## Esercizi svolti

| # | Esercizio | Esito | Note |
|---|---|---|---|
| 04-5 | Date e `relatime` | ✅ | Errore corretto: pensava che `relatime` guardasse solo la mtime (o il contenuto); confronta le **date**, anche con la ctime. Notato da solo che al primo `cat` la atime non è cambiata perché non erano passate 24 ore (contesto sbagliato fornito da Claude). Verificato: `chmod` → solo ctime; `cat` successivo → atime; `>>` → mtime e ctime, dimensione 23 → 28 |
| 04-6 | Hard link verso un altro file system | ✅ | Con `stat` (campo `Device:`) ha distinto home, `/boot` e `/proc`. Previsione parziale: pensava che il link venisse creato ma non fosse leggibile, invece il kernel lo rifiuta (`EXDEV`, "Collegamento tra dispositivi non valido"). Spiegato bene il perché (numero di inode cercato nella tabella sbagliata, link count incoerente). Link simbolico funzionante |
| — | Date di una directory | ✅ | Errori corretti: pensava che i nomi stessero nei metadati della directory e che `rm` non cambiasse la mtime. Verificato con `touch link/1` e `rm link/1`: dimensione di `link/` 26 → 35 → 26, mtime e ctime aggiornate entrambe le volte |
| — | `Blocchi:` di link simbolico e home | ✅ | `sl_rel.txt` 19 byte, `Blocchi: 0` (previsto, ma pensava che il percorso stesse nell'inode della cartella: sta nell'inode del link); home `Dim.: 4096`, `Blocchi: 8` |
| — | Link count della home (`Coll.: 7`) | ✅ | Spiegato a livello 3 su richiesta. Verificato con `ls -ia` e `ls -l` che `hl` non è una directory: 2 + 5 sottodirectory = 7 |

## Concetti spiegati

- `relatime` confronta **solo le date**: la atime si aggiorna se è più vecchia (o uguale) della mtime **o della ctime**, oppure se ha più di 24 ore → [Capitolo 04 §7.1](../libro/04-file-system-inode-link.md)
- Nell'output italiano di `stat` "Accesso" compare due volte: la prima riga sono i **permessi** (*Access*), la seconda la atime.
- Una voce di directory contiene il **numero** di inode, mai l'inode; non esistono hard link tra file system diversi (`EXDEV`); il campo `Device:` di `stat` dice su quale file system sta un file → [Capitolo 04 §5.1](../libro/04-file-system-inode-link.md)
- `/proc` è virtuale, `/boot` e `/` sono file system reali su disco; sulla VM `/home` **non** è separata da `/`.
- I nomi stanno nel **contenuto** della directory; una voce è una sequenza di byte (numero di inode, lunghezze, tipo, nome) → [Capitolo 04 §4.1](../libro/04-file-system-inode-link.md)
- `cat` su una directory dà `EISDIR`; `ls` legge le voci con `getdents`/`readdir`; `ls -iaU` mostra inode, `.` e `..` senza ordinamento.
- XFS: l'inode è una casella fissa da 512 byte **sul disco**; lo spazio avanzato contiene elenco dei blocchi, attributi estesi (etichetta SELinux) e, solo per **directory e link simbolici** piccoli, il contenuto stesso (*shortform*: `Blocchi: 0`). I file regolari hanno sempre almeno un blocco perché passano dalla page cache → [Capitolo 04 §4.2](../libro/04-file-system-inode-link.md)
- `Blocchi:` di `stat` conta unità da 512 byte: un blocco da 4 KiB vale 8, quindi va di 8 in 8.
- Link count di una directory = 2 + numero di sottodirectory, nascoste comprese.

## Decisioni prese

- Nuova regola in `CLAUDE.md`: quando Claude chiede di eseguire dei passi, li riscrive sempre per intero nello stesso messaggio.
- Si passa alla lezione sui file system; gli esercizi 7–12 del capitolo 03 restano in sospeso.

## File creati o modificati

| File | Motivo |
|---|---|
| `docs/resoconti-chat/2026-11-18-file-system-directory.md` | Questo resoconto (separato da quello del 17/11 su richiesta) |
| `docs/resoconti-chat/2026-11-17-esercizi-cap04.md` | Tolte le parti del 18/11 |
| `docs/README.md` | Aggiunto questo resoconto all'elenco |
| `docs/libro/04-file-system-inode-link.md` | §4.1 voce di directory, `.` e `..`, link count; §4.2 directory shortform di XFS; §5.1 e §5.3 niente hard link tra file system; §7.1 `relatime` confronta anche la ctime; errori comuni |
| `CLAUDE.md` | Regola: riscrivere sempre i passi da eseguire |

## Cose che devo fare io

- [x] Esercizi 5–6 del capitolo 04
- [x] Scoprire se `/home` è separata: **no**, stesso `Device:` di `/etc`; `/boot` è separato
- [ ] Esercizi 7–12 del capitolo 03
- [ ] Rispondere alle prime domande della lezione sui file system (dischi e partizioni)

## Domande aperte / da riprendere

- **Richiesta esplicita: nella lezione sui file system approfondire bene** come leggere i byte grezzi di una directory: nome del dispositivo su cui sta il file system (da `fd00h` a `/dev/...`), `xfs_db` in sola lettura, inode di `link/` letto campo per campo, formato shortform e formato a blocchi (con i blocchi di indice delle directory grandi), confronto con ext4.
- Lezione sui file system, percorso: dispositivi a blocchi e partizioni; LVM; `mkfs` (ext4 e XFS); mount e opzioni; `/etc/fstab` e UUID; `umount` e *target is busy*; `xfs_info`, gruppi di allocazione, `xfs_db`.
