# Capitolo 14 – Storage: dischi, partizioni, LVM, swap

> Capitolo **in corso**: cresce con la lezione sui file system iniziata il 2026-11-19.

## Obiettivi

Alla fine del capitolo (per ora) saprai:

- spiegare cos'è un **dispositivo a blocchi** e come Linux lo rappresenta in `/dev`;
- leggere l'output di `lsblk` riga per riga;
- collegare il numero `Device:` di `stat` al dispositivo su cui sta un file system.

## Prerequisiti

- Capitolo 04 (blocchi, inode, campo `Device:` di `stat`).

---

## Teoria

### 1. Dispositivi a blocchi

Un **dispositivo a blocchi** (*block device*) è un dispositivo su cui si può leggere e scrivere in pezzi di dimensione fissa, in **qualunque punto** (accesso casuale): dischi, SSD, chiavette USB, CD. Si contrappone ai **dispositivi a caratteri**, che producono o ricevono un flusso di byte in ordine, come il terminale (`/dev/pts/N`, capitolo 03).

Linux rappresenta ogni dispositivo con un **file speciale** in `/dev`, per esempio `/dev/sda`. Quel file non contiene dati: è una porta verso il driver del kernel che gestisce il dispositivo.

In una VM di VirtualBox i dischi sono **virtuali**: sul computer che ospita la VM sono normali file (ad es. `.vdi`), ma la VM li vede come dischi veri.

### 2. Numeri major e minor

Il kernel identifica ogni dispositivo con due numeri:
- **major**: quale **driver** lo gestisce. Esempi: `8` = dischi SCSI/SATA (`sd`), `11` = lettori CD (`sr`), `253` = *device mapper* (usato da LVM, paragrafo 4);
- **minor**: **quale** dispositivo, tra quelli di quel driver.

Il campo `Device:` di `stat` è proprio questa coppia, scritta in esadecimale e in decimale. Esempio reale sulla VM:

```
Device: fd00h/64768d
```

- `fd00h` è il numero in **esadecimale** (la `h` sta per *hex*): le due cifre alte sono il major, le due basse il minor. `fd` = 253 (major), `00` = 0 (minor), cioè il dispositivo **253:0**;
- `64768d` è lo **stesso** numero in decimale (la `d` sta per *decimal*): 253 × 256 + 0 = 64768. Si moltiplica per 256 **solo il major**, poi si somma il minor.

**Ripasso dell'esadecimale.** Il sistema esadecimale ha 16 cifre: `0`–`9`, poi `a`=10, `b`=11, `c`=12, `d`=13, `e`=14, `f`=15. Ogni cifra vale 16 volte quella alla sua destra:

```
fd = f × 16 + d = 15 × 16 + 13 = 240 + 13 = 253
```

Secondo esempio: un file in `/boot` sta su `sda2` = **8:2**. `stat` stampa `Device: 802h/2050d` (8 e 2 sono minori di 10, quindi in esadecimale si scrivono come in decimale; 8 × 256 + 2 = 2050).

> Nota: la regola "due cifre basse = minor" vale per numeri piccoli come quelli della VM; il formato interno del kernel è più ampio.

In `lsblk` il dispositivo 253:0 è `rlm-root`, montato su `/`: è lì che sta il file system della home.

### 3. Leggere `lsblk`

`lsblk` (*list block devices*) mostra i dispositivi a blocchi come un **albero**: sotto ogni disco le sue partizioni, sotto ogni partizione ciò che contiene. Output reale della VM:

```
NAME         MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda            8:0    0   20G  0 disk
├─sda1         8:1    0  600M  0 part /boot/efi
├─sda2         8:2    0    1G  0 part /boot
└─sda3         8:3    0 18,4G  0 part
  ├─rlm-root 253:0    0 16,4G  0 lvm  /
  └─rlm-swap 253:1    0    2G  0 lvm  [SWAP]
sr0           11:0    1 50,7M  0 rom
```

| Colonna | Significato |
|---|---|
| `NAME` | nome del dispositivo (il file in `/dev`) |
| `MAJ:MIN` | numeri major e minor (paragrafo 2) |
| `RM` | *removable*: 1 se il dispositivo è rimovibile |
| `SIZE` | dimensione |
| `RO` | *read only*: 1 se è in sola lettura |
| `TYPE` | `disk` = disco intero, `part` = partizione, `lvm` = volume logico, `rom` = lettore CD/DVD |
| `MOUNTPOINTS` | dove è montato il file system che contiene (vuoto = non montato direttamente) |

Riga per riga:
- `sda`: l'unico disco della VM, 20 GB;
- `sda1`, `sda2`, `sda3`: tre **partizioni** dello stesso disco;
- `sda1` (600 MB) è montata su `/boot/efi`: è la partizione di sistema EFI, usata dal firmware **UEFI** all'avvio (capitolo 12);
- `sda2` (1 GB) è montata su `/boot`: contiene kernel e file di avvio. È il file system separato visto con `stat` nel capitolo 04;
- `sda3` non ha un punto di montaggio: non contiene un file system, ma è usata da **LVM**, che ci ricava due volumi logici: `rlm-root` (montato su `/`) e `rlm-swap`;
- `[SWAP]`: lo spazio di **swap**, una zona del disco che il kernel usa come estensione della RAM quando la memoria scarseggia (paragrafo da scrivere);
- `sr0`: il lettore CD virtuale (`RM` = 1), con dentro un'immagine da 50,7 MB.

### 4. Partizioni: inizio e dimensione

Per il kernel un disco è una **fila di blocchi numerati** da 0 alla fine. Una **partizione** è un **intervallo contiguo** di quei blocchi, trattato come se fosse un dispositivo a sé (`sda1`, `sda2`, …), con i propri blocchi numerati di nuovo da 0.

Esempio con numeri inventati:

```
sda:   |0 ........ 999|1000 ............ 2999|3000 ....... 9999|
        └── sda1 ─────┘└────── sda2 ─────────┘└──── sda3 ──────┘
```

Per gestire `sda2` il kernel ha bisogno di **due** informazioni:

| Informazione | A cosa serve |
|---|---|
| **inizio** (offset, 1000) | **tradurre**: blocco del disco = inizio + blocco della partizione. Il blocco 100 di `sda2` è il blocco 1100 di `sda` |
| **dimensione** (2000 blocchi) | **proteggere**: una richiesta del blocco 2500 di `sda2` finirebbe nel blocco 3500, dentro `sda3`. Il kernel la rifiuta con un errore di I/O invece di invadere un'altra partizione |

Le partizioni sono gestite dallo **stesso driver del disco** (major 8 per `sda` e per `sda1`–`sda3`): cambia solo il minor.

**Partizione e volume logico a confronto.** Anche un volume logico LVM come `rlm-root` deve tradurre i suoi blocchi in blocchi del disco, ma lo fa il **device mapper**, la parte del kernel che crea dispositivi virtuali descritti da una "mappa" (per questo ha major 253). Una partizione richiede solo un'addizione e un controllo; un volume logico può essere fatto di pezzi sparsi, anche su dischi diversi (paragrafo da scrivere).

### 5. La tabella delle partizioni

Inizio e dimensione di ogni partizione devono sopravvivere allo spegnimento, quindi vanno scritti **sul disco stesso**. Non possono stare:
- dentro un **file system**, perché il file system sta dentro una partizione, e per trovarlo bisogna già sapere dove inizia la partizione (problema dell'uovo e della gallina);
- in **`/etc/fstab`**, perché è un file dentro `/`, quindi anche lui dentro una partizione. In più `fstab` dice *quale file system montare e dove*, non dove iniziano le partizioni (capitolo 15).

Si scrivono quindi nella **tabella delle partizioni** (*partition table*), in una posizione fissa che il kernel trova senza sapere niente in anticipo: l'**inizio del disco**.

**Settore**: la più piccola unità che un disco legge o scrive, tradizionalmente di **512 byte**, numerata da 0.

**MBR** (*Master Boot Record*): lo schema storico. Occupa il **settore 0** e contiene il codice di avvio, la tabella delle partizioni (al massimo 4 voci) e una firma finale. Lo schema moderno è **GPT** (paragrafo da scrivere).

**Conseguenza: nessuna partizione può iniziare dal settore 0.** Se `sda1` iniziasse dal settore 0, il suo settore 0 sarebbe il settore 0 di `sda` (0 + 0 = 0). Creando un file system su `sda1`, `mkfs` scriverebbe le sue strutture proprio lì e **sovrascriverebbe la tabella delle partizioni**. Al riavvio il kernel non troverebbe più nessuna partizione: i dati sarebbero ancora fisicamente sul disco, ma nessuno saprebbe più dove iniziano. In teoria basterebbe iniziare dal settore 1; nella pratica le partizioni iniziano più avanti.

### 6. Verificare inizio e dimensione: `/sys`

`/sys` è un **file system virtuale** (*sysfs*): i suoi file non stanno su nessun disco, li genera il kernel al momento della lettura per mostrare ciò che sa sui dispositivi. Per ogni partizione c'è una directory, ad es. `/sys/block/sda/sda1/`, con due file leggibili da tutti:
- `start`: settore di `sda` in cui inizia la partizione;
- `size`: dimensione in settori da 512 byte.

**Chi legge cosa, e in che ordine.** `/sys` **non** è la fonte della tabella delle partizioni, ne è solo una finestra:

```
settore 0 del disco ──(letto dal kernel al boot, tramite il driver)──> memoria del kernel ──(mostrata a richiesta)──> /sys
```

Il kernel legge la tabella direttamente dal disco e tiene inizio e dimensione nella propria memoria; `/sys` le espone. Per questo `/sys` non dipende da alcuna partizione: viene montato molto presto durante l'avvio (capitolo 12), su una directory chiamata `/sys`, ma il suo contenuto non sta sul disco.

**`/proc`, `/sys` e `/etc` a confronto.**

| Directory | Da dove vengono i dati | Sta su un disco? |
|---|---|---|
| `/proc` | generati dal kernel al momento della lettura: processi (`/proc/PID/`) e stato del kernel (`/proc/meminfo`, `/proc/cpuinfo`) | no (file system virtuale *proc*) |
| `/sys` | generati dal kernel al momento della lettura, organizzati per dispositivi e driver | no (file system virtuale *sysfs*) |
| `/etc` | file di testo veri, scritti da amministratore e pacchetti, letti dai programmi all'avvio | sì: sta nel file system di `/` (`rlm-root`) e sopravvive al riavvio |

Indizi pratici: `ls -l /proc/cpuinfo` mostra dimensione **0**, eppure `cat` stampa molte righe (il contenuto non esiste finché non lo leggi); `df /etc /proc` mostra due file system diversi.

**Risultati sulla VM:**
- `start` di `sda1` = **2048**: la prima partizione inizia al settore 2048, non al settore 1;
- `size` di `sda1` × 512 = **629 145 600 byte** = 600 × 1024 × 1024, cioè 600 **MiB**;
- `start` di `sda2` = `start` di `sda1` + `size` di `sda1`: le partizioni sono **contigue**, senza spazio in mezzo.

### 7. Perché le partizioni iniziano al settore 2048: l'allineamento

I dischi moderni dichiarano settori da 512 byte (*settori logici*) per compatibilità, ma fisicamente leggono e scrivono a pezzi da **4096 byte** (*settori fisici*, 8 settori logici), che iniziano ai settori 0, 8, 16, … ext4 e XFS lavorano a blocchi da 4096 byte, e il primo blocco coincide con il settore 0 della partizione.

- Partizione che inizia al settore **1**: il primo blocco occupa i settori 1–8, cioè **due** pezzi fisici; così ogni blocco del file system. Una lettura richiede due pezzi; una scrittura è ancora peggio: il disco deve **leggere** entrambi i pezzi, **modificare** la parte interessata e **riscriverli** entrambi (*read-modify-write*). Risultato: prestazioni molto più basse.
- Partizione che inizia al settore **2048** (divisibile per 8): ogni blocco del file system coincide con **un** pezzo fisico. Si dice che la partizione è **allineata**.

**Settore logico e settore fisico, più nel dettaglio.** Ogni disco contiene un piccolo computer, il **controller**, con il suo programma (*firmware*). Il sistema operativo non vede la superficie del disco: parla con il controller e chiede settori per **numero** (indirizzamento *LBA*, *Logical Block Addressing*: settore 0, 1, 2, …). Il **settore logico** è l'unità di questa "conversazione": la dimensione che il disco *dichiara* (512 byte). Il **settore fisico** è l'unità con cui il disco *scrive davvero* sul supporto (4096 byte). Il firmware traduce tra i due: è un'emulazione per compatibilità con i sistemi vecchi, che conoscevano solo i 512 byte (dischi detti *512e*, *512 emulation*). Il kernel mostra entrambi i valori:

```
cat /sys/block/sda/queue/logical_block_size
cat /sys/block/sda/queue/physical_block_size
```

In una VM i valori sono quelli del disco **virtuale** (spesso 512 e 512): l'allineamento conta comunque, perché il disco virtuale è un file su un disco reale dell'host.

Perché proprio 2048 e non 8? 2048 × 512 = 1 048 576 byte = **1 MiB**, multiplo di tutte le dimensioni interne in uso (settori da 4 KiB, pagine e blocchi di cancellazione degli SSD, *stripe* dei RAID): un unico valore che va bene ovunque. Lo spazio prima del primo MiB serve anche ad altro: con GPT ospita la tabella delle partizioni (paragrafo da scrivere) e, sui sistemi BIOS, una parte del boot loader (capitolo 12).

### 8. Perché esiste LVM (anteprima)

**I limiti delle partizioni.** Una partizione è un intervallo contiguo di **un solo** disco, con inizio e dimensione fissi:
1. **ingrandirla è difficile**: lo spazio libero dovrebbe stare subito dopo la sua fine, dove di solito inizia un'altra partizione;
2. **non può estendersi su un altro disco**;
3. le dimensioni vanno decise all'installazione, e correggerle costa caro.

**Il modello di LVM** (*Logical Volume Manager*): uno strato tra partizioni e file system.

```
PV  (Physical Volume)  →  VG  (Volume Group)  →  LV  (Logical Volume)  →  file system
sda3                      il serbatoio "rlm"       rlm-root, rlm-swap        XFS di /
```

- **PV**: una partizione (o un disco intero) **inizializzata** da LVM, che vi scrive un'etichetta e dei metadati e la divide in **extent** (pezzetti uguali, di solito 4 MiB). Una partizione appena creata **non** è ancora un PV.
- **VG**: il serbatoio di extent formato da uno o più PV; si può **estendere** aggiungendo PV.
- **LV**: un dispositivo virtuale costruito con extent del VG, anche sparsi e su dischi diversi. La mappa la tiene il **device mapper** (major 253).

**Gli strati sono indipendenti.** Ognuno ha una dimensione propria: ingrandire l'LV non ingrandisce il file system che contiene, perché il file system ha registrato la sua dimensione nelle strutture interne al momento di `mkfs`, e `df` interroga il file system. `/etc/fstab` non c'entra: dice cosa montare e dove, non quanto è grande.

**Esempio: dare più spazio a `/` aggiungendo il disco `sdb`.**

| Passo | Livello | Cosa si fa | Comando |
|---|---|---|---|
| 0 (facoltativo) | partizione | creare `sdb1` (si può usare anche il disco intero) | `fdisk`, `parted` |
| 1 | PV | inizializzare `sdb1` per LVM | `pvcreate /dev/sdb1` |
| 2 | VG | estendere il VG `rlm` con il nuovo PV | `vgextend rlm /dev/sdb1` |
| 3 | LV | estendere `rlm-root` con gli extent liberi | `lvextend -L +10G /dev/rlm/root` |
| 4 | file system | far occupare al file system tutto l'LV | `xfs_growfs /` (ext4: `resize2fs`) |

`lvextend -r` esegue insieme i passi 3 e 4. Lezione completa su LVM: paragrafo da scrivere.

**MB e MiB.** 1 MB (megabyte) = 1 000 000 byte; 1 MiB (mebibyte) = 1024 × 1024 = 1 048 576 byte. `lsblk` scrive `M` ma intende MiB (potenze di 1024).

---

## Comandi e file di riferimento

| Comando / file | A cosa serve | Documentazione |
|---|---|---|
| `lsblk` | Elenca i dispositivi a blocchi ad albero | `man 8 lsblk` |
| `/dev` | File speciali dei dispositivi | `man 7 hier` |
| `/sys/block/sda/sdaN/start`, `size` | Inizio e dimensione (in settori) di una partizione, come li conosce il kernel | `man 5 sysfs` |
| `stat` (campo `Device:`) | Su quale dispositivo sta un file | `man 1 stat` |

## Errori comuni e troubleshooting

- **Pensare che una partizione senza punto di montaggio sia inutilizzata:** può contenere LVM o swap (`sda3`).
- **Confondere disco e partizione:** `sda` è il disco, `sda1` una sua parte.
- **Convertire il decimale di `Device:` moltiplicando tutto per 256:** si moltiplica solo il major, poi si somma il minor (8:2 → 8 × 256 + 2 = 2050, non 802 × 256).

## Collegamento con l'esame EX200

Obiettivo *"Configure local storage"*: *List, create, delete partitions on MBR and GPT disks*; *Create and remove physical volumes*; *Assign physical volumes to volume groups*; *Create and delete logical volumes*.

## Esercizi

1. Con `stat` guarda il campo `Device:` di un file in `/boot`. Convertilo in major e minor e trova la riga corrispondente in `lsblk`.
2. Nella VM guarda `ls -l /dev/sda /dev/sda1`. Qual è il primo carattere della riga? Dove compaiono i numeri major e minor?

3. Confronta `stat /etc/passwd` e `stat /proc/cpuinfo`: campo `Size:` e campo `Device:`. Converti `Device:` in major e minor: trovi quel dispositivo in `lsblk`? Perché?
4. Esegui `df /etc /proc /sys` e spiega la colonna `Filesystem` di ogni riga.

5. Scenario (solo a parole, senza eseguire): il VG ha già 20 GB di extent liberi e vuoi aggiungere 5 GB a un LV montato su `/home` con file system **ext4**. Quali passi della tabella del §8 servono, quali no e perché? Con quale `man` verifichi le opzioni di ciascun comando?

## Domande di autoverifica

1. Che differenza c'è tra un dispositivo a blocchi e uno a caratteri?
2. Cosa indica il numero major? E il minor?
3. Perché `sda3` non ha un punto di montaggio, eppure è usata?
4. Perché una partizione che inizia al settore 1 rende più lente soprattutto le scritture?
5. `/sys` è la fonte da cui il kernel ricava le partizioni? Perché?
6. Perché `sda2` e `rlm-root` hanno numeri major diversi, pur stando sullo stesso disco?
7. Quali due informazioni servono al kernel per gestire una partizione, e a cosa serve ciascuna?

## Fonti

- `man 8 lsblk`, `man 1 stat`
- Documentazione del kernel: `admin-guide/devices.txt` (elenco dei numeri major)
- *Rocky Linux Admin Guide* (versione italiana, libro dell'Academy), capitolo 8 "File System", §8.1–8.2 (pagine 127–138). Attenzione: alcune affermazioni sono imprecise o superate, vedi il resoconto del 26/11/2026.

## Cronologia

- 2026-11-19: capitolo iniziato con la lezione sui file system: dispositivi a blocchi, major e minor, collegamento con `Device:` di `stat`, lettura di `lsblk` con l'output reale della VM.
- 2026-11-25: ripasso dell'esadecimale e secondo esempio di `Device:` (8:2 → `802h/2050d`); nuovo §4 sulle partizioni (intervallo di blocchi, inizio per tradurre, dimensione per proteggere, confronto con il device mapper), nato dalle domande socratiche della lezione. Nuovo §5: tabella delle partizioni all'inizio del disco, settore, MBR, perché nessuna partizione inizia dal settore 0. Nuovo §6: `/sys`, ordine disco → kernel → `/sys`, verifica di `start`/`size` sulla VM (2048, 600 MiB, partizioni contigue), MB e MiB. Nuovo §7: allineamento, settori logici e fisici, read-modify-write, perché 1 MiB. Aggiunti: settore logico e fisico (controller, firmware, LBA, 512e), confronto `/proc`–`/sys`–`/etc` (spiegazione di livello 3 su richiesta). Nuovo §8: perché esiste LVM, PV/VG/LV, indipendenza degli strati, passi per estendere `/` con un nuovo disco (livello 3 su richiesta).
