# Resoconto – 2026-11-17 – Esercizi del capitolo 04 (inode e link)

## Di cosa abbiamo parlato

1. Ripresa della chat del giorno prima ([2026-11-16-test-ingresso-2](2026-11-16-test-ingresso-2.md)): dove trovare il capitolo 04 e i suoi esercizi.
2. Impostazione di Claude Code: in modalità fullscreen (`/tui fullscreen`) lo scorrimento automatico si disattiva con `/config` → Auto-scroll = false.
3. Esercizi 1–4 del capitolo 04, uno alla volta, con previsione prima di eseguire. Assegnato l'esercizio 5, svolto il giorno dopo ([2026-11-18-file-system-directory](2026-11-18-file-system-directory.md)).

## Esercizi svolti

| # | Esercizio | Esito | Note |
|---|---|---|---|
| 1 | Hard link: numero di inode e link count | ✅ | Previsto correttamente: stesso numero di inode e link count 2 su entrambi i nomi, perché l'informazione sta nel singolo inode |
| 2 | Cancellare il primo nome | ✅ | Previsioni giuste (contenuto leggibile, link count 1, stesso inode, blocchi non liberati). Errore corretto: pensava che la directory corrente tenesse "aperto" il file. Verificato con `ls -li`: inode 16925780 invariato, link count 1 |
| 3 | Link simbolico: inode e dimensione | ✅ | Dopo la correzione: link assoluto (30 byte) e relativo `./link/hl_prova.txt` (19 byte), entrambi funzionanti. Verificato con `cat ../sl_rel.txt` da dentro `link/` che il percorso relativo si risolve rispetto alla directory del link. Errori iniziali: pensava che il link contenesse la directory; primo link creato pendente |
| 4 | Cancellare la destinazione di un link simbolico | ✅ | Previsioni giuste (link pendenti, poi seguono il nuovo file; con un hard link si leggerebbe il vecchio contenuto). Corretto: la tabella degli inode non "si sposta". Nuovo inode 50503131, vicino alla directory `link` |

## Concetti spiegati

- Directory corrente ≠ file aperto: la shell tiene un riferimento all'inode della **directory** (`cwd`), non ai file che contiene; un file è aperto solo se un processo ha un file descriptor su di esso → [Capitolo 04 §6.3](../libro/04-file-system-inode-link.md)
- PID, `$$`, file system virtuale `/proc`, `/proc/$$/fd` e `/proc/$$/cwd` (link simbolici); fd 0/1/2 su `/dev/pts/N` (pseudo-terminale); fd 255 aperto da bash per uso proprio → [Capitolo 03 §2](../libro/03-shell-strumenti-essenziali.md). Il paragrafo era nel libro ma non era mai stato spiegato in chat: spiegato da zero.
- Lettura di `ls -l`: il `.` dopo i permessi indica un contesto SELinux; "totale N" è lo spazio su disco (KiB) dei file elencati. Un file da 26 byte occupa un blocco intero da 4 KiB (frammentazione interna): dimensione ≠ spazio occupato.
- Il newline `\n` è un byte: i 26 byte del file tornano contando i caratteri.
- Il link simbolico contiene **esattamente** la stringa scritta come destinazione (nome del file compreso), senza controlli di esistenza. Un percorso relativo viene risolto rispetto alla **directory del link**, non alla directory corrente. Assoluto: sopravvive allo spostamento del link; relativo: sopravvive allo spostamento dell'insieme. Il contenuto non si modifica: si cancella e si ricrea il link.
- Inode riusato: cancellato `sl_proba.txt`, il nuovo link ha ricevuto lo stesso numero 16929384. Le caselle della tabella degli inode sono fisse: non scorrono, vengono solo segnate libere e riassegnate.
- La mtime di una directory cambia quando si aggiunge o toglie un nome, perché cambia il suo contenuto.
- XFS: il numero di inode codifica la posizione sul disco (gruppi di allocazione); XFS mette l'inode di un file vicino a quello della sua directory (home 167…/169…, `link` 503…/505…).
- Collegamento: la `cwd` ereditata dai comandi è il nodo dell'esperimento cron su `delete-30.sh`.

## Decisioni prese

- Gli esercizi si fanno uno alla volta: previsione scritta prima, poi esecuzione sulla VM e output inviato come screenshot.

## File creati o modificati

| File | Motivo |
|---|---|
| `docs/resoconti/2026-11-17-esercizi-cap04.md` | Questo resoconto |
| `docs/README.md` | Aggiunto questo resoconto all'elenco |
| `docs/libro/03-shell-strumenti-essenziali.md` | §2 ampliato: `/proc`, `/dev/pts`, fd 255, `cwd`, directory corrente ≠ file aperto |
| `docs/libro/04-file-system-inode-link.md` | §2 frammentazione interna, "totale", punto SELinux; §3 riuso e posizionamento degli inode in XFS; §5.2 contenuto esatto e percorso relativo dei link simbolici |

## Cose che devo fare io

- [x] Esercizi 1–4 del capitolo 04
- [ ] Esercizi 5–6 del capitolo 04 (fatti il 18/11)
- [ ] Esercizi 7–12 del capitolo 03
- [ ] Dire se sulla VM `/home` è una partizione separata (verificato il 18/11)

## Domande aperte / da riprendere

- Aggiungere un nome a una directory cambia anche la sua ctime? E cancellarne uno cambia la mtime? (risolta il 18/11)
- Dopo gli esercizi: lezione dedicata ai file system.
