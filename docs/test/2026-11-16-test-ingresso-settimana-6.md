# Test d'ingresso – Settimana 6 (strumenti essenziali)

> Rispondere **senza cercare** e senza provare i comandi. "Non lo so" è una risposta valida.
> Le risposte si danno in chat a Claude; l'esito viene annotato qui sotto e nel resoconto.
> Teoria collegata: [Capitolo 03](../libro/03-shell-strumenti-essenziali.md)

Stato: ✅ corretta · 🟨 parziale / da rivedere · ⬜ da rispondere

## Domande

### Redirezioni e pipe
1. Che differenza c'è tra `comando > file` e `comando >> file`?
   - Verifica: cosa succede con `sort elenco.txt > elenco.txt`?
2. Cosa fa `comando 2> errori.txt`? E `comando > tutto.txt 2>&1`? Cosa sono i numeri `1` e `2`?
   - Verifica: cosa cambia con `comando 2>&1 > tutto.txt`? Cos'è lo `0`?
3. Cosa succede, passo per passo, in `cat /etc/passwd | grep bash | wc -l`? Cosa vedi alla fine?
   - Verifica: cosa fa concretamente `|`? Cosa conta davvero quel numero (pensa a un utente `bashful`)?

### grep ed espressioni regolari
4. Cosa trova `grep '^root' /etc/passwd`? E `grep 'root$'`?
   - Verifica: come conteresti **solo** gli utenti che hanno bash come shell (l'ultimo campo della riga)?

### File e link
5. Che differenza c'è tra un **hard link** e un **link simbolico**? Cosa succede a ciascuno se cancelli il file originale?
6. Cos'è un **inode**?

### Archivi e compressione
7. Hai il file `backup.tar.gz`: cosa indicano `.tar` e `.gz`, e perché sono due cose separate?

### Documentazione e pacchetti
8. Vuoi cambiare la password di un utente ma non ricordi il comando: come lo cerchi **senza internet**?
9. Cosa sono le **sezioni** del manuale (`man 1`, `man 5`, …)? Perché esistono sia `man passwd` sia `man 5 passwd`?
10. Su Rocky Linux, come scopri **quale pacchetto** fornisce un file o un comando che non hai installato?

## Esito

**Test completato il 2026-11-16.** Punti da ripassare: pipe (3), date dell'inode (6), compressione ≠ crittografia (7), hash ≠ cifratura (8), dnf provides (10).

| # | Esito | Note |
|---|---|---|
| 1 | 🟨 | `>`/`>>` giusto. Verifica `sort f > f` sbagliata, spiegata (livello 3) → cap. 03 §3.6. Da verificare con l'esercizio 3 del capitolo |
| 2 | ✅ | Ordine delle redirezioni capito; `2>&1` copia la destinazione, non crea un collegamento |
| 3 | 🟨 | Capito `bashful`. La pipe collega stdout→stdin, trasporta byte e non elabora |
| 4 | ✅ | Dopo l'indizio: `grep 'bash$'` (attenzione: trova anche `rbash`) |
| 5 | ✅ | Dopo la verifica: link count capito (conta i nomi che puntano all'inode; a 0 inode e blocchi segnati liberi, non azzerati). Concetto giusto (stessi dati, nessun "originale"; symlink = percorso, inode diverso, pendente se cancelli il file, segue un nuovo file con lo stesso nome). Da correggere: "memoria" → disco. Manca il contatore dei link: quando i dati vengono liberati |
| 6 | ✅ | Dopo varie verifiche: inode = struttura dati (tipo, permessi, UID/GID, dimensione, link count, blocchi, date); il nome sta nella directory. Date atime/mtime/ctime/btime trovate con `stat`; capito che modificare il contenuto aggiorna anche la ctime. Errore: pensava che `>>` aggiornasse la atime |
| 7 | ✅ | Dopo la verifica. Errori corretti: compressione ≠ crittografia; gli archivi usano sempre compressione lossless; tar copia i metadati ma non gli inode (all'estrazione vengono creati inode nuovi) |
| 8 | ✅ | `apropos` trovato da solo. Dopo le verifiche: `chpasswd` serve per molti utenti da stdin, il comando giusto è `passwd`; `/etc/shadow` contiene hash (non password cifrate), quindi non si modifica a mano |
| 9 | ✅ | Sezioni 1–8 corrette dopo la verifica (3 = funzioni di libreria, non "chiamate"); `whatis`; l'ordine di ricerca sta in `/etc/man_db.conf` (non è numerico). Trovati in `man man`, dopo un indizio: `-S` e `MANSECT` (non `-M`/`MANPATH`, che riguardano le directory) |
| 10 | ✅ | `dnf provides` trovato con gli indizi (prima `--location`, poi `info`). Costruito da solo il percorso `/usr/share/man/man7/inode.7.gz`; installato `man-pages` |
