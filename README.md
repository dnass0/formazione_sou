# formazione_sou – DevOps Academy

Repository del mio percorso nella **DevOps Academy di Sourcesense**: 6 mesi full-time, iniziata il **15/10/2026**.

Qui raccolgo note, lezioni, esercizi e report settimanali. La parte più importante è la **Track 1 – Linux System Administration & Networking**, che si chiude con un esame verso **metà gennaio 2027**. Come obiettivo personale studio per arrivare al livello dell'esame **Red Hat EX200 (RHCSA)**.

---

## Struttura del repository

```
formazione_sou/
├── README.md              ← questo file
├── PIANO_STUDIO.md        ← piano di studio e checklist degli argomenti
├── CLAUDE.md              ← istruzioni per Claude, usato come "professore"
├── .gitignore
├── docs/
│   ├── README.md          ← indice della documentazione
│   ├── libro/             ← libro di testo, un capitolo per argomento
│   ├── resoconti/         ← i miei report settimanali per l'Academy
│   ├── resoconti-chat/    ← resoconto di ogni sessione di studio con Claude
│   ├── test/              ← test d'ingresso, quiz e simulazioni, con l'esito
│   └── glossario/         ← inglese tecnico delle pagine man
└── esercizi/
    ├── esercizio_bonus_Paolo.md   ← awk, grep e sed in pipe su un CSV
    ├── rubrica.csv                ← dati di prova dell'esercizio bonus
    └── extras/                    ← esercizi extra e corretti, immagini, script bash
```

| Percorso | Cosa contiene |
|---|---|
| [`PIANO_STUDIO.md`](PIANO_STUDIO.md) | Routine settimanale, argomenti delle track, checklist dei progressi |
| [`docs/README.md`](docs/README.md) | Indice di tutta la documentazione e cronologia delle sessioni |
| [`docs/libro/`](docs/libro/README.md) | Lezioni teoriche in stile libro di testo, dal basso livello (kernel, file system, processi) fino ai comandi |
| [`docs/resoconti/`](docs/resoconti/) | Report settimanali inviati all'Academy |
| [`docs/resoconti-chat/`](docs/resoconti-chat/) | Cosa è stato fatto in ogni sessione: concetti, esercizi, errori, cose in sospeso |
| [`docs/test/`](docs/test/) | Test con le mie risposte e la valutazione di ciascuna |
| [`docs/glossario/`](docs/glossario/inglese-tecnico-man.md) | Parole inglesi frequenti nelle pagine `man` e metodo per leggerle |
| [`esercizi/`](esercizi/) | Esercizi svolti e materiale extra |

---

## Il libro di testo

Ogni argomento affrontato diventa un capitolo, con la stessa struttura:
- obiettivi e prerequisiti;
- teoria, con esempi di output reali della VM letti riga per riga;
- comandi e file di riferimento;
- errori comuni;
- collegamento con gli obiettivi EX200;
- esercizi e domande di autoverifica, senza soluzioni;
- fonti e cronologia delle aggiunte.

Capitoli già iniziati (l'elenco completo, con lo stato, è in [`docs/libro/README.md`](docs/libro/README.md)):

| # | Capitolo | Argomenti principali |
|---|---|---|
| 03 | [La shell e gli strumenti essenziali](docs/libro/03-shell-strumenti-essenziali.md) | file descriptor, `/proc`, redirezioni, pipe, `grep` e regex, archivi e compressione, documentazione locale, `awk`, `sed` |
| 04 | [Il file system: inode e link](docs/libro/04-file-system-inode-link.md) | blocchi, inode, directory e voci di directory, hard link e link simbolici, cancellazione e recupero, date e `relatime`, dettagli di XFS |
| 07 | [Gestione dei pacchetti](docs/libro/07-gestione-pacchetti.md) | pacchetti e repository, nome completo (NEVRA), metadati, `dnf provides` |
| 08 | [Utenti, gruppi e password](docs/libro/08-utenti-gruppi-password.md) | `passwd` e `chpasswd`, `/etc/shadow`, hash e cifratura |
| 14 | [Storage: dischi, partizioni, LVM](docs/libro/14-storage-dischi-partizioni-lvm.md) | dispositivi a blocchi, numeri major e minor, `lsblk` |

---

## Laboratorio

- **VM Rocky Linux 9** (compatibile con RHEL) su VirtualBox, con un disco virtuale da 20 GB: `/boot/efi`, `/boot` e LVM con `/` e swap. File system XFS.
- Accesso dal Mac via SSH con port forwarding (`127.0.0.1`, porta 2222) e autenticazione a chiave.
- Regola di studio: prima `man`, `info`, `--help` e `/usr/share/doc`, come all'esame EX200, dove non c'è internet.

---

## Come è prodotto il materiale

- **Scritti da me:** i report settimanali (`docs/resoconti/`), le soluzioni degli esercizi (`esercizi/`), le risposte ai test e la checklist del piano di studio.
- **Scritti con Claude (Anthropic), usato come professore:** il libro di testo (`docs/libro/`), i resoconti delle sessioni (`docs/resoconti-chat/`), le domande dei test e il glossario.

Claude segue le regole di [`CLAUDE.md`](CLAUDE.md): non risolve gli esercizi al posto mio, dà aiuti graduali (prima il *cosa*, poi un indizio, solo alla fine la spiegazione completa), fa domande per verificare che ho capito e non scrive i report settimanali.

---

## Flusso di lavoro con Git

Il repository è versionato con Git e pubblicato su GitHub. Il ciclo di ogni giorno:

```
git status                          # cosa è cambiato
git add .                           # prepara le modifiche (staging area)
git commit -m "Cosa è cambiato"     # salva una "fotografia" nella storia
git push                            # invia i commit a GitHub
```

Il file [`.gitignore`](.gitignore) esclude i file del Finder del Mac (`.DS_Store`) e le impostazioni locali di Claude Code.
