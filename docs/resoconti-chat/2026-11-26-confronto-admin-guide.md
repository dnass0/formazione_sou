# Resoconto – 2026-11-26 – Confronto con la Rocky Linux Admin Guide (cap. 8)

## Di cosa abbiamo parlato

1. Ripresa dal resoconto del 25/11: esercizio 5 del capitolo 14 ancora aperto (domande 2 e 3), poi limite dei 2 TiB dell'MBR e GPT.
2. L'utente ha fornito i PDF dell'Academy come fonti di verifica: *Rocky Linux Admin Guide* (it) e *Learning Bash with Rocky* (it). *Pro Git* lo passerà l'utente in una sua traduzione.
3. Confronto tra il capitolo 8 "File System" della Admin Guide e i nostri capitoli 04 e 14.
4. Ripresa dell'esercizio 5 del cap. 14 (domanda 2, ricerca con `apropos`), interrotta da una domanda di ripasso sugli inode.

## Concetti spiegati

- Ripasso su richiesta: dove stanno gli inode. Sul disco, dentro la partizione; superblocco in posizione fissa; ext4 con tabelle fisse per gruppo di blocchi (esaurimento degli inode, `df -i`); XFS con inode creati a gruppi di 64. Correzione del ricordo "le directory a volte vengono salvate negli inode": ogni directory *ha* un inode; in XFS è il suo *elenco di nomi* che, se piccolo, sta dentro il suo inode → [Capitolo 04 §3.1](../libro/04-file-system-inode-link.md)
- "A gruppi di 64" spiegato con lo schedario: ext4 stampa tutte le schede a `mkfs`, XFS prepara pacchi da 64 inode (32 KiB) quando servono. Risposte: 1 file → 64 esistenti, 1 occupata ✅; domanda dell'utente su 25 file → sempre un solo pacco (25 occupate, 39 libere), il secondo pacco arriva al 65° file. Domanda su 65 file "in un colpo solo": il kernel crea un file per system call (`openat`), quindi 128 esistenti, 65 occupate.
- Domanda 1 (superblocco in posizione fissa) 🟨: intuito il problema circolare, ma collocato "prima del disco" e "all'avvio" → chiarito: sta dentro la partizione, a una distanza fissa dal suo inizio, la conosce il codice del driver, serve a ogni montaggio.

### Cosa copre il capitolo 8 della guida e dove siamo noi

| Argomento della guida | Da noi |
|---|---|
| 8.1 Partizionamento, MBR, primarie/estese/logiche, limite 2 TB | Cap. 14 §4–5 ✅; primarie/estese/logiche e 2 TiB avviati a voce, da scrivere |
| 8.1.1 Nomi dei dispositivi (`sd`, `vd`, `sr0`…) | Solo `sda` → **manca** (e la guida non cita NVMe) |
| 8.1.2 Numero di partizione (5 = prima logica) | **Manca** |
| 8.1.3–8.1.4 `fdisk`, `parted`, `cfdisk` | **Manca** (previsto dopo GPT) |
| 8.2 LVM: PV, VG, LV, PE/LE, comandi, lineare/stripe/mirror | Cap. 14 §8 (anteprima) 🟨; mancano PE/LE nel dettaglio, `pvs/vgs/lvs`, tipi di LV |
| 8.3 `mkfs`, boot sector, superblocco, tabella degli inode, data block | Inode e blocchi nel cap. 04 ✅; **superblocco e `mkfs` mancano** |
| 8.3.6 `fsck`, `/lost+found` | **Manca** |
| 8.4 FHS | Cap. 04 + `man 7 hier` (da leggere) 🟨 |
| 8.4.1 `/etc/fstab` (6 colonne), UUID | **Manca** (cap. 15) |
| 8.4.2 `mount`, `umount`, opzioni | **Manca** (cap. 15) |
| 8.5 Nomi dei file, tipi di file | Cap. 04 in parte ✅ |
| 8.6–8.7 Permessi, umask | Cap. 05 (da scrivere) |

Argomenti d'esame che la guida **non** tratta e che faremo comunque: GPT, swap (`mkswap`, `swapon`), `blkid`, `partprobe`, `lsblk -f`, XFS (`xfs_growfs`, `xfs_repair`), opzioni di mount e `nofail`, unit `.mount` di systemd.

### Affermazioni della guida da correggere

- **`fdisk` "usa solo MBR e non supporta GPT":** è falso da anni. Il `fdisk` di util-linux gestisce GPT (su Rocky 8/9 sì).
- **"`gparted -l`":** si intende `parted -l`. `gparted` è l'interfaccia grafica.
- **`cfdisk` "più affidabile, il migliore da usare":** è un'opinione. All'esame si usano `fdisk`, `gdisk` o `parted`. Da verificare sulla VM se `cfdisk` è installato.
- **Boot sector "cilindro 0, traccia 0, settore 1":** è la numerazione CHS, dove i settori partono da 1. In LBA, la numerazione che usiamo noi, quello stesso settore è lo **0**. Non c'è contraddizione con il cap. 14 §5.
- **"MBR: 446 byte":** MBR è il nome dell'intero settore da 512 byte. I 446 byte sono il codice di avvio, i 64 la tabella (4 voci × 16 byte), i 2 la firma `55 AA`.
- **"Il sistema inizializza Boot Sector e Super block, poi l'amministratore la tabella degli inode":** è tutto lavoro di `mkfs`. Il boot sector, poi, non appartiene al file system.
- **"La dimensione della tabella degli inode determina il numero massimo di file":** vale per ext4, dove gli inode sono fissati alla creazione. Non vale per XFS, il file system predefinito su Rocky, che li alloca dinamicamente.
- **"Ultima modifica dell'inode (= creazione)":** è sbagliato. Si tratta della ctime, cioè la data dell'ultimo cambiamento dei metadati (cap. 04 §7).
- **Superblocco salvato solo con `sync` e allo spegnimento:** è una semplificazione. ext4 e XFS usano un **journal** (il registro delle modifiche) proprio per non perdere coerenza negli arresti improvvisi.
- **`touch /forcefsck` e `shutdown -F`:** sono metodi obsoleti con systemd. Oggi si usa il parametro del kernel `fsck.mode=force`. Per XFS non si usa `fsck` ma `xfs_repair`.
- **`/etc/mtab`:** oggi è un link simbolico a `/proc/self/mounts`. "Copiare mtab in fstab" è un consiglio da evitare.
- **"Solo l'amministratore può montare":** non sempre, l'opzione `user` in `fstab` lo permette anche agli utenti.
- **"`/run` è `/var/run`":** è il contrario: `/var/run` è un link a `/run`. Inoltre `/usr/bin` non è "comandi di amministrazione" (quelli sono in `/usr/sbin`), e su Rocky `/bin` è un link a `/usr/bin`.
- **`lvcreate -l` "percentuale":** `-l` vuole un numero di **extent**. La percentuale si esprime con la forma `-l 100%FREE`.
- **Nomi `/dev/hd[a-d]`:** sono obsoleti. Mancano i dischi NVMe (`/dev/nvme0n1`, con partizioni `nvme0n1p1`: notare la `p`).

## Decisioni prese

- Nuova regola in `CLAUDE.md`: l'ultima mezz'ora di ogni giorno è per il ripasso della giornata (priorità) e il resoconto veloce.
- Nuova regola in `CLAUDE.md`: Claude ricorda sempre le domande lasciate senza risposta.
- I PDF dell'Academy (`/Users/dnasso/Desktop/Academy#8/`) sono fonti di verifica. Claude li legge quando serve, segnala gli errori invece di copiarli e scende comunque più in basso del libro.

## File creati o modificati

| File | Motivo |
|---|---|
| `docs/resoconti-chat/2026-11-26-confronto-admin-guide.md` | Questo resoconto |
| `docs/README.md` | Aggiunto questo resoconto |
| `docs/libro/14-storage-dischi-partizioni-lvm.md` | Aggiunta la Admin Guide tra le fonti |
| `CLAUDE.md` | Regole del ripasso di fine giornata e delle domande lasciate indietro |
| `docs/libro/04-file-system-inode-link.md` | Nuovo §3.1 (dove sta la tabella degli inode), errore comune su `df -i` |

## Cose che devo fare io

- [ ] Esercizi 7–12 del capitolo 03
- [ ] Leggere `man 7 hier`
- [ ] Committare il report 6 (`docs/resoconti/11-23-26-REPORT_6.md`)
- [ ] Passare a Claude la traduzione dei capitoli di Pro Git

## Domande aperte / da riprendere

- Domanda di verifica sugli inode (posta il 26/11, "non lo so" → indizio di livello 2 con i conti): ext4 o XFS: quale dà *No space left on device* con spazio libero, scrivendo milioni di file minuscoli.
- Esercizio 5 del cap. 14: domanda 2 (quale `man` per ciascun comando, con `apropos`) e domanda 3 (`-L 5G` contro `-L +5G`).
- Limite dei 2 TiB dell'MBR → GPT.
- Da aggiungere al percorso: nomi dei dispositivi (`sd`/`vd`/`nvme`), partizioni estese e logiche, superblocco e `mkfs`, `fsck`/`xfs_repair`.
