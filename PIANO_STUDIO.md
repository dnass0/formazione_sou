# Piano di studio – DevOps Academy

> Inizio: **15/10/2026** · Full-time · Durata: circa 6 mesi
> **Esame Track 1 (Linux): metà gennaio 2027 circa**
> Obiettivo personale per la Track 1: livello **Red Hat EX200 (RHCSA)**
> Legenda: `[ ]` da fare · `[x]` fatto · `[~]` in corso

## Routine settimanale

| Giorno | Mattina | Pomeriggio |
|---|---|---|
| Lun–Gio | Teoria (video, libri, man page, capitolo del libro) | Laboratorio sulle VM + note nel repo |
| Ven | Mini-simulazione cronometrata sugli argomenti della settimana | Ripasso dei punti deboli + report settimanale (mail "[DevOps Academy] Report Studio") |

Ogni giorno:
- 15 minuti di Vim (niente altri editor nel laboratorio)
- prima `man`/`--help`/`/usr/share/doc`, poi la rete, LLM il meno possibile
- annotare in `diario-errori.md` ogni errore fatto e come l'ho risolto (utile anche per i report)
- commit delle note nel repo (`formazione_sou`)

## Attività una tantum

- [ ] Creare il repo GitHub `formazione_sou` e comunicare l'URL agli istruttori
- [x] Accesso a Rocket Chat (canale Academy DevOps)
- [x] Impostare la firma email
- [x] Seguire CNCF, antirez, FSF, Apache, Linux Foundation
- [x] Guardare la presentazione di Giosuè Manzo (Academy #2)
- [ ] Iniziare IT Crowd 🙂
- [ ] Scaricare gli obiettivi ufficiali EX200 dal sito Red Hat e confrontarli con questo piano
- [ ] Preparare il laboratorio (vedi sotto)

## Laboratorio

Hypervisor: VirtualBox (già installato sul Mac: Intel x86_64, 16 GB di RAM).

- [x] Verificare da terminale l'architettura del Mac e scaricare l'ISO di Rocky Linux corrispondente
- [~] Creare 2 VM, `server1` e `server2` (circa 2 GB di RAM, 2 CPU, disco da 20 GB ciascuna) — esistono già una VM Rocky Linux e una Debian (20/10)
- [ ] Installazione minimale, senza interfaccia grafica
- [ ] Creare un utente normale con permessi da amministratore, oltre a root
- [ ] Aggiungere a ogni VM un secondo disco da circa 5 GB, lasciato vuoto (serve nella settimana 9)
- [ ] Configurare la rete: le VM comunicano tra loro **e** escono su internet (scegliere il tipo di rete VirtualBox giusto)
- [ ] Verifica: da `server1` raggiungere `server2` e un sito internet
- [ ] Snapshot "pulito" di ogni VM, per rompere e ripristinare senza paura

---

# Track 1 – Linux System Administration & Networking

## A. Materiale dell'Academy (Step 1–3)

### Step 1 – Libri e video corsi
- [x] Video: Introduzione Linux
- [x] Video: Architettura
- [x] Video: Installazione e Package Management (test finale non svolto: link Udemy senza accesso)
- [x] Video: Comandi Linux
- [x] Video: File System

### Step 2 – GNU/Linux e filosofia open source
- [x] Documentario Revolution OS
- [x] TED Talk di Linus Torvalds
- [x] Talk di Kat Cosgrove "Fly Me to the Moon"
- [x] Commento con le impressioni sulla pagina Confluence

### Step 3 – SysAdmin Books (Rocky Linux) e Git
- [~] Libro Rocky Linux Admin
- [x] Libro Bash
- [ ] Libro Ansible
- [ ] Feedback sui tre libri → mail agli istruttori
- [~] Pro Git, capitoli 1–3 → mail con i concetti compresi
- [ ] Corso Git su ACloudGuru (credenziali dagli istruttori)
- [ ] learngitbranching.js.org

### Altro materiale dell'Academy
- [x] "Accenni di Networking" + To Do inviato (09/11)
- [x] Corso sulla sicurezza sul lavoro (29/10)

### Track Extra – Esercizi
- [x] Esercizi 1–4 (Bash), con correzione dell'esercizio 3
- [x] Esercizi 5–6 (11/11)

### Fatto in più
- [x] Installazione manuale di Arch Linux in VM, BIOS + MBR, in gruppo (30/10 – 02/11)
- [x] `vimtutor` (04/11)
- [x] Partizioni e volumi logici (LVM) da terminale su VM (09/11)
- [x] Accesso SSH alla VM con chiavi (`ssh-keygen`) (10/11)

### Report settimanali
- [x] Settimana 1 · [x] Settimana 2 · [x] Settimana 3 · [x] Settimana 4 · [x] Settimana 5

## B. Programma settimanale (verso l'esame)

### Settimane 1–5 · 15/10 – 13/11
(La settimana 1 comprende solo i due giorni iniziali: 15/10 – 16/10)
Materiale dell'Academy (sezione A): spunta quello che hai già fatto.

### Settimana 6 · 16/11 – 20/11 ← siamo qui
- [ ] Spuntare nel piano le attività già fatte
- [ ] Recuperare il materiale dell'Academy rimasto indietro (sezione A)
- [ ] Preparare il laboratorio (vedi sezione **Laboratorio**)
- [ ] Test d'ingresso sugli strumenti essenziali (5 domande, senza cercare)
- [ ] **Strumenti essenziali:** shell, redirezioni (`>`, `>>`, `2>`, `|`), `grep` ed espressioni regolari
- [ ] File: creare, copiare, spostare, cancellare; hard link e link simbolici
- [ ] Archivi e compressione: `tar`, `gzip`, `bzip2`, `xz`
- [ ] Trovare la documentazione: `man` (sezioni, `man -k`), `info`, `/usr/share/doc`
- [ ] Pacchetti: `dnf` (install, remove, search, provides, history), configurare un repository

### Settimana 7 · 23/11 – 27/11
- [ ] **Utenti e gruppi:** creare, modificare ed eliminare utenti e gruppi; `/etc/passwd`, `/etc/shadow`, `/etc/group`
- [ ] Password e scadenza (`chage`), configurare `sudo` (`visudo`, `/etc/sudoers.d/`)
- [ ] **Permessi:** rwx, ugo, notazione ottale, `umask`, SUID/SGID/sticky, directory condivise con SGID
- [ ] Diagnosticare problemi di permessi
- [ ] **Script shell:** variabili, argomenti (`$1`, `$@`, `$#`), exit code, `if`/`test`, cicli `for`/`while`, catturare l'output dei comandi

### Settimana 8 · 30/11 – 04/12
- [ ] **Processi:** `ps`, `top`, segnali e `kill`, `nice`/`renice`, job in background
- [ ] **systemd:** unit, `systemctl` (start, stop, enable, status), target, target di default
- [ ] **Boot:** sequenza di avvio, GRUB, avviare un target diverso, **interrompere il boot e reimpostare la password di root**
- [ ] **Log:** `journalctl`, journal persistente, `/var/log`
- [ ] `tuned`: profili e profilo raccomandato

### Settimana 9 · 07/12 – 11/12 (08/12 festivo)
- [ ] **Storage:** dischi, MBR e GPT, partizioni (`fdisk`, `gdisk`, `parted`)
- [ ] **LVM:** PV, VG, LV; creare, estendere, ridimensionare
- [ ] **File system:** creare e montare ext4, xfs, vfat; `/etc/fstab` con UUID ed etichette
- [ ] Swap: aggiungere swap senza toccare quello esistente
- [ ] Estendere un LV e il suo file system

### Settimana 10 · 14/12 – 18/12
- [ ] **Fondamenti di rete:** modello TCP/IP, IPv4 e subnetting, IPv6, gateway, DNS, porte TCP/UDP
- [ ] **NetworkManager:** `nmcli`, IP statici IPv4/IPv6, hostname, risoluzione dei nomi (`/etc/hosts`, `resolv.conf`)
- [ ] Strumenti di diagnosi: `ip`, `ss`, `ping`, `tracepath`, `dig`, `curl`
- [ ] **firewalld:** zone, servizi, porte, regole permanenti
- [ ] **SSH:** chiavi, configurazione, `scp`/`sftp`/`rsync`

### Settimana 11 · 21/12 – 23/12 (settimana corta)
- [ ] **NFS:** montare condivisioni NFS (con `server2` come server)
- [ ] **autofs:** mount automatici, anche delle home
- [ ] **Pianificazione:** `cron`, `at`, timer systemd
- [ ] **Ora:** `chrony`, client NTP
- [ ] Bootloader: modificare i parametri del kernel (`grubby`)

### Settimana 12 · 28/12 – 01/01 — Buffer festivo
- [ ] Ripasso leggero, flashcard
- [ ] **Prima simulazione d'esame completa** (cronometrata, senza internet)

### Settimana 13 · 04/01 – 08/01 (06/01 festivo)
- [ ] **SELinux:** modalità enforcing/permissive, contesti di file e processi, `restorecon`, `semanage fcontext`, porte, booleani
- [ ] Diagnosticare violazioni SELinux (`ausearch`, `sealert`, journal)
- [ ] **Container (verificare sugli obiettivi attuali):** `podman`, `skopeo`, storage persistente, container come servizio systemd
- [ ] Seconda simulazione d'esame

### Settimana 14 · 11/01 – 15/01 — Esame
- [ ] Simulazioni d'esame e ripasso dei punti deboli (dal `diario-errori.md`)
- [ ] **Esame Track 1**

---

# Tracce successive (indicative, da dettagliare dopo l'esame)

| Periodo | Track |
|---|---|
| 18/01 – 19/02 | **Track 2** – Jenkins & Ansible Ops + K8s Deploy & Quality Gate |
| 22/02 – 05/03 | **Track 3** – Configuration Management |
| 08/03 – 19/03 | **Track 4** – Supporto OpenShift 1° livello (k8s locale) |
| 22/03 – 02/04 | **Track 5** – Cloud Azure / AWS |
| 05/04 – 16/04 | **Track 6** – Cloud Native & Observability |
| 19/04 – 30/04 | **Track π** – LLM e GenAI · Track Extra / Random · OBS2.0 (opzionali) |
