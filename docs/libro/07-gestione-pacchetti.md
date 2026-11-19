# Capitolo 07 – Gestione dei pacchetti: rpm, dnf, repository

> Capitolo **in corso**: per ora contiene solo le basi emerse dal test d'ingresso della settimana 6. Verrà completato quando affronteremo l'argomento.

## Obiettivi

Alla fine del capitolo (per ora) saprai:

- spiegare cos'è un **pacchetto** e cos'è un **repository**;
- leggere il nome completo di un pacchetto (nome, versione, release, architettura);
- scoprire **quale pacchetto** fornisce un file o un comando, anche se non è installato.

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

---

## Comandi e file di riferimento

| Comando / file | A cosa serve | Documentazione |
|---|---|---|
| `dnf provides` | Quale pacchetto contiene un file | `man dnf`, sezione dei comandi |
| `dnf install` | Installa un pacchetto | `man dnf` |
| `dnf info` | Informazioni su un pacchetto di cui conosci il nome | `man dnf` |
| `/var/cache/dnf` | Cache dei metadati dei repository | — |

## Errori comuni e troubleshooting

- **Passare a `dnf provides` solo una parola** invece di un percorso: per i file serve il percorso, o un pattern con caratteri jolly.
- **Caratteri jolly senza apici:** li interpreta la shell sul disco locale.
- **Confondere `dnf info` e `dnf provides`:** `info` parte dal nome del pacchetto, `provides` parte dal file.
- **Usare root anche per consultare:** `dnf provides`, `man` e `ls` non ne hanno bisogno; root serve per installare.

## Collegamento con l'esame EX200

Obiettivo *"Deploy, configure, and maintain systems"*: *Install and update software packages from Red Hat Network, a remote repository, or from the local file system*.

## Esercizi

1. Scopri quale pacchetto fornisce il comando `semanage`, che userai con SELinux. È installato sulla tua VM?
2. Scopri quale pacchetto fornisce la pagina di manuale `hier` della sezione 7, usando un pattern con caratteri jolly invece del percorso esatto.
3. Prova lo stesso pattern dell'esercizio 2 senza apici, da una directory in cui esiste un file con un nome che corrisponde. Cosa cambia e perché?

## Domande di autoverifica

1. Cosa contengono i metadati di un repository?
2. Come fa `dnf provides` a trovare un file che non è sul tuo disco?
3. Cosa succederebbe a `dnf provides` se la VM non raggiungesse i repository e la cache fosse vuota?
4. Cosa indica `noarch`? Perché un pacchetto di sole pagine di manuale è `noarch`?
5. Cosa significa `@System` nell'output di `dnf`?

## Fonti

- `man dnf`
- Documentazione Rocky Linux (libri dell'Academy): gestione dei pacchetti

## Cronologia

- 2026-11-16: capitolo iniziato dal test d'ingresso della settimana 6 (domanda 10): pacchetti e repository, nome completo di un pacchetto, metadati e cache, `dnf provides` con l'esempio reale di `man-pages`.
