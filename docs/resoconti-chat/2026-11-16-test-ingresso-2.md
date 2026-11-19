# Resoconto – 2026-11-16 – Test d'ingresso settimana 6 (seguito)

## Di cosa abbiamo parlato

1. Ripresa dal resoconto [2026-11-16-organizzazione-piano](2026-11-16-organizzazione-piano.md): test d'ingresso fermo alla domanda 5.
2. Domande 5–10 del test d'ingresso, con molti approfondimenti nati dalle mie domande: spazio liberato e bitmap, recupero dei file cancellati, punti di montaggio, date dell'inode, archivi, sezioni del manuale, `dnf provides`.
3. Nuova regola in `CLAUDE.md` sul contesto delle domande.
4. **Test d'ingresso completato.** Claude ha scritto nel libro i capitoli 04, 07 e 08 e ha ampliato il capitolo 03.

## Test d'ingresso – avanzamento

| # | Argomento | Esito | Note |
|---|---|---|---|
| 5 | Hard link e link simbolici | ✅ | Dopo l'indizio sul link count (seconda colonna di `ls -l`). Precisato: conta i nomi, non i file; a 0 i blocchi sono segnati liberi, non azzerati |
| 6 | Inode | ✅ | Dopo le verifiche: contenuto dell'inode, link count, date (atime, mtime, ctime, btime). Errore corretto: `>>` non legge il file, quindi non aggiorna la atime |
| 7 | Archivi e compressione | ✅ | Errori corretti: compressione ≠ crittografia; tar copia i metadati, non gli inode |
| 8 | Documentazione senza internet | ✅ | `apropos` → `passwd` (dopo l'indizio); `chpasswd` = molti utenti da stdin; shadow contiene hash |
| 9 | Sezioni del manuale | ✅ | Sezioni 1–8, `whatis`, ordine di ricerca in `/etc/man_db.conf` |
| 10 | Pacchetto che fornisce un file | ✅ | Con gli indizi: `dnf provides /usr/share/man/man7/inode.7.gz` → `man-pages`, installato |

## Concetti spiegati

- Il link simbolico contiene solo un percorso, che il kernel risolve a ogni accesso: diventa "pendente" se il file sparisce e segue qualsiasi nuovo file con lo stesso nome.
- Con gli hard link non esiste un "originale": sono nomi equivalenti per lo stesso oggetto.
- Link count: numero di voci di directory che puntano all'inode; a 0 inode e blocchi tornano liberi (salvo file ancora aperti da un processo).
- "Liberare spazio" = segnare come liberi inode e blocchi nel registro del file system (bitmap su ext4, alberi B+ su XFS), senza cancellare i byte. `df` legge quel registro. Inode e blocchi vengono liberati solo quando link count = 0 **e** nessun processo ha il file aperto.
- Il disco è diviso in blocchi numerati (di solito 4 KiB); l'inode elenca i blocchi del file; la bitmap dei blocchi ha un bit per blocco. Cancellare = cambiare pochi bit (veloce); copiare = leggere e scrivere tutti i blocchi (lento). Verifica superata.
- Domanda 6 (in corso): l'inode è una struttura dati (il numero è il suo indice); contiene tipo, permessi, UID/GID (numeri, tradotti da `ls` tramite `/etc/passwd` e `/etc/group`), dimensione, link count, blocchi e date. Il nome sta nel **contenuto** della directory (tabella nome → numero di inode). `rm` usa la chiamata di sistema `unlink`.
- Punto di montaggio: ogni file system è agganciato in una directory dell'unico albero che parte da `/`. Se `/home` è una partizione separata ci sono due punti di montaggio (`/` e `/home`); altrimenti `/home` è una semplice directory del root file system. Smontare / sola lettura / spegnere: misure via via più drastiche. Lo smontaggio fallisce con `target is busy` se dei processi usano il file system.
- Date dell'inode: atime (lettura), mtime (contenuto), ctime (cambio dell'inode: permessi, proprietario, link count, e anche ogni modifica del contenuto), btime (creazione, non modificabile con i comandi normali). La "c" di ctime sta per *change*, non *creation*. Opzione di montaggio `relatime` (predefinita): atime aggiornata solo se più vecchia di mtime/ctime o dopo 24 ore; esistono anche `noatime` e `strictatime`. `O_NOATIME` è un'opzione di `open()`.
- Pacchetti: nome completo (nome-versione-release.architettura), metadati dei repository con l'elenco dei file, cache in `/var/cache/dnf`, `dnf provides` (cerca anche file non installati), `@System` = installato. Pagine di manuale in `/usr/share/man/manN/nome.N.gz`; le sezioni 2/3/5/7 stanno nel pacchetto `man-pages` → [Capitolo 07](../libro/07-gestione-pacchetti.md)
- Archivi: tar (*tape archive*) crea un unico flusso sequenziale (intestazione con nome e metadati, poi contenuto, per ogni file); gzip/bzip2/xz/zstd comprimono un solo flusso, in modo lossless. Compressione (eliminare ripetizioni) ≠ crittografia (rendere illeggibile). Filosofia Unix: strumenti separati e combinabili. Le estensioni sono convenzioni; `file` legge le firme nei primi byte. tar salva una copia dei metadati, ma all'estrazione crea inode nuovi; SELinux e ACL solo se richiesto esplicitamente.
- Documentazione: `apropos` / `man -k` cercano nelle descrizioni brevi usando un indice (database) generato periodicamente. `chpasswd` legge `nome:password` da stdin (molti utenti); `passwd` cambia la password di un utente. I numeri di inode sono locali a ogni file system.
- `/etc/shadow`: hash a senso unico (`$6$sale$hash`, 6 = SHA-512), non cifratura. Al login si calcola l'hash della password digitata e si confronta. Root non può leggere le password, solo reimpostarle.
- Sezioni del manuale: 1 comandi, 2 chiamate di sistema, 3 funzioni di libreria, 4 file speciali (`/dev`), 5 formati dei file, 6 giochi, 7 concetti (`inode`, `regex`, `hier`), 8 amministrazione (la più usata all'EX200), 9 funzioni del kernel. `whatis` / `man -f` mostra in quali sezioni esiste una pagina. `man` senza numero segue l'ordine `SECTION` di `/etc/man_db.conf` (1 n l 8 3 0 2 5 4 9 6 7), scavalcabile indicando la sezione, con `-S`/`--sections` o con la variabile d'ambiente `MANSECT` (sezioni separate da `:`). Prima tentativo con `-M`/`MANPATH`, che invece indicano le directory in cui cercare le pagine.
- Recupero dei file cancellati: il kernel non permette di collegare un nome a un inode "per numero" (`link()` vuole un percorso esistente); ext4 azzera anche l'elenco dei blocchi nell'inode. Gli strumenti leggono il dispositivo grezzo: recupero dai metadati (journal) oppure file carving (firme come `FF D8 FF` per i JPEG, file senza nome). Regola: smettere subito di scrivere. Eccezione: file ancora aperto, leggibile da `/proc/<PID>/fd/`. Soluzione vera: backup e snapshot (LVM).
- Differenza tra "byte ancora presenti sul disco" e "spazio considerato libero dal file system".

Nel libro:
- link, inode, cancellazione, recupero, date → [Capitolo 04](../libro/04-file-system-inode-link.md)
- archivi e compressione, documentazione locale → [Capitolo 03, §6 e §7](../libro/03-shell-strumenti-essenziali.md)
- `dnf provides` → [Capitolo 07](../libro/07-gestione-pacchetti.md)
- `passwd`, `chpasswd`, `/etc/shadow` → [Capitolo 08](../libro/08-utenti-gruppi-password.md)

## Decisioni prese

- **Nuova regola in `CLAUDE.md`:** nelle domande e negli esempi Claude deve dichiarare sempre il contesto e le ipotesi (es. "`/home` è una partizione separata") e non dare mai per scontate né la configurazione del sistema né le mie conoscenze. Nata dalla domanda sullo smontaggio di `/home`, che presupponeva due partizioni senza dirlo.

- Prima chiudiamo il test d'ingresso (domande 6–10), poi facciamo una **lezione dedicata ai file system** (blocchi, inode, bitmap, `mkfs`, ext4 e XFS), utile per la parte EX200 su partizioni e LVM.

## File creati o modificati

| File | Motivo |
|---|---|
| `docs/test/2026-11-16-test-ingresso-settimana-6.md` | Esito della domanda 5 |
| `docs/resoconti-chat/2026-11-16-test-ingresso-2.md` | Questo resoconto |
| `docs/README.md` | Aggiunto questo resoconto all'elenco |
| `CLAUDE.md` | Regola fondamentale: esplicitare sempre il contesto delle domande |
| `docs/libro/04-file-system-inode-link.md` | Nuovo capitolo: inode, directory, link, cancellazione, recupero, date |
| `docs/libro/03-shell-strumenti-essenziali.md` | Aggiunti §6 (archivi e compressione) e §7 (documentazione locale) |
| `docs/libro/07-gestione-pacchetti.md` | Nuovo capitolo (in corso): pacchetti, metadati, `dnf provides` |
| `docs/libro/08-utenti-gruppi-password.md` | Nuovo capitolo (in corso): `passwd`, `chpasswd`, `/etc/shadow`, hash |
| `docs/libro/README.md` | Aggiornato lo stato dei capitoli 03, 04, 07, 08 |

## Cose che devo fare io

- [ ] Leggere il capitolo 04 e fare gli esercizi
- [ ] Leggere i nuovi paragrafi 6 e 7 del capitolo 03 e fare gli esercizi 7–12
- [ ] Dirmi se sulla VM `/home` è una partizione separata (caso A) o no (caso B)
- [ ] Leggere `man 7 hier` dopo aver installato il manuale

- Restano valide le attività del resoconto precedente

## Domande aperte / da riprendere

- **Prossimo passo:** lezione dedicata ai file system (blocchi, inode, bitmap, `mkfs`, ext4 e XFS, punti di montaggio, opzioni di montaggio, smontaggio e `target is busy`) → capitoli 04 e 15.
- Domande rimaste senza risposta: cosa mostra `ls -l` se l'utente proprietario viene cancellato; cosa fa `dnf provides` senza rete e con la cache vuota.
- Uso corretto dei termini: "disco" e non "memoria"; "dimensione" e non "peso"; "hash" e non "cifratura"; un `.gz` è compresso, non è un archivio.
