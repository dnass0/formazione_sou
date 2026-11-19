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

- `fd00` in esadecimale: `fd` = 253 (major), `00` = 0 (minor), cioè il dispositivo **253:0**;
- `64768` in decimale = 253 × 256 + 0.

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

---

## Comandi e file di riferimento

| Comando / file | A cosa serve | Documentazione |
|---|---|---|
| `lsblk` | Elenca i dispositivi a blocchi ad albero | `man 8 lsblk` |
| `/dev` | File speciali dei dispositivi | `man 7 hier` |
| `stat` (campo `Device:`) | Su quale dispositivo sta un file | `man 1 stat` |

## Errori comuni e troubleshooting

- **Pensare che una partizione senza punto di montaggio sia inutilizzata:** può contenere LVM o swap (`sda3`).
- **Confondere disco e partizione:** `sda` è il disco, `sda1` una sua parte.

## Collegamento con l'esame EX200

Obiettivo *"Configure local storage"*: *List, create, delete partitions on MBR and GPT disks*; *Create and remove physical volumes*; *Assign physical volumes to volume groups*; *Create and delete logical volumes*.

## Esercizi

1. Con `stat` guarda il campo `Device:` di un file in `/boot`. Convertilo in major e minor e trova la riga corrispondente in `lsblk`.
2. Nella VM guarda `ls -l /dev/sda /dev/sda1`. Qual è il primo carattere della riga? Dove compaiono i numeri major e minor?

## Domande di autoverifica

1. Che differenza c'è tra un dispositivo a blocchi e uno a caratteri?
2. Cosa indica il numero major? E il minor?
3. Perché `sda3` non ha un punto di montaggio, eppure è usata?

## Fonti

- `man 8 lsblk`, `man 1 stat`
- Documentazione del kernel: `admin-guide/devices.txt` (elenco dei numeri major)

## Cronologia

- 2026-11-19: capitolo iniziato con la lezione sui file system: dispositivi a blocchi, major e minor, collegamento con `Device:` di `stat`, lettura di `lsblk` con l'output reale della VM.
