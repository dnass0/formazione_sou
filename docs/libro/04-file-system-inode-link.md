# Capitolo 04 – Il file system: inode, file, hard link e link simbolici

## Obiettivi

Alla fine del capitolo saprai:

- spiegare come un file system organizza il disco in **blocchi** e tiene traccia di quelli liberi;
- dire cos'è un **inode**, cosa contiene e cosa **non** contiene (il nome!);
- spiegare cos'è davvero una **directory**;
- distinguere **hard link** e **link simbolici** e prevedere cosa succede a ciascuno quando il file viene cancellato;
- spiegare cosa fa il sistema quando **cancelli** un file, quando lo spazio torna davvero libero e perché a volte un file cancellato si può recuperare;
- distinguere le **date** di un file: atime, mtime, ctime e btime.

## Prerequisiti

- Capitolo 03, paragrafi 1 e 2 (la shell, le system call e i file descriptor).
- Sapere cos'è un disco e cos'è una partizione, anche solo a grandi linee. Il capitolo 14 li tratta in dettaglio.

---

## Teoria

### 1. Il problema: dare un ordine a un disco

Un disco, visto dal kernel, è soltanto una lunghissima sequenza di byte numerati. Non sa niente di "file", "cartelle" o "nomi".

Un **file system** è il modo in cui si organizza quella sequenza di byte per poterci salvare file con un nome, dei permessi, una data, e ritrovarli dopo. Quando "formatti" una partizione (con un comando della famiglia `mkfs`, che vedremo nel capitolo 15), scrivi su quella partizione le **strutture vuote** del file system: in pratica disegni le righe sul quaderno bianco.

> **Termine – File system:** l'insieme di strutture dati scritte su una partizione che permettono di salvare e ritrovare file e directory. Esempi: XFS (predefinito su Rocky Linux e RHEL), ext4, vfat.

> **Attenzione al linguaggio:** quando si parla di file system si parla di **disco**, non di **memoria**. La memoria (RAM) si svuota allo spegnimento, il disco no. Confonderle porta a ragionamenti sbagliati.

### 2. I blocchi

La prima cosa che il file system fa è dividere lo spazio in tanti "cassetti" della stessa dimensione, chiamati **blocchi**. Di solito un blocco è grande **4 KiB** (4096 byte). Ogni blocco ha un numero: 0, 1, 2, …

Un file occupa uno o più blocchi interi. Un file da 10 KiB occupa 3 blocchi: 4 + 4 + 2 KiB, e l'ultimo resta in parte vuoto.

Il blocco è l'**unità minima**: anche un file da 26 byte occupa un blocco intero da 4 KiB. I byte inutilizzati del blocco sono uno spreco che si chiama **frammentazione interna**. Per questo **dimensione** del file (quanti byte contiene, scritta nell'inode) e **spazio occupato** su disco sono due numeri diversi. La prima riga di `ls -l` su una directory, `totale N`, mostra proprio lo spazio occupato dai file elencati, in KiB:

```
totale 4
16925780 -rw-r--r--. 1 dnasso dnasso 26 17 nov 12.27 hl_prova.txt
```

Qui il file contiene 26 byte (colonna della dimensione) ma occupa 4 KiB. Il `.` dopo i permessi indica che il file ha un **contesto SELinux**, un'etichetta di sicurezza aggiuntiva (capitolo 24).

### 3. L'inode: la scheda del file

Per ogni file il file system tiene una piccola struttura dati chiamata **inode** (*index node*). Pensala come la **scheda** di un file in uno schedario.

Gli inode stanno in una tabella, e la posizione di un inode in quella tabella è il suo **numero di inode**. Il numero identifica la scheda, ma **non è** la scheda.

Le posizioni della tabella sono **fisse**, come le caselle di un casellario: quando un file viene cancellato la sua casella viene segnata libera e **non si sposta**, e un file creato dopo può riceverla (lo stesso numero, ma un file diverso). Quale casella libera venga scelta dipende dalle regole del file system. In **XFS** il numero di inode indica anche **dove** sta fisicamente l'inode: il disco è diviso in **gruppi di allocazione** (*allocation groups*) e XFS cerca di mettere l'inode di un file vicino a quello della sua directory. Esempio reale: la home aveva inode `16786379` e i file creati lì numeri `169…`; la directory `link` aveva `50331794` e un file creato dentro di essa ha ricevuto `50503131`.

**Cosa contiene un inode:**

| Informazione | Dove la vedi in `ls -l` |
|---|---|
| **Tipo** di file (normale, directory, link simbolico, dispositivo…) | il primo carattere: `-`, `d`, `l`, … |
| **Permessi** | `rw-r--r--` |
| **Link count** (numero di nomi che puntano all'inode) | il numero dopo i permessi |
| **UID** e **GID** (proprietario e gruppo, come **numeri**) | i due nomi, ad es. `dnasso dnasso` |
| **Dimensione** in byte | il numero prima della data |
| **Date** (atime, mtime, ctime, btime: paragrafo 7) | la data (di default `ls` mostra la mtime) |
| **Elenco dei blocchi** che contengono i dati | non visibile in `ls` |

**Cosa NON contiene un inode: il nome del file.**

Nota anche che l'inode contiene solo i **numeri** di utente e gruppo. È `ls` che li trasforma in nomi, cercandoli in `/etc/passwd` e `/etc/group`. Se quell'utente venisse cancellato dal sistema, `ls -l` non troverebbe più il nome e mostrerebbe il numero.

### 4. La directory: una tabella di nomi

Se il nome non sta nell'inode, dove sta? In una **directory**.

Una directory è a sua volta un file, con il suo inode e i suoi blocchi. Il suo **contenuto**, cioè quello che c'è scritto nei suoi blocchi, è una tabella di coppie *nome → numero di inode*:

```
nome          numero di inode
report.txt    1234
copia.txt     1234     ← stesso inode: è un hard link
foto.jpg      5678
```

Ogni riga di questa tabella si chiama **voce di directory** (*directory entry*). Il nome sta nel **contenuto** della directory, non nei suoi metadati.

#### 4.1 Com'è fatta davvero una voce di directory

Sul disco la "tabella" non ha colonne allineate: è una **sequenza di byte**, una voce dopo l'altra. I nomi hanno lunghezze diverse, quindi ogni voce porta con sé, oltre al nome, i campi che servono a leggerla. Esempio di ext4 (struttura `ext4_dir_entry_2`):

| Campo | Byte | A cosa serve |
|---|---|---|
| numero di inode | 4 | dove andare a prendere la scheda del file |
| lunghezza della voce | 2 | dove inizia la voce successiva |
| lunghezza del nome | 1 | quanti byte leggere per il nome (massimo 255) |
| tipo di file | 1 | file, directory, link… |
| nome | variabile | i caratteri del nome, **senza** `\0` finale |

XFS usa campi simili. Due conseguenze:
- una voce contiene il **numero** di inode, mai l'inode stesso;
- il **tipo** è copiato nella voce per comodità: così `ls` può colorare directory e link senza aprire l'inode di ogni file. La fonte ufficiale resta l'inode.

**Le voci `.` e `..`.** Ogni directory contiene logicamente anche `.` (lei stessa) e `..` (la directory madre): `ls -a` le mostra. Per questo una directory appena creata ha **link count 2**: il suo nome nella directory madre più il `.` al suo interno. Ogni sottodirectory aggiunge 1 alla madre, con il suo `..`. Quindi il link count di una directory è **2 + il numero delle sue sottodirectory**, comprese quelle **nascoste** (che `ls` senza `-a` non mostra). I file normali non contano, perché non contengono un `..`. In XFS `..` e `.` non sono scritti come voci (§4.2), ma il kernel li restituisce lo stesso a `ls -a` e il conteggio funziona allo stesso modo.

Dove stanno fisicamente questi byte dipende dal file system e dalla dimensione della directory: di solito nei blocchi dati della directory, come per un file normale. In ext4 una directory occupa sempre almeno un blocco, e `ls -l` mostra 4096 come dimensione.

#### 4.2 XFS: le directory piccole stanno dentro l'inode

La tabella degli inode sta **sul disco** ed è fatta di caselle di dimensione **fissa**: in XFS ogni inode occupa **512 byte**. Le caselle fisse del §3 ne usano circa 176. Il resto è uno **spazio libero dentro l'inode** che XFS usa per:
- l'elenco dei blocchi del file (quando i dati stanno fuori);
- gli **attributi estesi**, per esempio l'etichetta SELinux che `stat` mostra alla riga `Contesto`;
- direttamente il **contenuto**, se è abbastanza piccolo, ma **solo per directory e link simbolici**.

**I file regolari no.** Un file regolare in XFS ha sempre i dati in blocchi, anche se è lungo pochi byte: `hl_prova.txt` (28 byte) mostra `Blocchi: 8`, cioè 8 × 512 = 4 KiB. Il motivo è che i dati dei file regolari passano dalla **page cache**, la memoria in cui il kernel tiene copie dei file in pezzi da 4 KiB (le *pagine*), ognuno collegato a un blocco sul disco. Directory e link simbolici invece sono strutture che legge e scrive solo il codice del file system, che può metterle dove vuole. (ext4 ha un'opzione, `inline_data`, per tenere nell'inode anche i file piccoli, ma non è attiva di default.)

Una directory con pochi nomi ha un elenco di poche decine di byte: invece di occupare un blocco da 4 KiB, XFS lo scrive **dentro l'inode della directory**. Questo formato si chiama **shortform**. Vantaggi: nessun blocco sprecato, e una lettura in meno, perché leggendo l'inode si hanno già i nomi. Quando i nomi non ci stanno più, XFS sposta l'elenco in un blocco dati.

Esempio reale: `stat link/` mostra `Dim.: 26` e `Blocchi: 0`. I 26 byte sono:
- un'**intestazione** di 6 byte: quante voci ci sono (1 byte), un byte che indica se i numeri di inode sono da 4 o da 8 byte, e il numero di inode della directory madre (4 byte). È così che XFS conserva `..`; `.` non viene scritto, perché è l'inode stesso;
- la voce `hl_prova.txt`: 8 byte fissi + 12 byte di nome = 20.

Creando il file `1` la dimensione passa a 35: 8 byte fissi + 1 byte di nome = 9.

Lo stesso trucco vale per i **link simbolici** corti: il percorso viene scritto dentro l'inode.

Quando apri `/home/dnasso/report.txt`, il kernel:
1. parte dall'inode di `/`;
2. legge il contenuto di `/`, cerca la voce `home` e trova il suo numero di inode;
3. legge il contenuto di `home`, cerca `dnasso`;
4. legge il contenuto di `dnasso`, cerca `report.txt` e trova l'inode 1234;
5. dall'inode 1234 ricava permessi e blocchi, e finalmente può leggere i dati.

### 5. Hard link e link simbolici

#### 5.1 Hard link: un altro nome per lo stesso inode

Un **hard link** è semplicemente **un'altra voce di directory** che punta allo **stesso inode**. Quando crei un hard link:
- viene aggiunta una riga *nome → numero di inode* in una directory;
- nell'inode il **link count** aumenta di 1.

I dati **non vengono duplicati**: c'è un solo inode e un solo insieme di blocchi.

Conseguenza importante: **non esiste un "originale"**. Dopo aver creato l'hard link, i due nomi sono perfettamente equivalenti. Il file system non sa quale dei due è nato prima, perché il nome non sta nell'inode.

**Niente hard link tra file system diversi.** Una voce di directory contiene solo il **numero** di inode, non il file system a cui appartiene, e ogni file system ha la **sua** tabella degli inode con la sua numerazione. Se fosse permesso:
- il numero N, scritto in una directory della home, verrebbe cercato nella tabella della home, dove l'inode N è un altro file o una casella libera;
- il link count sta nell'inode dell'altro file system, che non saprebbe niente della nuova voce. Il conteggio non sarebbe mai coerente, e smontando l'altro file system il nome resterebbe orfano.

Per questo il kernel rifiuta l'operazione già al momento della creazione. Esempio reale sulla VM (la home e `/boot` hanno un campo `Device:` diverso in `stat`):

```
$ ln /boot/config-5.14.0-687.10.1.el9_8.0.1.x86_64 hl
ln: creazione del collegamento fisico 'hl' a '/boot/config-…' non riuscita: Collegamento tra dispositivi non valido
```

In inglese il messaggio è *Invalid cross-device link* (codice di errore `EXDEV`). Un link simbolico invece funziona, perché contiene un percorso e il percorso attraversa i mount. Per sapere se due file stanno sullo stesso file system si confronta il campo **`Device:`** di `stat`.

#### 5.2 Link simbolico: un file che contiene un percorso

Un **link simbolico** (*symbolic link*, *symlink*) è un **file a sé**, con il **suo** inode (di tipo `l`), il cui contenuto è **solo un percorso**, una stringa come `/home/dnasso/report.txt`.

Ogni volta che lo usi, il kernel legge quel percorso e lo **risolve in quel momento**, cercando cosa c'è a quell'indirizzo. Il link simbolico non sa niente del file a cui punta: ne conosce solo l'indirizzo. Da qui due conseguenze:
- se il file a quel percorso viene cancellato, il link resta ma non porta più da nessuna parte: si dice che è **pendente** (*dangling*). Usarlo dà un errore;
- se poi crei un **nuovo** file allo stesso percorso, il link lo segue senza accorgersi che è un altro file.

**Il contenuto è esattamente la stringa che scrivi.** Quando crei un link simbolico, il kernel salva il percorso **così come lo hai scritto**, nome del file compreso, senza completarlo e **senza controllare che il file esista**. Per questo la dimensione di un link simbolico è il numero di caratteri del percorso: un link a `hl_prova.txt` è grande 12 byte. E per questo si può creare un link già pendente senza ricevere errori.

**Percorso relativo: rispetto a cosa?** Se il percorso è relativo, il kernel lo risolve rispetto alla **directory in cui si trova il link**, non alla directory corrente di chi lo usa o di chi lo ha creato. Esempio reale: un link creato in `/home/dnasso/` con contenuto `hl_prova.txt` porta a `/home/dnasso/hl_prova.txt`, anche se il file vero è in `/home/dnasso/link/`. `ls` colora in rosso i link pendenti.

| Destinazione | Esempio | Resta valido se… | Si rompe se… |
|---|---|---|---|
| assoluta | `/home/dnasso/link/hl_prova.txt` | sposti il link | sposti o rinomini la cartella del file |
| relativa | `link/hl_prova.txt` | sposti link e file insieme (copia della home, ripristino di un backup altrove) | sposti solo il link |

Il contenuto di un link simbolico non si modifica: per correggerlo si cancella il link (il file a cui punta non viene toccato) e se ne crea uno nuovo.

#### 5.3 Confronto

| | Hard link | Link simbolico |
|---|---|---|
| Cos'è | un'altra voce di directory | un file che contiene un percorso |
| Inode | **lo stesso** del file | **uno suo** |
| Spazio occupato | solo una voce di directory | un inode e il percorso |
| Se cancelli "l'originale" | i dati restano raggiungibili | diventa pendente |
| Aggiorna il link count | sì | no |
| Verso un altro file system | **no** (`EXDEV`) | sì |

### 6. Cosa succede quando cancelli un file

#### 6.1 `rm` in realtà "toglie un nome"

`rm` usa la system call **`unlink()`**, cioè "togli un collegamento". Quello che fa è:
1. togliere la voce dalla directory;
2. diminuire di 1 il link count nell'inode.

Il file "sparisce davvero" solo come effetto collaterale, quando si toglie l'**ultimo** nome.

#### 6.2 Quando lo spazio torna libero

Il file system tiene un **registro** di cosa è occupato e cosa è libero. Su ext4 questo registro è fatto di **bitmap**: sequenze di bit, uno per ogni blocco e uno per ogni inode (`1` = occupato, `0` = libero). XFS usa strutture diverse, gli alberi B+, ma il principio è lo stesso.

```
blocco:   118 119 120 121 122 123
bitmap:    1   0   1   1   1   0      ← il file occupa i blocchi 120–122
```

Quando il link count arriva a 0, il file system **segna come liberi** l'inode e i suoi blocchi:

```
blocco:   118 119 120 121 122 123
bitmap:    1   0   0   0   0   0
contenuto dei blocchi 120–122: ancora i vecchi byte del file
```

"Liberare lo spazio" vuol dire **soltanto questo**: cambiare dei bit nel registro. I byte del contenuto **non vengono cancellati**. Il prossimo file che ha bisogno di spazio potrà prendere quei blocchi e sovrascriverli.

Ecco perché:
- **cancellare** un file da 1 GB è quasi istantaneo, perché cambiano pochi bit;
- **copiarlo** è lento, perché bisogna leggere 1 GB e scriverne un altro;
- `df`, che mostra lo spazio libero, se ne accorge subito, perché legge proprio questo registro.

#### 6.3 L'eccezione dei file aperti

Anche il **kernel** tiene un conto: quanti processi hanno quel file **aperto** in quel momento. Inode e blocchi vengono liberati solo quando **entrambi** i conti sono a zero:
- link count = 0 (nessun nome punta più all'inode);
- nessun processo ha il file aperto.

Esempio classico: cancelli un file di log enorme, ma il servizio che ci scrive lo tiene ancora aperto. Il nome sparisce, ma `df` non mostra spazio in più finché il servizio non chiude il file. Lo riprenderemo nel capitolo 10 (processi).

#### 6.4 Recuperare un file cancellato

**Con gli strumenti normali non si può "ricollegare" un inode.** La system call che crea un hard link, `link()`, chiede un **percorso esistente** e un nuovo nome. Non esiste una chiamata del tipo "collega questo nome all'inode numero 1234". Quando i nomi sono finiti, non c'è più una porta d'ingresso. In più, ext4 quando cancella un file **azzera anche l'elenco dei blocchi** nell'inode.

Gli strumenti di recupero **scavalcano il file system** e leggono il dispositivo grezzo (ad esempio `/dev/sda1`) come una sequenza di byte. Le tecniche principali sono due:
1. **Recupero dai metadati:** cercano una copia vecchia dell'inode, per esempio nel **journal**. Il journal è un registro in cui il file system annota le modifiche prima di farle, per non corrompersi in caso di interruzione improvvisa.
2. **File carving:** ignorano inode e directory e cercano nei blocchi le **firme** dei formati noti. Per esempio, ogni JPEG inizia con i byte `FF D8 FF`. I file recuperati così sono **senza nome**, perché il nome stava nella voce di directory.

**Regola d'oro:** dopo una cancellazione per errore, **smetti subito di scrivere** su quel file system, perché ogni scrittura può riusare i blocchi segnati come liberi. Su un sistema acceso non basta stare fermi, perché altri programmi scrivono. Dalla misura meno drastica alla più drastica:
1. **rimontarlo in sola lettura:** resta leggibile, ma il kernel rifiuta le scritture;
2. **smontarlo:** viene staccato dall'albero delle directory. Non si può fare se dei processi lo stanno usando (errore `target is busy`) e non si può fare con `/` mentre il sistema è acceso;
3. **spegnere il computer** e analizzare il disco da un altro sistema. È la più sicura ma ferma **tutto**: servizi, utenti, tutte le partizioni.

(Montaggio e smontaggio: capitolo 15.)

Per un amministratore di sistema la vera risposta però non è il recupero: sono i **backup** e gli **snapshot** (capitolo 14, LVM).

### 7. Le date di un file

L'inode tiene **tre** date fin dai primi Unix, più una quarta sui file system moderni:

| Data | Nome | Cosa la aggiorna |
|---|---|---|
| **atime** | *access time* | la **lettura** del contenuto |
| **mtime** | *modification time* | la modifica del **contenuto** |
| **ctime** | *change time* | qualsiasi modifica dell'**inode**: permessi, proprietario, link count… e **anche** ogni modifica del contenuto, perché cambiano dimensione, blocchi e la mtime stessa, che stanno nell'inode |
| **btime** | *birth time* | la **creazione** del file. Non si può modificare con i comandi normali. Disponibile su XFS ed ext4; sui file system più vecchi `stat` mostra `-` |

> **Trappola classica:** la "c" di **ctime** sta per ***change***, non per *creation*. La data di creazione è la btime.

Esempi, partendo da un file con tutte le date di ieri:

| Operazione | atime | mtime | ctime |
|---|---|---|---|
| leggere il contenuto | ✔ | | |
| cambiare i permessi | | | ✔ |
| aggiungere testo in fondo (`>>`) | | ✔ | ✔ |

Aggiungere testo con `>>` **non** aggiorna la atime: la shell apre il file in **scrittura** e non legge niente di quello che c'era.

#### 7.1 Perché la atime a volte "non cambia": `relatime`

Aggiornare la atime vuol dire **scrivere** sull'inode a ogni **lettura**: su un server che legge migliaia di file al secondo, è un costo enorme per un'informazione poco usata. Per questo i file system vengono montati con delle **opzioni di montaggio**, e quella predefinita su Linux è **`relatime`**: la atime viene aggiornata solo se
- è più vecchia della mtime o della ctime, oppure
- sono passate più di 24 ore dall'ultimo aggiornamento.

`relatime` **confronta solo le date**: non sa se è cambiato il contenuto o solo i metadati. Esempio: dopo un `chmod` la ctime diventa più recente della atime, quindi la lettura successiva aggiorna la atime. Le letture seguenti non la aggiornano più, finché non cambia di nuovo la mtime o la ctime o non passano 24 ore.

Altre opzioni: `noatime` (mai) e `strictatime` (sempre). Esiste anche `O_NOATIME`, un'opzione che un singolo programma può passare alla system call `open()` per non aggiornare la atime. Le opzioni di montaggio sono trattate nel capitolo 15.

---

## Comandi e file di riferimento

| Comando / file | A cosa serve | Documentazione |
|---|---|---|
| `ls -l` | Mostra tipo, permessi, link count, proprietario, dimensione e mtime | `man ls` |
| `ls -i` | Mostra il numero di inode | `man ls` |
| `stat` | Mostra tutto il contenuto dell'inode, comprese le quattro date | `man stat` |
| `ln` | Crea hard link e (con un'opzione) link simbolici | `man ln` |
| `rm` | Toglie un nome (system call `unlink`) | `man rm`, `man 2 unlink` |
| `df` | Spazio libero dei file system montati | `man df` |
| `/proc/<PID>/fd/` | File aperti da un processo, anche se già cancellati | `man 5 proc` |
| Inode e date | Descrizione completa dei campi | `man 7 inode`, `man 2 stat` |
| Link | Comportamento di hard link e link simbolici | `man 2 link`, `man 7 symlink` |

> Le pagine delle sezioni 2, 5 e 7 stanno nel pacchetto `man-pages`, che con l'installazione minimale di Rocky potrebbe mancare (capitolo 07).

## Errori comuni e troubleshooting

- **Dire "memoria" invece di "disco"** quando si parla di blocchi e file system.
- **Pensare che l'inode contenga il nome:** il nome sta nella directory. È per questo che esistono gli hard link.
- **Pensare che esista un file "originale" e una "copia"** dopo un hard link: i nomi sono equivalenti.
- **Pensare che `rm` cancelli i dati:** toglie un nome e, se era l'ultimo, segna i blocchi come liberi.
- **Lo spazio non si libera dopo `rm`:** probabilmente un processo ha ancora il file aperto.
- **Confondere ctime con la data di creazione.**
- **Aspettarsi che la atime cambi a ogni lettura:** con `relatime` non succede.
- **Pensare che `relatime` guardi solo la mtime o il contenuto:** confronta la atime anche con la ctime, quindi anche una modifica dei soli metadati (per esempio `chmod`) fa aggiornare la atime alla lettura successiva.
- **Link simbolico che "non funziona più":** controlla se il percorso a cui punta esiste ancora.

## Collegamento con l'esame EX200

Obiettivo ufficiale *"Understand and use essential tools"*:

- *Create hard and soft links*
- *List, set, and change standard ugo/rwx permissions* (i permessi stanno nell'inode; capitolo 05)

Le basi del capitolo servono anche per *"Create and configure file systems"* e *"Configure local storage"* (capitoli 14 e 15).

## Esercizi

1. Crea un file `prova.txt` con del testo. Guarda il suo numero di inode e il link count. Crea un hard link in un'altra directory della tua home e guarda di nuovo entrambi i valori, su tutti e due i nomi.
2. Cancella il primo nome dell'esercizio 1. Il contenuto è ancora leggibile dal secondo nome? Cosa è cambiato nel link count?
3. Crea un link simbolico a un file. Confronta il numero di inode e la dimensione del link con quelli del file. Cosa rappresenta quella dimensione?
4. Cancella il file a cui punta il link dell'esercizio 3 e prova a leggerlo attraverso il link. Poi crea un nuovo file con lo stesso nome e un contenuto diverso, e leggi di nuovo dal link.
5. Con `stat`, prima di eseguire ciascun comando prevedi quali date cambieranno, poi verifica: leggere il file, cambiare i permessi, aggiungere una riga in fondo. Se una data non si comporta come previsto, trova il motivo.
6. Prova a creare un hard link a un file che sta su un file system diverso da quello della tua home (per esempio sotto `/boot`, se è una partizione separata, o in `/proc`). Cosa succede? Sai spiegare perché, ricordando come sono fatti i numeri di inode?

## Domande di autoverifica

1. Perché un hard link non occupa spazio per i dati?
2. Dove sta il nome di un file? E dove stanno i suoi permessi?
3. Cosa fa esattamente `rm` a livello di directory e di inode?
4. Quando il file system considera libero lo spazio di un file? Quali due condizioni devono essere vere?
5. Perché cancellare un file è molto più veloce che copiarlo?
6. Perché un file recuperato con il file carving non ha il nome?
7. Perché non si può creare un nuovo nome per un inode il cui link count è già 0?
8. Qual è la differenza tra mtime e ctime? Esiste un'operazione che aggiorna la mtime senza aggiornare la ctime?
9. Perché esiste l'opzione di montaggio `relatime`?
10. Dopo aver cancellato per errore un file importante, qual è la prima cosa da fare? Quali sono le opzioni, dalla meno alla più drastica?

## Fonti

- `man 7 inode`, `man 2 stat`, `man 2 link`, `man 2 unlink`, `man 7 symlink`
- `man ln`, `man stat`, `man ls`
- `man 8 mount`: opzioni `relatime`, `noatime`, `strictatime`
- *Learning Bash with Rocky* e documentazione Rocky Linux (libri dell'Academy): parti su file e link

## Cronologia

- 2026-11-18: nuovo §4.2, directory *shortform* di XFS: l'elenco dei nomi sta dentro l'inode (`Blocchi: 0`), calcolo dei 26 e dei 9 byte con l'esempio reale di `link/`. Corretto subito dopo: in XFS solo directory e link simbolici stanno nell'inode, i file regolari usano sempre blocchi (page cache).
- 2026-11-18: nuovo §4.1, com'è fatta una voce di directory sul disco (campi di `ext4_dir_entry_2`), tipo copiato nella voce, `.` e `..` e link count delle directory (domanda "dove stanno davvero i nomi?").
- 2026-11-18: §5.1 e §5.3, perché non esistono hard link tra file system diversi (`EXDEV`) e come riconoscerli con il campo `Device:` di `stat` (dall'esercizio 6).
- 2026-11-18: §7.1 e Errori comuni, `relatime` confronta la atime anche con la ctime (esempio del `chmod`), emerso durante l'esercizio 5.
- 2026-11-17: aggiunte al §3 le caselle fisse della tabella degli inode, il riuso dei numeri e il posizionamento degli inode in XFS (dagli esercizi 3 e 4).
- 2026-11-17: aggiunti al §5.2 il contenuto esatto di un link simbolico, la risoluzione dei percorsi relativi rispetto alla directory del link e il confronto tra percorso assoluto e relativo (dall'esercizio 3, link creato pendente).
- 2026-11-17: aggiunte al paragrafo 2 la frammentazione interna, la riga `totale` di `ls -l` e il `.` del contesto SELinux, con l'output reale dell'esercizio 2.
- 2026-11-16: capitolo creato dopo il test d'ingresso della settimana 6 (domande 5 e 6) e dalle domande nate durante il test: hard link e link simbolici, inode e directory, link count e `unlink`, blocchi e bitmap, cosa vuol dire "liberare spazio", file aperti, recupero dei file cancellati, misure per smettere di scrivere su un file system, date dell'inode e `relatime`.
