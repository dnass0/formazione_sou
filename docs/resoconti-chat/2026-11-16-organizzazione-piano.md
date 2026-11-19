# Resoconto – 2026-11-16 – Organizzazione del percorso e piano di studio

## Di cosa abbiamo parlato

1. Ho presentato l'Academy DevOps di Sourcesense: 6 mesi, iniziata il 15/10/2026, full-time.
2. Ho condiviso il materiale della Track 1: regole generali (report settimanali, repo GitHub, Vim, LLM il meno possibile, community da seguire, firma email) e gli Step 1–3 (video Linux, documentari, libri Rocky Linux, Git).
3. Ho condiviso l'elenco completo delle track: Linux, Jenkins/Ansible/K8s, Configuration Management, OpenShift, Cloud, Observability, LLM, più track extra e opzionali.
4. Abbiamo costruito il piano di studio a settimane.
5. Ho comunicato che dopo circa 3 mesi (metà gennaio 2027) ci sarà un esame sulla Track 1, e che il mio obiettivo è arrivare al livello dell'esame **Red Hat EX200 (RHCSA)**.
6. Abbiamo definito il ruolo di Claude come **professore** e il formato del libro di testo.
7. Abbiamo sistemato la numerazione delle settimane e il nome della cartella del repo (`formazione_sou`).
8. Abbiamo creato la cartella `docs/` per tutta la documentazione e deciso di fare un resoconto per ogni chat.
9. Abbiamo spostato tutto (`CLAUDE.md`, `docs/`, piano) dentro `formazione_sou`.
11. Abbiamo spuntato il piano leggendo i report settimanali e gli esercizi della Track Extra nella cartella `~/Desktop/Academy#8`, e aggiunto le attività svolte che mancavano dal piano (Accenni di Networking, corso sicurezza, esercizi Extra 1–6, Arch Linux, LVM, SSH con chiavi).
12. Permessi: Claude può leggere liberamente `~/Desktop/Academy#8`; per tutto il resto chiede ogni volta (`.claude/settings.local.json`).
10. Abbiamo iniziato la **settimana 6**, partendo dalla preparazione del laboratorio (Mac Intel x86_64, 16 GB di RAM, VirtualBox già installato) e da un test d'ingresso sugli strumenti essenziali.

## Test d'ingresso – Settimana 6 (in corso)

Domande complete ed esito aggiornato: [`docs/test/2026-11-16-test-ingresso-settimana-6.md`](../test/2026-11-16-test-ingresso-settimana-6.md)

| # | Argomento | Esito | Note |
|---|---|---|---|
| 1 | `>` e `>>` | 🟨 | Verifica `sort f > f` sbagliata; spiegata su richiesta (cap. 03 §3.6), da verificare con l'esercizio 3 |
| 2 | `2>`, `2>&1`, descrittori 0, 1, 2 | ✅ | Dopo la verifica: ordine delle redirezioni capito; lo 0 è lo stdin (di default il terminale, non per forza la tastiera) |
| 3 | Pipe `cat \| grep \| wc -l` | 🟨 | Capito che `grep` trova la stringa ovunque (`bashful`). Da correggere: la pipe collega stdout→stdin, trasporta byte (non righe) e non elabora nulla |
| 4 | Àncore `^` e `$` | ✅ | Dopo l'indizio: `grep 'bash$'` |

## Concetti spiegati

- File descriptor, redirezioni e loro ordine, pipe a basso livello, àncore di `grep` → [Capitolo 03](../libro/03-shell-strumenti-essenziali.md)
- Perché `sort f > f` svuota il file: la shell tronca il file prima di lanciare il comando → [Capitolo 03, §3.6](../libro/03-shell-strumenti-essenziali.md)

- Perché la Track 1 (Linux) è la più importante: tutte le track successive (Jenkins, Kubernetes, OpenShift, cloud) girano su Linux, e i problemi si riducono spesso a permessi, processi, rete, file system o SELinux.
- L'EX200 è un esame **pratico**, senza internet: bisogna abituarsi a usare la documentazione locale (`man`, `man -k`, `info`, `/usr/share/doc`).
- La cartella locale di un repo Git può avere un nome diverso da quello del repo su GitHub, ma usare lo stesso nome evita confusione.

## Decisioni prese

- **Inizio del piano:** 15/10/2026. La settimana 1 comprende solo il 15 e il 16 ottobre, contati come settimana a parte. Oggi siamo nella **settimana 6**, l'esame cade nella **settimana 14** (11–15/01/2027).
- **Track 1:** programma costruito sugli obiettivi EX200. Le track successive restano indicative, da dettagliare dopo l'esame.
- **Claude fa il professore**, con una scala di aiuto: (1) il COSA, (2) un indizio, (3) la spiegazione completa solo su mia richiesta. Le regole sono in `CLAUDE.md`.
- **Libro di testo:** un capitolo per argomento, aggiornato man mano, in `docs/libro/`.
- **Cartella del repo:** `formazione_sou`, lo stesso nome del repo che creerò su GitHub, come richiesto dall'Academy. (L'avevamo rinominata per errore in `sourcesense_academy_dnasso` e poi rimessa a posto.)
- **Documentazione:** tutto in `docs/`, con un resoconto per ogni chat.
- **Tutto sta dentro `formazione_sou`:** `CLAUDE.md`, `docs/` e `PIANO_STUDIO.md`. Le sessioni con Claude vanno aperte da questa cartella.

## File creati o modificati

| File | Motivo |
|---|---|
| `CLAUDE.md` | Istruzioni per Claude: ruolo di professore, libro di testo, documentazione, resoconti |
| `PIANO_STUDIO.md` | Piano di studio: sezione A (materiale Academy) e sezione B (settimane fino all'esame) |
| `docs/README.md` | Indice generale della documentazione |
| `docs/test/2026-11-16-test-ingresso-settimana-6.md` | Domande del test d'ingresso ed esito |
| `docs/libro/03-shell-strumenti-essenziali.md` | Primo capitolo del libro, nato dal test d'ingresso |
| `.claude/settings.local.json` | Permesso di lettura su `~/Desktop/Academy#8` |
| `docs/libro/README.md` | Indice del libro di testo (26 capitoli + 2 appendici, tutti da scrivere) |
| `docs/resoconti-chat/2026-11-16-organizzazione-piano.md` | Questo resoconto |

## Cose che devo fare io

- [ ] Aprire `PIANO_STUDIO.md` con Vim e spuntare quello che ho già fatto nella sezione A (cercare nel file, sostituire un carattere, salvare: le risposte sono in `vimtutor`, lezioni 3 e 4)
- [ ] Scaricare gli obiettivi ufficiali EX200 dal sito Red Hat e confrontarli con il piano (soprattutto la parte sui container)
- [ ] Creare il repo `formazione_sou` su GitHub, inizializzare Git nella cartella locale e collegarle (Pro Git, sezioni 2.1 e 2.5)
- [ ] Preparare il laboratorio in VirtualBox: 2 VM Rocky Linux (`server1`, `server2`), installazione minimale, disco aggiuntivo, rete tra le VM, snapshot
- [ ] Rispondere al test d'ingresso sugli strumenti essenziali (5 domande, senza cercare)

- learngitbranching: ancora da fare
- Voci confermate: presentazione di Giosuè Manzo fatta; ancora da fare repo GitHub, IT Crowd, libro Ansible, feedback libri, ACloudGuru. La "revisione degli esami scritti" è stata tolta dal piano perché non esiste.
- [ ] Esperimento: un job cron che salva `pwd` in `/tmp`, per scoprire da quale directory cron esegue gli script (riguarda `delete-30.sh`)
- [ ] Correggere il commento di `delete-30.sh`
- [ ] Rispondere: quale tipo di rete VirtualBox usa la VM, e a quale IP/porta mi collego in SSH
- [ ] Completare il test d'ingresso (domande 5–10)
- [ ] Leggere il Capitolo 03 e fare gli esercizi (in particolare 3 e 5)

## Domande aperte / da riprendere

- Da quale argomento della settimana 6 partire con la prima lezione.
- Confermare se i container sono ancora tra gli obiettivi EX200 attuali.
