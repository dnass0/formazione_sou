# Capitolo 03 – La shell e gli strumenti essenziali

## Obiettivi

Alla fine del capitolo saprai:

- spiegare cosa sono i **file descriptor** e perché ogni processo ne ha almeno tre;
- usare le redirezioni (`>`, `>>`, `<`, `2>`, `2>&1`) e prevedere **dove finisce** ogni flusso, anche quando l'ordine delle redirezioni cambia;
- spiegare cosa fa il kernel quando colleghi due comandi con una pipe (`|`);
- usare `grep` con le àncore `^` e `$` per cercare in modo preciso;
- spiegare la differenza tra **archiviare** e **comprimere**, e perché `tar` e `gzip` sono strumenti separati;
- trovare un comando o un'informazione **senza internet**, usando `man`, le sue sezioni, `apropos` e `whatis`.

## Prerequisiti

- Saper aprire un terminale e lanciare un comando.
- Sapere cos'è un file e cos'è una directory (capitolo 04, anche solo a grandi linee).

---

## Teoria

### 1. Cos'è la shell

La **shell** (su Rocky Linux di solito `bash`) è un programma come un altro: legge quello che scrivi, lo interpreta e chiede al kernel di eseguire i comandi.

Quando scrivi `ls -l` e premi Invio, succede questo:

1. la shell divide la riga in parole (`ls` e `-l`);
2. cerca il programma `ls` nelle directory elencate nella variabile `PATH`;
3. crea un nuovo **processo** figlio (la system call `fork()` crea una copia della shell);
4. nel figlio, sostituisce il programma della shell con quello di `ls` (system call `execve()`);
5. aspetta che il figlio finisca e ne legge il **codice di uscita** (exit code).

Tra il punto 3 e il punto 4 la shell ha l'occasione di **preparare l'ambiente** del figlio. È proprio lì che avvengono le redirezioni: il comando non sa nulla di `>` o di `|`, se ne occupa la shell prima di lanciarlo.

> **Termine – System call:** la richiesta che un programma fa al kernel per ottenere un servizio che non può fare da solo (aprire un file, creare un processo, leggere dalla rete…).

### 2. I file descriptor

Un programma non legge e non scrive "direttamente" su un file o sullo schermo. Chiede al kernel di aprire una risorsa, e il kernel gli restituisce un **numero intero**: il **file descriptor** (fd). Da quel momento il programma dice "scrivi questi byte sull'fd 3", e il kernel sa a cosa corrisponde il 3.

Ogni processo ha una propria **tabella dei file descriptor**. Per convenzione, i primi tre sono sempre questi:

| fd | Nome | Simbolo in C | A cosa serve |
|---|---|---|---|
| 0 | standard input | `stdin` | da dove il programma **legge** i dati in ingresso |
| 1 | standard output | `stdout` | dove scrive l'**output normale** |
| 2 | standard error | `stderr` | dove scrive **errori e diagnostica** |

In una shell interattiva tutti e tre puntano al **terminale**: lo 0 alla tastiera (in realtà al dispositivo del terminale), l'1 e il 2 allo schermo. Ecco perché, di default, output ed errori compaiono mescolati sullo stesso schermo: sono due canali separati che arrivano nello stesso posto.

Un processo figlio **eredita** i file descriptor del padre. Quindi `ls`, lanciato dalla shell, si ritrova già gli fd 0, 1 e 2 collegati al terminale.

Puoi vederlo con i tuoi occhi su Linux:

```bash
ls -l /proc/$$/fd
```

- `$$` è il PID (numero di processo) della shell corrente.
- `/proc/<PID>/fd/` è una directory virtuale creata dal kernel che mostra la tabella degli fd di quel processo.

Output tipico:

```
lrwx------. 1 dnasso dnasso 64 ... 0 -> /dev/pts/0
lrwx------. 1 dnasso dnasso 64 ... 1 -> /dev/pts/0
lrwx------. 1 dnasso dnasso 64 ... 2 -> /dev/pts/0
```

- `0`, `1`, `2` sono i file descriptor.
- `/dev/pts/0` è il **terminale** (uno pseudo-terminale, per esempio la tua sessione SSH).

Tutti e tre puntano allo stesso terminale.

Altri dettagli che vedrai:

- **`/proc`** è un **file system virtuale**: non sta sul disco, lo genera il kernel al momento in cui lo leggi. Ogni processo ha la sua directory `/proc/<PID>/`.
- **`/dev/pts/N`** è uno **pseudo-terminale** (*pseudo-terminal slave*): un terminale "finto" che il kernel crea per ogni sessione SSH o finestra di terminale. Il numero cambia da sessione a sessione.
- Nella shell compare spesso anche un **fd 255** che punta al terminale: è una copia che `bash` tiene per uso proprio, così può parlare con il terminale anche se tu redirigi 0, 1 o 2.
- Accanto a `fd/` c'è **`/proc/<PID>/cwd`**, un link simbolico alla **directory corrente** (*current working directory*) del processo. Cambia con `cd`, e i comandi lanciati dalla shell la ereditano.

> **Directory corrente ≠ file aperto.** Stare dentro una directory significa tenere un riferimento alla **directory**, non ai file che contiene. Un file è "aperto" solo se un processo ha un file descriptor su di esso: è questo che impedisce di liberarne lo spazio quando viene cancellato (capitolo 04, §6.3).

> **Perché due canali di output?** Così puoi separare i dati "buoni" dagli errori: salvare l'output in un file e continuare a vedere gli errori a schermo, o viceversa.

### 3. Le redirezioni

Una redirezione dice alla shell: "prima di lanciare il comando, fai puntare questo file descriptor da un'altra parte".

#### 3.1 Output su file: `>` e `>>`

```bash
comando > file      # equivale a: comando 1> file
comando >> file     # equivale a: comando 1>> file
```

- `>` apre `file` in scrittura; se non esiste lo **crea**, se esiste lo **svuota** (tronca a zero byte). Poi collega l'fd 1 a quel file.
- `>>` apre `file` in modalità **append**: se non esiste lo crea, se esiste scrive in fondo senza toccare il contenuto precedente.

**Importante:** la shell apre (e con `>` svuota) il file **prima** di eseguire il comando. Tienilo a mente per l'esercizio 3.

#### 3.2 Errori su file: `2>`

```bash
comando 2> errori.txt
```

Il numero prima di `>` indica **quale** file descriptor redirigere. `2>` collega lo stderr al file; lo stdout resta sul terminale.

Un uso frequentissimo è buttare via gli errori:

```bash
find / -name passwd 2> /dev/null
```

`/dev/null` è un file speciale che accetta qualunque scrittura e la scarta.

> **Attenzione allo spazio:** `2> file` e `2 > file` sono cose diverse. Nel secondo caso il `2` diventa un **argomento** del comando e viene rediretto lo stdout. Il numero deve stare attaccato al `>`.

#### 3.3 Input da file: `<`

```bash
comando < file
```

Collega l'fd 0 (stdin) al file: il comando legge dal file come se tu stessi digitando quel contenuto. Lo stdin, quindi, **non è "la tastiera"**: è *da dove* il programma legge, e di default questo è il terminale.

#### 3.4 Duplicare un descrittore: `2>&1`

```bash
comando > tutto.txt 2>&1
```

`2>&1` significa: "fai puntare l'fd 2 **allo stesso posto a cui punta l'fd 1 in questo momento**".

È una **copia della destinazione**, non un collegamento permanente tra i due descrittori. Dietro c'è la system call `dup2(1, 2)`.

#### 3.5 L'ordine conta: da sinistra a destra

La shell applica le redirezioni **una alla volta, da sinistra a destra**. Segui la tabella degli fd passo per passo.

**Caso A – `comando > tutto.txt 2>&1`**

| Passo | fd 1 | fd 2 |
|---|---|---|
| inizio | terminale | terminale |
| `> tutto.txt` | **tutto.txt** | terminale |
| `2>&1` (copia dove punta l'1 *adesso*) | tutto.txt | **tutto.txt** |

Risultato: output **ed** errori nel file.

**Caso B – `comando 2>&1 > tutto.txt`**

| Passo | fd 1 | fd 2 |
|---|---|---|
| inizio | terminale | terminale |
| `2>&1` (copia dove punta l'1 *adesso*) | terminale | **terminale** |
| `> tutto.txt` | **tutto.txt** | terminale |

Risultato: l'output va nel file, gli errori **restano a schermo**.

In bash esiste anche una scorciatoia per il caso A: `comando &> tutto.txt`.

#### 3.6 Trappola: leggere e scrivere lo stesso file

```bash
sort elenco.txt > elenco.txt
```

Sembra voler dire "ordina il file e salva il risultato al suo posto", ma il risultato è un **file vuoto**, e il contenuto originale è perso. Segui l'ordine degli eventi:

1. La shell legge la riga e trova la redirezione `> elenco.txt`.
2. **Prima di lanciare `sort`**, la shell apre `elenco.txt` in scrittura con troncamento (nella system call `open()` c'è l'opzione `O_TRUNC`). Il file viene svuotato **adesso**: 0 byte.
3. La shell lancia `sort`, con lo stdout già collegato a `elenco.txt`.
4. `sort` apre `elenco.txt` per leggerlo e lo trova **vuoto**.
5. `sort` ordina zero righe, non scrive niente e termina. Il file resta vuoto.

Il problema non è `sort`: è che la shell prepara le redirezioni **prima** che il comando parta. Vale per qualunque comando che legge e scrive lo stesso file: `grep`, `tr`, `sed`, `cut`…

Come ottenere davvero il risultato voluto:

- **File temporaneo**, il metodo che funziona con qualunque comando:
  ```bash
  sort elenco.txt > elenco.tmp && mv elenco.tmp elenco.txt
  ```
  `&&` esegue `mv` **solo se** `sort` è terminato con successo (exit code 0), così in caso di errore non sovrascrivi l'originale.
- **Opzione specifica di `sort`:** `sort -o elenco.txt elenco.txt`. `sort` legge **tutto** l'input prima di aprire il file di output, quindi qui è sicuro (vedi `man sort`, opzione `-o`). Non è una regola generale: pochi comandi hanno un'opzione simile.

Anche `>>` non risolve il problema: `cat file >> file` aggiungerebbe il file a sé stesso all'infinito. GNU `cat` se ne accorge e si rifiuta con l'errore *input file is output file*.

### 4. La pipe `|`

```bash
cat /etc/passwd | grep bash | wc -l
```

La pipe collega lo **stdout** del comando a sinistra allo **stdin** del comando a destra. Ecco cosa succede davvero:

1. **Il canale.** Per ogni `|` la shell chiede al kernel di creare una pipe (system call `pipe()`). Una pipe è un piccolo **buffer in memoria del kernel** (su Linux 64 KiB di default) con due estremità: una per scrivere e una per leggere.
2. **I processi.** La shell crea un processo per ogni comando. **Tutti partono insieme**: non aspetta che `cat` finisca per lanciare `grep`.
3. **I collegamenti.**
   - L'fd 1 di `cat` viene collegato all'estremità di scrittura della prima pipe.
   - L'fd 0 di `grep` viene collegato all'estremità di lettura della prima pipe, e il suo fd 1 alla scrittura della seconda.
   - L'fd 0 di `wc` viene collegato alla lettura della seconda pipe; il suo fd 1 resta il terminale.
4. **Il flusso.** `cat` scrive byte nella pipe e `grep` li legge man mano.
   - Se la pipe è **vuota**, chi legge si mette in attesa.
   - Se è **piena**, chi scrive si mette in attesa.

   Il kernel fa da "nastro trasportatore" e sincronizza i processi.
5. **La fine.** Quando `cat` termina e chiude la sua estremità di scrittura, `grep` riceve **EOF** (End Of File, "non arriverà più niente"). Finisce, chiude a sua volta, e `wc` riceve EOF, stampa il conteggio ed esce.

Alcune precisazioni importanti:

- **La pipe trasporta byte, non righe.** Sono i programmi come `grep` e `wc -l` che ragionano "per righe", cercando il carattere di a capo (`\n`).
- **La pipe non elabora nulla.** Trasporta i dati e basta; l'elaborazione la fanno i comandi.
- **Nella pipe passa solo lo stdout.** Lo stderr di `cat` va ancora sul terminale. Per mandare nella pipe anche gli errori: `comando 2>&1 | altro` (oppure, in bash, `comando |& altro`).

> **Nota di stile:** `cat file | grep testo` funziona, ma `cat` qui è superfluo: `grep testo file` legge il file da solo. In più, `grep -c` conta le righe senza bisogno di `wc -l`.

### 5. `grep` e le prime espressioni regolari

`grep` legge il testo **riga per riga** e stampa le righe che contengono una corrispondenza con il **pattern** (modello) che gli dai.

#### 5.1 La ricerca è "contenuta in", non "uguale a"

`grep bash` stampa ogni riga che contiene la sequenza di caratteri `bash` **in qualunque punto**: all'inizio, in mezzo, in un nome utente come `bashful`, in un commento…

Per cercare in modo preciso servono le **espressioni regolari**.

> **Termine – Espressione regolare (regex):** una stringa che descrive un *insieme* di testi possibili, usando caratteri normali e caratteri speciali (metacaratteri).

#### 5.2 Le àncore `^` e `$`

Le àncore non corrispondono a un carattere, ma a una **posizione** nella riga:

| Àncora | Posizione | Esempio | Trova le righe che… |
|---|---|---|---|
| `^` | inizio riga | `grep '^root'` | **iniziano** con `root` |
| `$` | fine riga | `grep 'root$'` | **finiscono** con `root` |
| `^…$` | tutta la riga | `grep '^root$'` | sono **esattamente** `root` |

Le àncore lavorano sui **caratteri**, non sulle parole: `grep 'root$'` trova anche una riga che finisce con `chroot`.

**Perché le virgolette singole?** Alcuni caratteri (`$`, `*`, `?`…) hanno un significato speciale anche **per la shell**. Le virgolette singole dicono alla shell "non toccare niente, passa il testo così com'è a `grep`".

### 6. Archivi e compressione

Un file come `backup.tar.gz` è il risultato di **due operazioni diverse**, fatte da due programmi diversi.

#### 6.1 Archiviare: `tar`

**Archiviare** vuol dire mettere molti file dentro **uno solo**. `tar` (da *tape archive*, archivio su nastro) nasce per scrivere su nastri magnetici, che si leggono solo in sequenza. Per questo un archivio tar è **un unico flusso di byte** in cui i file sono messi uno dopo l'altro:

```
[intestazione file 1: nome, tipo, permessi, proprietario, date…][contenuto file 1]
[intestazione file 2: …][contenuto file 2]
…
```

`tar` **non comprime**: un archivio tar è grande più o meno quanto la somma dei file.

Nell'intestazione `tar` salva il **percorso** del file e una **copia dei metadati** dell'inode (capitolo 04): tipo, permessi, proprietario, gruppo, mtime, destinazione dei link simbolici. **Non** salva gli inode veri e propri: quando estrai l'archivio, il file system crea **inode nuovi**, con numeri nuovi, e ci scrive dentro i metadati copiati. Non potrebbe fare altrimenti, perché i numeri di inode sono **locali a ogni file system** e sulla destinazione quei numeri potrebbero essere già usati.

> **Per l'EX200:** alcuni metadati "speciali", come i contesti **SELinux** e le **ACL**, `tar` li salva solo se glielo chiedi esplicitamente (`man tar`). Li vedremo nei capitoli 05 e 24.

#### 6.2 Comprimere: `gzip`, `bzip2`, `xz`, `zstd`

**Comprimere** vuol dire rendere un file **più piccolo** eliminando le **ripetizioni**. Un esempio semplificato: invece di `AAAAAAAAAA` (10 byte) scrivo "10 volte A". Gli algoritmi veri cercano sequenze di byte che si ripetono e le sostituiscono con riferimenti più corti.

Un compressore lavora su **un solo flusso di byte**, cioè un file. Non sa cosa siano una directory o un elenco di file: per questo prima serve `tar`.

> **Compressione ≠ crittografia.** La **crittografia** (cifratura) rende i dati **illeggibili** senza una chiave e non riduce la dimensione. La compressione riduce la dimensione e non protegge niente: chiunque può decomprimere un `.gz`.

Esistono due tipi di compressione:
- **lossless** (senza perdita): decomprimendo si ottengono **esattamente** i byte originali. gzip, bzip2, xz e zstd sono tutti di questo tipo;
- **lossy** (con perdita): butta via dettagli che occhio e orecchio non notano. È il caso di JPEG e MP3.

Per archivi, backup, programmi e file di configurazione si usa **sempre** compressione lossless: in un eseguibile o in un file di configurazione basta un byte diverso per renderlo inutilizzabile.

#### 6.3 Perché due strumenti separati

È un principio della **filosofia Unix**: *ogni programma fa una cosa sola e la fa bene, e i programmi si combinano tra loro*. È lo stesso principio della pipe (paragrafo 4).

`tar` non deve sapere niente di compressione e i compressori non devono sapere niente di file e directory. Così, quando nasce un algoritmo migliore, lo si usa con `tar` senza cambiare `tar`. Per questo esistono `.tar.gz`, `.tar.bz2`, `.tar.xz` e `.tar.zst`: l'archivio è lo stesso, cambia solo il compressore.

> **Le estensioni sono solo una convenzione nel nome.** Linux non le usa per decidere cosa sia un file. Il comando `file` riconosce il tipo leggendo i primi byte del contenuto, le cosiddette **firme** (*magic number*): ad esempio un JPEG inizia con `FF D8 FF`. È lo stesso principio del *file carving* (capitolo 04, paragrafo 6.4).

### 7. La documentazione locale

All'esame EX200 non c'è internet: c'è solo la documentazione installata sul sistema. Saperla consultare velocemente è una competenza d'esame a tutti gli effetti.

#### 7.1 Le sezioni del manuale

Le pagine di `man` sono divise in **sezioni** numerate:

| Sezione | Contenuto | Esempi |
|---|---|---|
| 1 | Comandi per tutti gli utenti | `ls`, `passwd`, `stat` |
| 2 | **Chiamate di sistema**: richieste al kernel | `open`, `link`, `unlink` |
| 3 | **Funzioni di libreria**: funzioni già pronte usate dai programmi (es. la libreria standard del C), che spesso usano le chiamate di sistema | `printf` |
| 4 | File speciali, cioè i dispositivi in `/dev` | `null` |
| 5 | Formati dei file e convenzioni | `passwd`, `fstab` |
| 6 | Giochi | |
| 7 | Concetti e argomenti vari | `inode`, `regex`, `hier` |
| 8 | Comandi di **amministrazione del sistema**, di norma per root. **La più usata all'EX200** | `useradd`, `mount`, `fdisk` |
| 9 | Funzioni interne del kernel | |

Lo stesso nome può esistere in più sezioni: `passwd(1)` è il **comando** che cambia la password, `passwd(5)` descrive il **formato del file** `/etc/passwd`. La notazione `nome(N)` indica la pagina `nome` della sezione `N`.

#### 7.2 Quale pagina apre `man` senza numero

Con `man passwd`, senza numero, `man` cerca nelle sezioni seguendo un **ordine di ricerca** e apre la prima pagina che trova. L'ordine **non è numerico**: è scritto nella riga `SECTION` di **`/etc/man_db.conf`**, e quello predefinito è

```
1 n l 8 3 0 2 5 4 9 6 7
```

(la sezione 8 viene prima della 2, per esempio). Quel file vale per tutti gli utenti, ma l'ordine si può scavalcare:
1. indicando la sezione: `man 5 passwd`;
2. per un solo comando, con l'opzione `-S` (`--sections`);
3. per il proprio utente, con la **variabile d'ambiente** `MANSECT`, che contiene le sezioni separate da `:`.

> **Termine – Variabile d'ambiente:** un valore che la shell passa ai programmi che lancia, e che i programmi leggono per modificare il loro comportamento. `PATH` è la più famosa. Il nome si scrive senza `$`; il `$` serve per **leggerne** il valore (`echo $PATH`). Come si impostano e come si rendono permanenti: capitolo 09.

Da non confondere con `MANPATH` (e l'opzione `-M`), che indica **in quali directory** cercare le pagine, non l'ordine delle sezioni. Funziona come `PATH`, che indica alla shell in quali directory cercare i comandi.

> **Consiglio d'esame:** quasi ogni man page ha le sezioni **ENVIRONMENT** e **FILES**, che dicono cosa influenza il comportamento del comando, e la sezione **SEE ALSO**, che porta ai comandi collegati. Dentro `man` si cerca con `/parola`, e `n` passa al risultato successivo.

#### 7.3 Dove stanno le pagine

Le pagine sono file in `/usr/share/man/manN/`, compressi con gzip: ad esempio `/usr/share/man/man5/passwd.5.gz`. Non è un archivio (non c'è `.tar`), è **un solo file compresso**, che `man` decomprime al volo.

Le pagine **non arrivano tutte insieme**: le installa ogni pacchetto. Le pagine delle sezioni 2, 3, 5 e 7 di base stanno nel pacchetto `man-pages`, che su un'installazione minimale può mancare. In quel caso `man 7 inode` risponde che la pagina non esiste. Come scoprire quale pacchetto fornisce un file: capitolo 07.

#### 7.4 Cercare quando non sai il nome: `apropos` e `whatis`

- **`apropos parola`** (equivalente a `man -k`) cerca la parola nelle **descrizioni brevi** di tutte le pagine. È lo strumento per rispondere a "non ricordo il comando che fa X". Attenzione a come combina più parole (`man apropos`).
- **`whatis nome`** (equivalente a `man -f`) mostra in quali sezioni esiste una pagina con **quel nome esatto**, e la sua descrizione breve.

Tutti e due non leggono le pagine ogni volta: consultano un **indice** (un piccolo database) generato periodicamente. Su un sistema appena installato, se l'indice non è ancora stato creato, rispondono *nothing appropriate* anche se le pagine ci sono.

Esempio: cercando come cambiare una password, `apropos` trova sia `chpasswd(8)` sia `passwd(1)`. Leggere la DESCRIPTION chiarisce la differenza: `chpasswd` legge righe `nome:password` dallo **standard input** ed è pensato per aggiornare **molti utenti insieme** (ad esempio da uno script, con una redirezione: paragrafo 3); `passwd` cambia la password di **un** utente in modo interattivo.

**Come cercare bene con `apropos`.** Ogni pagina `man` inizia con una sezione NAME di una sola riga: `nome - descrizione breve`. L'indice contiene solo quelle righe, e `apropos` stampa le righe in cui compare la parola cercata, così:

```
passwd (1)           - update user's authentication tokens
│       │              └── descrizione breve (dalla sezione NAME)
│       └── sezione del manuale
└── nome della pagina
```

Conseguenze pratiche:
1. **Cerca in inglese**, con le parole che userebbe chi ha scritto la descrizione breve: verbi come *resize*, *grow*, *create*, *change*, *list*, e nomi come *filesystem*, *volume*, *user*.
2. La parola viene cercata **come pezzo di testo**, anche dentro parole più lunghe: `ext` trova anche *extend*, *text*, *next*. Più la parola è corta, più risultati inutili.
3. Con **più parole**, di default basta che **una** compaia (risultati che si sommano); esiste un'opzione per richiedere che compaiano **tutte** (esercizio 11).
4. Puoi limitare la ricerca a una **sezione**: i comandi di amministrazione stanno nella sezione **8** (`man apropos`, opzione per la sezione).
5. Puoi filtrare l'output con `grep` (paragrafo 5), visto che è testo che passa in una pipe.
6. Se una ricerca dà troppi risultati, **restringi** (più parole, sezione, `grep`); se non ne dà, **allarga** (sinonimi, parola più generica).

### 8. Elaborare testo a colonne: `awk`

`awk` è un piccolo linguaggio di programmazione pensato per il testo diviso in colonne (file CSV, `/etc/passwd`, output di altri comandi). Su Rocky il comando `awk` è la versione GNU (`gawk`).

#### 8.1 Il modello: record, campi, programma

`awk` legge l'input **una riga alla volta**. Per ogni riga:
1. la chiama **record**; la riga intera è `$0`;
2. la divide in **campi** con un **separatore**: `$1` è il primo campo, `$2` il secondo… Il separatore predefinito sono spazi e tabulazioni; con l'opzione **`-F`** se ne sceglie un altro (`-F:`, `-F,`);
3. esegue il **programma**, fatto di coppie `pattern { azione }`:
   - se il **pattern** (una condizione) è vero per quella riga, l'azione viene eseguita;
   - senza pattern, l'azione vale per **ogni** riga;
   - senza azione, la riga viene stampata.

Variabili riempite da `awk`: **`NR`** (numero della riga corrente), **`NF`** (quanti campi ha la riga), quindi **`$NF`** è l'ultimo campo.

**I campi esistono solo in base al separatore.** Senza `-F:`, una riga di `/etc/passwd` senza spazi è un unico campo (`$1` = riga intera); una riga con spazi nella descrizione (`nobody:x:65534:65534:Kernel Overflow User:…`) ha come `$1` tutto ciò che precede il primo spazio. Per lo stesso motivo, in un CSV una virgola dentro un campo (`Via Roma, 5`) sposta tutte le colonne successive.

#### 8.2 Come `awk` legge i suoi argomenti

```
awk [opzioni] 'programma' file...
```

Il **primo argomento che non è un'opzione** è il programma; i successivi sono i file. Il programma va **sempre tra apici singoli**, altrimenti la shell sostituirebbe `$1`, `$NF`… con le **sue** variabili prima di avviare `awk`.

#### 8.3 Esempi su `/etc/passwd`

| Comando | Cosa fa |
|---|---|
| `awk -F: '{ print $6 }' /etc/passwd` | la home di ogni utente (sesto campo) |
| `awk -F: '$NF == "/bin/bash" { print $1 }' /etc/passwd` | il nome degli utenti con shell **esattamente** `/bin/bash` |
| `awk -F: 'NR <= 3 { print $1, $3 }' /etc/passwd` | nome e UID delle prime 3 righe |

- `==` `!=` `<` `<=` `>` `>=` confrontano valori; il testo va tra **virgolette doppie**.
- `print $1, $3` stampa i due valori sulla **stessa riga**, separati da uno spazio; `print $1; print $3` sono due comandi e stampano su **due righe**.
- Un'espressione regolare come pattern va tra barre: `/regex/` cerca il testo **in tutta la riga**, non in un campo preciso.

### 9. Modificare testo mentre scorre: `sed`

`sed` (*stream editor*) modifica il testo riga per riga mentre passa, senza aprirlo come un editor. Su Rocky è GNU sed.

#### 9.1 Il ciclo: una riga alla volta, un solo passaggio

`sed` attraversa l'input **una sola volta**, dall'inizio alla fine. Ogni riga completa il suo **ciclo** prima che venga letta la successiva:

```
per ogni riga, nell'ordine del file:
  1. leggi la riga nel pattern space (l'area di lavoro)
  2. esegui lo script su quella riga
  3. stampa automatica del pattern space (se non c'è -n)
  → passa alla riga successiva
```

L'output quindi si costruisce **mentre** `sed` avanza. Con `sed '5p'` la riga 5 esce **due volte di fila**: una dal comando `p`, una dalla stampa automatica dello stesso ciclo. Con `sed '3p;5p'` l'ordine è 1, 2, 3, 3, 4, 5, 5, 6…

Conseguenze:
- **`-n`** disattiva la stampa automatica: escono solo le righe stampate con `p`;
- `sed` scrive su **stdout** e **non modifica il file**. Per modificarlo serve **`-i`** (*in place*): GNU sed scrive il risultato in un file temporaneo e poi lo sostituisce all'originale. Mai provarlo su file di sistema come `/etc/passwd`.

#### 9.2 La sintassi

```
sed [opzioni] 'script' [file...]      (senza file legge da stdin)
```

Ogni istruzione dello script ha la forma **`[indirizzo]comando[argomenti]`**; più istruzioni si separano con `;`. Esempio: `5p` = indirizzo `5` + comando `p`.

**Indirizzi** (facoltativi; senza indirizzo il comando vale per tutte le righe):

| Tipo | Forma | Seleziona |
|---|---|---|
| per numero | `5`, `2,4`, `$` (ultima), `1,$` (tutte) | le righe in quella posizione |
| per contenuto | `/regex/` | le righe che **contengono** una corrispondenza |

**Comandi principali:**

| Comando | Cosa fa |
|---|---|
| `p` | stampa il pattern space |
| `d` | scarta la riga **e interrompe lo script per quella riga**: i comandi dopo non vengono eseguiti |
| `q` | stampa la riga corrente ed esce |
| `s/cerca/sostituisci/flag` | sostituisce la prima corrispondenza di `cerca` (una regex); flag `g` = tutte quelle della riga; `&` nel testo sostitutivo = il testo trovato |

`d` lavora sulla **riga intera**: per togliere solo una parola si usa `s` con la parte sostitutiva vuota.

**Il separatore di `s`** può essere **qualunque singolo carattere**, sempre uguale nelle tre posizioni (documentato solo in `info sed`, nodo *The "s" Command*). Utile con i percorsi: `s%/bin/bash%/bin/zsh%` invece di `s/\/bin\/bash/\/bin\/zsh/` (escape con `\`).

#### 9.3 Esempi su `/etc/passwd`

| Comando | Cosa fa |
|---|---|
| `sed -n '5p' /etc/passwd` | solo la riga 5 |
| `sed '/nologin/d' /etc/passwd` | tutto tranne le righe che contengono `nologin` |
| `sed 's%/bin/bash%/bin/zsh%' /etc/passwd` | sostituisce la shell nell'output |
| `sed 's/:/ \| /g' /etc/passwd` | tutti i `:` diventano ` \| ` |

---

## Comandi e file di riferimento

| Comando / file | A cosa serve | Documentazione |
|---|---|---|
| `>` `>>` `<` `2>` `2>&1` `&>` | Redirezioni | `man bash`, sezione **REDIRECTION** |
| `\|` | Pipe tra comandi | `man bash`, sezione **Pipelines**; `man 7 pipe` |
| `grep` | Cerca righe che corrispondono a un pattern | `man grep` |
| `awk` | Elabora testo a colonne: campi, pattern e azioni | `man awk` |
| `sed` | Modifica il testo riga per riga (stream editor) | `man sed`, `info sed` |
| `wc` | Conta righe (`-l`), parole (`-w`), byte (`-c`) | `man wc` |
| `/dev/null` | "Buco nero": scarta tutto ciò che riceve | `man 4 null` |
| `/proc/<PID>/fd/` | Mostra i file descriptor di un processo | `man 5 proc` |
| Espressioni regolari | Sintassi dei pattern | `man 7 regex` |
| `tar` | Crea ed estrae archivi | `man tar` |
| `gzip` `bzip2` `xz` `zstd` | Comprimono un singolo file | `man gzip`, … |
| `file` | Riconosce il tipo di un file dal contenuto | `man file` |
| `man` | Manuale; `-S` per l'ordine delle sezioni, `-k`, `-f` | `man man` |
| `apropos` | Cerca nelle descrizioni brevi delle pagine | `man apropos` |
| `whatis` | In quali sezioni esiste una pagina | `man whatis` |
| `/etc/man_db.conf` | Configurazione di `man`: ordine delle sezioni (`SECTION`) | `man 5 man_db.conf` |
| `/usr/share/man/manN/` | Dove stanno le pagine della sezione N | — |

## Errori comuni e troubleshooting

- **`2>&1` messo prima di `>`:** gli errori restano a schermo (vedi il Caso B al paragrafo 3.5).
- **Spazio tra il numero e `>`:** `2 > file` non redirige lo stderr.
- **Credere che la pipe trasporti gli errori:** nella pipe passa solo lo stdout.
- **Leggere e scrivere lo stesso file nella stessa riga** (`cmd f > f`): il file viene svuotato prima che il comando lo legga (paragrafo 3.6).
- **Pattern senza àncore:** `grep root` trova anche `chroot`, `rootkit`, `/root`…
- **Pattern senza virgolette:** la shell può interpretare `$`, `*` e altri caratteri prima che arrivino a `grep`.
- **Chiamare "archivio" un file `.gz`:** è un solo file compresso; l'archivio è il `.tar`.
- **Confondere compressione e crittografia:** un `.gz` non protegge nulla.
- **Credere che `tar` conservi tutto:** SELinux e ACL vanno richiesti esplicitamente.
- **`man` dice che la pagina non esiste:** forse manca il pacchetto che la contiene (capitolo 07).
- **`apropos` risponde *nothing appropriate*:** forse l'indice delle pagine non è ancora stato generato.
- **Confondere `MANPATH` con `MANSECT`:** il primo indica le directory, il secondo l'ordine delle sezioni.
- **`awk`: pensare che `$1` sia la prima riga:** è il primo **campo** di ogni riga; le righe si scelgono con il pattern (`NR`).
- **`awk`: scrivere `/bin/bash` come pattern:** `awk` lo legge come la regex `/bin/` concatenata alla variabile vuota `bash`; il risultato (`"1"` o `"0"`) è una stringa non vuota, quindi **vera su ogni riga**. Per un confronto esatto su un campo: `$NF == "/bin/bash"`.
- **`awk`: usare `[1-3]` per un intervallo di righe:** le classi di caratteri sono delle regex e della shell; in `awk` i numeri si confrontano con `<=`, `>=`…
- **`awk`: dimenticare il `-` di `-F`:** `F:` diventa il programma e dà `syntax error`.
- **`sed`: aspettarsi che `5p` stampi la riga 5 "in cima":** `sed` fa un solo passaggio e l'output si costruisce riga per riga.
- **`sed`: `s/nologin/d/`** non cancella righe: sostituisce il testo con la lettera `d`. Per cancellare le righe: `/nologin/d`.
- **`sed`: `1,$d;5p` per stampare solo la riga 5:** `d` interrompe lo script, quindi `5p` non viene mai eseguito. Si usa `-n '5p'`.
- **`sed`: `s/:/ | ` senza il terzo separatore:** errore *unterminated `s' command*.
- **Escape inutili** (`\ ` dentro apici singoli): l'escape serve solo se sai quale significato speciale togli, e a chi (shell o comando).
- **`riga com.:3` con il testo di un altro comando:** un apice rimasto aperto ha fatto finire il comando successivo dentro il programma. Con il prompt `>` premi Ctrl+C.

## Collegamento con l'esame EX200

Obiettivo ufficiale *"Understand and use essential tools"*, in particolare:

- *Use input-output redirection (>, >>, |, 2>, etc.)*
- *Use grep and regular expressions to analyze text*
- *Archive, compress, unpack, and uncompress files using tar, gzip, and bzip2*
- *Locate, read, and use system documentation including man, info, and files in /usr/share/doc*

## Esercizi

1. Lancia `ls -l /proc/$$/fd`, poi `ls -l /proc/$$/fd > /tmp/fd.txt` e guarda il contenuto del file. Cosa è cambiato nel descrittore 1? Perché nel file compare quella riga?
2. Con un solo comando, cerca in tutto il file system i file chiamati `passwd`. Salva in `trovati.txt` i risultati e in `errori.txt` i messaggi di errore. Quante righe ha ciascun file?
3. Crea un file `config.txt` con alcune righe, alcune delle quali iniziano con `#`. Prima di eseguirlo, prevedi cosa succede con `grep -v '^#' config.txt > config.txt` (`man grep` per l'opzione `-v`). Poi verifica. Infine ottieni il risultato voluto, cioè il file senza le righe di commento, senza perdere dati e senza usare opzioni specifiche del comando.
4. Prevedi **prima** di eseguirlo dove finiranno output ed errori di `ls /etc /inesistente 2>&1 > out.txt`. Poi verifica.
5. Usando le àncore, conta quanti utenti in `/etc/passwd` hanno come shell `/bin/bash`, senza contare per errore righe che contengono "bash" altrove. Suggerimento: apri `/etc/passwd` e guarda in quale posizione della riga si trova la shell.
6. Riscrivi `cat /etc/passwd | grep bash | wc -l` con un solo comando, senza pipe.
7. Crea un archivio compresso con gzip della directory `/etc/sysconfig` nella tua home. Poi elenca il contenuto dell'archivio **senza estrarlo**. Usa solo `man tar`.
8. Crea lo stesso archivio con `xz` e con `bzip2`. Confronta le dimensioni dei tre file e il tempo impiegato (cerca in `man bash` la parola chiave per misurare il tempo di un comando).
9. Rinomina uno degli archivi dell'esercizio 8 con un'estensione sbagliata (es. `.txt`). Riesci a scoprire che tipo di file è davvero?
10. Senza internet e senza ricordare il nome del comando, trova come si crea un nuovo utente. Poi trova quali sezioni del manuale hanno una pagina chiamata `crontab` e cosa descrive ciascuna.
11. In `man apropos`, trova l'opzione che fa cercare le pagine che contengono **tutte** le parole indicate. Confronta il numero di risultati di `apropos change password` con e senza quell'opzione.
12. Apri `/etc/man_db.conf` e trova l'ordine delle sezioni. Poi, solo per il terminale corrente, fai in modo che `man passwd` apra la sezione 5 senza indicarla.

## Domande di autoverifica

1. Perché un comando lanciato dalla shell ha già gli fd 0, 1 e 2 aperti, senza aprirli lui?
2. In che momento la shell applica le redirezioni: prima, durante o dopo l'esecuzione del comando?
3. Cosa vuol dire esattamente "copiare un file descriptor"? In cosa è diverso da un collegamento permanente?
4. In una pipe `a | b`, `b` aspetta che `a` finisca prima di partire?
5. Cosa succede a chi scrive in una pipe piena? E a chi legge da una pipe vuota?
6. Come fa `wc` a sapere che i dati sono finiti?
7. Perché `grep 'root$'` trova anche la riga di un utente con shell `/sbin/chroot`?
8. Che differenza c'è tra archiviare e comprimere? Perché `gzip` da solo non basta per una directory?
9. Perché per un backup non si userebbe mai una compressione lossy?
10. Quando estrai un archivio tar, i file hanno gli stessi numeri di inode di quelli originali? Perché?
11. Cosa contiene la sezione 8 del manuale e perché è la più importante per l'EX200?
12. Perché `man passwd` apre la sezione 1 e non la 5? Dove è deciso?
13. Che differenza c'è tra `apropos` e `whatis`?

## Fonti

- `man bash`: sezioni **REDIRECTION** e **Pipelines**
- `man 7 pipe`, `man 2 pipe`, `man 2 dup2`
- `man grep`, `man 7 regex`
- *Learning Bash with Rocky* (libro dell'Academy): capitoli su redirezioni e pipe
- `man tar`, `man gzip`, `man file`
- `man man`, `man apropos`, `man whatis`, `man 5 man_db.conf`

## Cronologia

- 2026-11-19: nuovo paragrafo 9, `sed` (ciclo su una riga alla volta, stampa automatica e `-n`, sintassi `[indirizzo]comando[argomenti]`, indirizzi per numero e per contenuto, `p`/`d`/`q`/`s`, separatore di `s`, `-i`), con gli errori reali degli esercizi.
- 2026-11-19: nuovo paragrafo 8, `awk` (record, campi, separatore, pattern e azione, `NR`/`NF`, come legge gli argomenti), con gli esempi e gli errori reali degli esercizi su `/etc/passwd`, per l'esercizio bonus sul CSV.

- 2026-11-17: ampliato il paragrafo 2 con `/proc` come file system virtuale, `/dev/pts`, l'fd 255 di bash, `/proc/<PID>/cwd` e la differenza tra directory corrente e file aperto (dubbio nato dall'esercizio 2 del capitolo 04).
- 2026-11-16: aggiunti i paragrafi 6 (archivi e compressione) e 7 (documentazione locale: sezioni del manuale, ordine di ricerca, `MANSECT`, `apropos`, `whatis`), dal test d'ingresso della settimana 6 (domande 7, 8 e 9).
- 2026-11-16: aggiunto il paragrafo 3.6 ("leggere e scrivere lo stesso file"), spiegato su richiesta durante il test d'ingresso; l'esercizio 3 è stato sostituito con una variante.
- 2026-11-16: capitolo creato dopo il test d'ingresso della settimana 6 (domande 1–4). Paragrafi: la shell e `fork`/`exec`, file descriptor, redirezioni e loro ordine, pipe a basso livello, `grep` con le àncore `^` e `$`.
- 2026-11-25: §7.4, strategia di ricerca con `apropos` (com'è fatta una riga dell'indice, parole in inglese, ricerca come sottostringa, più parole, sezione 8, filtro con `grep`), nata dalla difficoltà a trovare il comando per ingrandire ext4.
