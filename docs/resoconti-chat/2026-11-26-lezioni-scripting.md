# Resoconto – 2026-11-26 – Integrazione delle lezioni di scripting a problemi

## Di cosa abbiamo parlato

1. Lettura del `CLAUDE.md` del repo di un collega ([DMGiulioRomano/formazione_sou](https://github.com/DMGiulioRomano/formazione_sou)) e della sua parte di scripting: 24 lezioni a problemi + allenamenti, kit `prepara.sh`/`verifica.sh`.
2. Integrazione nel mio repo sotto una nuova cartella `studio/` (lezioni + lab), ripartendo da zero.
3. Confronto fra i due metodi di insegnamento e proposte di modifica.

## Concetti spiegati

- Come funziona una lezione a problemi: Situazione → Il contesto → Compito → tentativo → indizi → `verifica.sh` → domande «Dopo» → spiegazione → diario e sintesi.

## Decisioni prese

- Nuova struttura: `studio/lezioni/scripting/` e `studio/lab/scripting/`. `docs/` resta com'è.
- Lezioni 01, 02 e 13 (le uniche con diario già scritto): diario e sintesi svuotati, stati della mappa a «—», anche in `00-percorso.md`. Non copiata la `palestra/` del collega (contiene le sue soluzioni).
- Nuova sezione in `CLAUDE.md` «Lezioni di scripting a problemi», con la scala di aiuto adattata: al livello 3 si riduce il problema e si spiega il concetto, la soluzione solo su richiesta esplicita.
- I link Obsidian `[[...]]` delle lezioni puntano ad appunti che qui non esistono: la teoria andrà nei capitoli di `docs/libro/`.

## File creati o modificati

| File | Motivo |
|---|---|
| `studio/lezioni/scripting/*.md` | Lezioni copiate, diari azzerati, URL del clone aggiornato |
| `studio/lab/scripting/prepara.sh`, `verifica.sh` | Kit copiato invariato |
| `studio/README.md` | Indice e origine del materiale |
| `CLAUDE.md` | Regole per le lezioni a problemi |
| `.gitignore` | Esclusi `dati/` e `uscita/` della palestra |
| `docs/README.md` | Aggiunti `studio/` e questo resoconto |

## Cose che devo fare io

- [x] Rispondere alle domande sulle modifiche proposte al `CLAUDE.md`
- [ ] Commit e push, poi `git pull` sulla VM
- [ ] Installare sulla VM i pacchetti elencati in `00-percorso.md` (EPEL, ShellCheck, …) e fare lo snapshot
- [ ] Esercizi 7–12 del capitolo 03
- [ ] Leggere `man 7 hier`
- [ ] Committare il report 6
- [ ] Passare a Claude la traduzione dei capitoli di Pro Git

## Domande aperte / da riprendere

- **Da qui si riparte (27/11):** correzione a *Learning Bash* 8.7 (`for file in $(ls -d /tmp/*)` si spezza sui nomi con spazi): che rapporto c'è con i file con spazi che il kit mette in `dati/`?
- Snapshot della VM `prima-di-scripting`: fatto o no?
- **Primo passo pratico del 27/11:** chiave ssh della VM su GitHub e remote del clone sulla VM da `https://` a ssh, per fare commit e push dei miei script dalla VM (`palestra/`).
- Ripasso di oggi da fare domani: repository e EPEL, output di `dnf install`, scriptlet e `$1`, `/etc/shells`, idempotenza.

- Domanda di verifica sugli inode: ext4 o XFS, quale dà *No space left on device* con spazio libero scrivendo milioni di file minuscoli.
- Esercizio 5 del cap. 14: domanda 2 (`apropos`) e domanda 3 (`-L 5G` contro `-L +5G`).
- Limite dei 2 TiB dell'MBR → GPT.
- Da aggiungere al percorso: nomi dei dispositivi, partizioni estese e logiche, superblocco e `mkfs`, `fsck`/`xfs_repair`.

## Aggiornamento

- Approvate tutte le proposte e il livello 3 senza soluzione per lo scripting. Aggiunte al `CLAUDE.md` in generale: spiegare le parole partendo dal nome (nome, riferimento, concetto, momento); prevedere prima di lanciare; una domanda per messaggio; ridurre il problema prima di dare la soluzione; errori scoperti con un caso che fallisce; domande «Dopo» nel ripasso serale; correttori automatici per gli esercizi di Track 1.
- Spiegati i passi per partire: commit e push dal Mac, preparazione della VM (EPEL e pacchetti, snapshot), clone/pull del repo sulla VM, `prepara.sh 01`.
- L'utente ha fatto notare che stavo saltando `00-percorso.md` (avevo ridotto la preparazione a una lista di comandi). Si riparte da lì, sezione per sezione: metodo → mappa e calendario → preparazione della VM (pacchetto per pacchetto) → fonti ed errori dei libri dell'Academy.
- Deciso di usare Obsidian sul Mac (vault = radice del repo, `.obsidian/` ignorata da git). Link nuovi in formato Markdown relativo, non `[[...]]`.
- Decisione: il tempo lo gestisce l'utente giorno per giorno (niente calendario imposto); l'obiettivo è studiare in modo pratico, la teoria generale è già stata vista.
- Preparazione della VM: `.repo` e repository abilitati, EPEL, output di `dnf install` → [Capitolo 07 §5–7](../libro/07-gestione-pacchetti.md)
- `00-percorso.md`, passo 1 (metodo): il correttore prova dall'esterno (stdout, codice di uscita, effetti sui file) su un numero finito di casi → servono le domande «Dopo». Prima risposta 🟨 («sintassi ed exit status»), poi ✅.
- Passo 3 (preparazione VM), fatto in pratica: `dnf install ShellCheck` fallisce senza EPEL ✅ previsto; installato `epel-release` (3 file `.repo`, 2 repository abilitati in più, OpenH264 di Cisco); installati gli strumenti (7 nuovi + 3 dipendenze + 3 aggiornati + 9 già presenti = 18 ✅ previsto «di più e di meno»).
- Scriptlet di `dash`: `/etc/shells` ✅, ma il perché ❌ due volte → spiegato (shell di login, `chsh`, `pam_shells`). Spiegati su richiesta `$1` negli scriptlet (1 installazione, 2/1 aggiornamento, 0 rimozione) e l'idempotenza. Esercizio: 1 riga ❌ → 3 righe ✅; `sed` le toglie tutte ✅. → [Capitolo 07 §7](../libro/07-gestione-pacchetti.md)
- Kit sulla VM: clonato il repo, `./prepara.sh 01` → `palestra/l01/` con `conta-righe.sh` (lo script da riparare, previsto ✅ al secondo tentativo) e `dati/`. Visti nell'output: il `.` dell'etichetta SELinux, cartelle piccole dentro l'inode (XFS), gli apici di `ls` sui nomi con spazi.

**Dove ci siamo fermati:** `00-percorso.md`, passo 4 («Le fonti» e «Quando leggi i due libri»). Il ripasso di fine giornata è saltato: l'utente è dovuto andare via.
