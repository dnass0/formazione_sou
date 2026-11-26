# Capitolo 07 – Gestione dei pacchetti: rpm, dnf, repository

> Capitolo **in corso**: per ora contiene solo le basi emerse dal test d'ingresso della settimana 6. Verrà completato quando affronteremo l'argomento.

## Obiettivi

Alla fine del capitolo (per ora) saprai:

- spiegare cos'è un **pacchetto** e cos'è un **repository**;
- leggere il nome completo di un pacchetto (nome, versione, release, architettura);
- scoprire **quale pacchetto** fornisce un file o un comando, anche se non è installato;
- leggere i file `.repo` e distinguere i repository abilitati da quelli disabilitati;
- aggiungere un repository esterno (EPEL) e capire cosa è cambiato;
- leggere l'output di `dnf install`: dipendenze, dipendenze deboli, aggiornamenti, fasi della transazione.

## Prerequisiti

- Capitolo 03, paragrafo 7 (documentazione locale).
- Capitolo 04 (file e percorsi).

---

## Teoria

### 1. Pacchetti e repository

Un **pacchetto** è un archivio che contiene i file di un programma (eseguibili, librerie, file di configurazione, documentazione), più le **informazioni** per installarlo: nome, versione, dipendenze (gli altri pacchetti di cui ha bisogno) e l'elenco dei file che installa. Su Rocky Linux e RHEL i pacchetti sono in formato **RPM**.

Un **repository** è un server (o una directory) che raccoglie pacchetti e li mette a disposizione. Su Rocky i principali sono `baseos` (il sistema di base) e `appstream` (applicazioni e strumenti aggiuntivi).

**`dnf`** è il programma che scarica i pacchetti dai repository, risolve le dipendenze, li installa, li aggiorna e li rimuove. Installare o rimuovere pacchetti modifica il sistema, quindi richiede i privilegi di root.

### 2. Il nome completo di un pacchetto

```
man-pages-6.04-10.el9_8.noarch
```

| Parte | Esempio | Significato |
|---|---|---|
| Nome | `man-pages` | il nome del pacchetto, quello che usi con `dnf install` |
| Versione | `6.04` | la versione del software, decisa da chi lo sviluppa |
| Release | `10.el9_8` | quante volte la distribuzione ha ricostruito il pacchetto; `el9_8` = *Enterprise Linux 9.8* |
| Architettura | `noarch` | il tipo di processore: `x86_64` per i programmi compilati, `noarch` per pacchetti che contengono solo testo o script |

A volte prima della versione compare un numero seguito da due punti, come in `libpcap-14:1.10.0-4.el9_9.2.x86_64`. È l'**epoch** (inglese, «epoca»): un contatore che vince su tutto il resto nel confronto fra versioni. Serve quando chi sviluppa cambia schema di numerazione (per esempio da `2024.1` a `1.0`) e il nuovo numero sembrerebbe *più vecchio*: alzando l'epoch, `dnf` sa comunque che è più recente. Quando manca vale 0. Per esteso il nome si chiama **NEVRA**: *Name, Epoch, Version, Release, Architecture*.

### 3. I metadati dei repository e la cache

Oltre ai pacchetti, ogni repository pubblica un **catalogo** (i **metadati**) che descrive tutto quello che contiene: nomi, versioni, dipendenze e **l'elenco completo dei file** di ogni pacchetto.

`dnf` scarica questi cataloghi e li conserva in una **cache** sul disco, in `/var/cache/dnf`. Per questo a volte, prima di rispondere, `dnf` mostra righe di download o la data dell'ultima verifica dei metadati.

### 4. Quale pacchetto fornisce un file: `dnf provides`

Il sotto-comando **`provides`** (alias `whatprovides`, abbreviabile in `prov`) cerca un file nei metadati di **tutti** i pacchetti, installati e non. È il catalogo della biblioteca: ti dice in quale libro sta un capitolo anche se quel libro non lo hai a casa.

L'argomento è il **percorso del file**. Se non conosci il percorso esatto puoi usare caratteri jolly, ma devi metterli **tra apici singoli**: senza apici, `*` verrebbe interpretato dalla **shell**, che cercherebbe file corrispondenti sul **tuo** disco prima ancora di lanciare `dnf`.

**Esempio reale:** sulla VM `man 7 inode` diceva che la pagina non esisteva. Sapendo che le pagine stanno in `/usr/share/man/manN/nome.N.gz` (capitolo 03, paragrafo 7.3), si cerca chi fornisce `/usr/share/man/man7/inode.7.gz`. Output:

```
man-pages-6.04-9.el9_7.noarch : Linux kernel and C library user-space interface
                              : documentation
Repo         : baseos
Corrispondenza trovata in:
Nome file   : /usr/share/man/man7/inode.7.gz

man-pages-6.04-10.el9_8.noarch : Linux kernel and C library user-space interface
                               : documentation
Repo         : @System
...
```

- Ogni blocco è un pacchetto che contiene quel file.
- `Repo : baseos`: il pacchetto è disponibile nel repository `baseos`. Compare con due release diverse, perché il repository ne conserva più versioni.
- `Repo : @System`: il pacchetto è **già installato** su questo sistema.
- `Nome file`: il file trovato dentro il pacchetto.

### 5. I file `.repo`: quali repository consulta `dnf`

`dnf` sa quali repository esistono leggendo i file **`/etc/yum.repos.d/*.repo`** (il nome `yum` è rimasto dal predecessore di `dnf`). Ogni file contiene una o più **sezioni**, una per repository, che iniziano con l'**id** tra parentesi quadre:

```
[baseos]
name=Rocky Linux $releasever - BaseOS
...
enabled=1
```

Due cose da non confondere:

- **file ≠ repository.** Sulla VM, prima di EPEL, c'erano 5 file ma `dnf repolist` mostrava 4 repository: un file può descriverne diversi, e molti sono disabilitati.
- **`enabled=1` / `enabled=0`** decide se `dnf` consulta quel repository. `dnf repolist` mostra solo quelli abilitati (`dnf repolist --all` anche gli altri).

Per vedere solo id e stato:

```sh
grep -E '^\[|^enabled' /etc/yum.repos.d/rocky.repo
```

(`^` = inizio riga, `|` = oppure, `-E` = regex estese; con più file `grep` antepone `nomefile:` a ogni riga, `-h` lo toglie.)

I repository di Rocky 9:

| Id | Contenuto | Di default |
|---|---|---|
| `baseos` | Il sistema di base | abilitato |
| `appstream` | Applicazioni, linguaggi, strumenti | abilitato |
| `extras` | Pacchetti in più curati da Rocky (es. `epel-release`) | abilitato |
| `crb` | *CodeReady Builder*: librerie e strumenti di sviluppo, spesso dipendenze di EPEL | **disabilitato** |

Molti repository hanno anche le varianti **`-debuginfo`** (i simboli di debug, che collegano il binario alle righe del sorgente, per analizzare un crash) e **`-source`** (i sorgenti, pacchetti SRPM): sono disabilitati, perché su un sistema normale non servono.

### 6. Aggiungere un repository: EPEL

**EPEL** (*Extra Packages for Enterprise Linux*) è un repository curato dal progetto Fedora con pacchetti che RHEL e Rocky non forniscono (per esempio `ShellCheck`, `dash`).

Cosa succede, verificato sulla VM il 26/11/2026:

1. Prima: `sudo dnf install ShellCheck` → `Nessuna corrispondenza per l'argomento: ShellCheck`. `dnf` ha cercato nei metadati dei repository abilitati (in cache: «Ultima verifica della scadenza dei metadati: 2:36:33 fa») e non l'ha trovato.
2. `sudo dnf install epel-release` (dal repository `extras`). Il pacchetto non contiene programmi: contiene **configurazione**, cioè tre file `.repo` (`epel.repo`, `epel-testing.repo`, `epel-cisco-openh264.repo`) e le chiavi per verificare le firme. Il nome del pacchetto non coincide con i nomi dei file: per vedere cosa ha installato, `rpm -ql epel-release` (*query, list*).
3. Dopo: `dnf repolist` passa da 4 a 6 repository: `epel` ed `epel-cisco-openh264`, gli unici con `enabled=1` nei nuovi file. `epel-testing` (pacchetti non ancora dichiarati stabili) resta disabilitato.

**Perché un repository di Cisco?** OpenH264 è un **codec** (*coder-decoder*) per il formato video H.264, coperto da brevetti. Cisco paga i diritti, ma solo per i binari che compila e distribuisce **dai propri server**: per questo Fedora non può ospitarlo e il file `.repo` punta a Cisco.

### 7. Leggere l'output di `dnf install`

`dnf` calcola prima una **transazione**: l'insieme di tutte le operazioni necessarie, che vengono applicate tutte o nessuna. Il riepilogo prima della conferma la divide in sezioni:

| Sezione | Cosa contiene |
|---|---|
| `Installazione` | I pacchetti chiesti e non ancora presenti |
| `Aggiornamento` | Pacchetti chiesti già presenti ma in versione più vecchia: `dnf install` li porta all'ultima versione |
| `Installazione delle dipendenze` | Pacchetti **richiesti** (campo `Requires:` dell'RPM): senza, il programma non funziona |
| `Installazione delle dipendenze deboli` | Pacchetti **raccomandati** (`Recommends:`): utili ma non indispensabili. Si escludono con `--setopt=install_weak_deps=False` |

I pacchetti già presenti all'ultima versione vengono saltati («è già installato»).

**Esempio reale (26/11/2026).** Chiesti 18 pacchetti per le lezioni di scripting. Risultato:

- **7 installati** fra quelli chiesti (`ShellCheck`, `dash`, `zsh`, `bc`, `bash-completion`, `lsof`, `nmap-ncat`);
- **3 dipendenze**: `libpcap` (cattura di pacchetti di rete, per `ncat`), `libibverbs` (richiesta da `libpcap`), `libtirpc` (*Transport-Independent RPC*, per `lsof`);
- **3 aggiornati**: `jq` e `vim-enhanced` più la sua dipendenza `vim-common`, da `el9_8` a `el9_9` (la VM aveva pacchetti di Rocky 9.8, i repository ormai quelli di 9.9);
- gli altri 9 erano già installati.

Le fasi della transazione, nell'ordine in cui compaiono:

1. **Test di transazione:** prova a tavolino (conflitti fra file, spazio su disco) senza toccare niente.
2. **Preparazione.**
3. **Installing / Upgrading:** i file del pacchetto vengono scritti sul disco. Il contatore `N/16` conta le operazioni, non i pacchetti.
4. **Esecuzione scriptlet:** gli **scriptlet** sono piccoli script di shell contenuti nell'RPM, eseguiti prima o dopo l'installazione o la rimozione (per esempio per registrare qualcosa in un file di sistema). Si leggono con `rpm -q --scripts nome`.

   **Esempio reale: gli scriptlet di `dash`.**

   ```
   postinstall scriptlet (using /bin/sh):
   grep -q '^/bin/dash$' /etc/shells || \
       echo '/bin/dash' >> /etc/shells
   postuninstall scriptlet (using /bin/sh):
   if [ $1 -eq 0 ]; then
       sed -i '/^\/bin\/dash$/d' /etc/shells
   fi
   ```

   - `/etc/shells` (`man 5 shells`) è l'elenco delle **shell di login valide**. La shell di login è quella scritta nell'ultimo campo della riga dell'utente in `/etc/passwd`, che parte quando l'utente entra. L'elenco lo leggono `chsh` (un utente normale può scegliere solo shell elencate) e alcuni servizi che rifiutano l'accesso a chi ha una shell non elencata. Per *eseguire* `dash` non serve: serve per poterla usare **come shell di login**.
   - **Dopo l'installazione:** `grep -q` cerca la riga esatta `/bin/dash` (`^` inizio, `$` fine riga) senza stampare niente (*quiet*). `||` esegue il comando a destra solo se quello a sinistra fallisce: la riga si aggiunge (`>>` accoda, non sovrascrive) **solo se manca**. Rilanciato più volte, lo script lascia il file nello stesso stato: è **idempotente**.
   - **Dopo la rimozione:** `$1` è il numero di versioni del pacchetto che restano installate. In un aggiornamento la nuova versione è già al suo posto, quindi `$1` vale 1 e la riga resta. Solo con una rimozione vera vale 0, e `sed -i` (*in place*) cancella (`d`) la riga. Le `/` del percorso sono precedute da `\` perché `/` delimita l'indirizzo di `sed`.
5. **Pulizia:** negli aggiornamenti, la rimozione dei file della **versione vecchia** (per questo 13 pacchetti scritti + 3 pulizie = 16 operazioni).
6. **Verifica:** controlla che nel database RPM tutto risulti come previsto.

---

## Comandi e file di riferimento

| Comando / file | A cosa serve | Documentazione |
|---|---|---|
| `dnf provides` | Quale pacchetto contiene un file | `man dnf`, sezione dei comandi |
| `dnf install` | Installa un pacchetto | `man dnf` |
| `dnf info` | Informazioni su un pacchetto di cui conosci il nome | `man dnf` |
| `/var/cache/dnf` | Cache dei metadati dei repository | — |
| `/etc/yum.repos.d/*.repo` | Definizione dei repository (id, indirizzo, `enabled`) | `man dnf.conf` |
| `dnf repolist [--all]` | Repository abilitati (o tutti) | `man dnf` |
| `rpm -ql pacchetto` | File installati da un pacchetto | `man rpm` |
| `rpm -q --scripts pacchetto` | Scriptlet di un pacchetto | `man rpm` |
| `dnf list installed nome` | Pacchetto installato e repository di provenienza | `man dnf` |

## Errori comuni e troubleshooting

- **Passare a `dnf provides` solo una parola** invece di un percorso: per i file serve il percorso, o un pattern con caratteri jolly.
- **Caratteri jolly senza apici:** li interpreta la shell sul disco locale.
- **Confondere `dnf info` e `dnf provides`:** `info` parte dal nome del pacchetto, `provides` parte dal file.
- **`Nessuna corrispondenza per l'argomento`:** il pacchetto non è in nessun repository **abilitato**. Prima di pensare a un errore di battitura, chiediti in quale repository sta (EPEL? CRB disabilitato?).
- **Confondere il nome del pacchetto con i nomi dei file che installa** (`epel-release` → `epel.repo`…): si controlla con `rpm -ql`.
- **Usare root anche per consultare:** `dnf provides`, `man` e `ls` non ne hanno bisogno; root serve per installare.

## Collegamento con l'esame EX200

Obiettivo *"Deploy, configure, and maintain systems"*: *Install and update software packages from Red Hat Network, a remote repository, or from the local file system*.

## Esercizi

1. Scopri quale pacchetto fornisce il comando `semanage`, che userai con SELinux. È installato sulla tua VM?
2. Scopri quale pacchetto fornisce la pagina di manuale `hier` della sezione 7, usando un pattern con caratteri jolly invece del percorso esatto.
3. Prova lo stesso pattern dell'esercizio 2 senza apici, da una directory in cui esiste un file con un nome che corrisponde. Cosa cambia e perché?
4. Elenca tutti i repository definiti sulla VM, anche quelli disabilitati. Quanti sono `-debuginfo`?
5. Da quale repository è arrivato `ShellCheck`? E `bash`? Trova un comando che te lo dica senza aprire file di log.
6. Leggi gli scriptlet del pacchetto `dash` e spiega, riga per riga, cosa fanno.

## Domande di autoverifica

1. Cosa contengono i metadati di un repository?
2. Come fa `dnf provides` a trovare un file che non è sul tuo disco?
3. Cosa succederebbe a `dnf provides` se la VM non raggiungesse i repository e la cache fosse vuota?
4. Cosa indica `noarch`? Perché un pacchetto di sole pagine di manuale è `noarch`?
5. Cosa significa `@System` nell'output di `dnf`?
6. Perché il numero di file in `/etc/yum.repos.d/` non coincide con il numero di righe di `dnf repolist`?
7. Il pacchetto `epel-release` contiene programmi? Cosa cambia nel sistema quando lo installi?
8. Che differenza c'è fra una dipendenza e una dipendenza debole? Quando vorresti escludere le seconde?
9. Perché in un aggiornamento compare una fase di «Pulizia»?
10. A cosa serve l'epoch in `libpcap-14:1.10.0-4.el9_9.2`?

## Fonti

- `man dnf`, `man dnf.conf`, `man rpm`
- Documentazione Rocky Linux (libri dell'Academy): gestione dei pacchetti

## Cronologia

- 2026-11-16: capitolo iniziato dal test d'ingresso della settimana 6 (domanda 10): pacchetti e repository, nome completo di un pacchetto, metadati e cache, `dnf provides` con l'esempio reale di `man-pages`.
- 2026-11-26: preparando la VM per le lezioni di scripting: file `.repo` e repository abilitati, EPEL (e il repository di Cisco per OpenH264), epoch e NEVRA, lettura dell'output di `dnf install` (dipendenze, dipendenze deboli, aggiornamenti, fasi della transazione, scriptlet).
