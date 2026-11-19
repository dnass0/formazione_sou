# Capitolo 08 – Utenti, gruppi, password e sudo

> Capitolo **in corso**: per ora contiene solo le basi emerse dal test d'ingresso della settimana 6. Verrà completato quando affronteremo l'argomento.

## Obiettivi

Alla fine del capitolo (per ora) saprai:

- distinguere i comandi `passwd` e `chpasswd`;
- spiegare come sono salvate le password in `/etc/shadow` e perché non si modificano a mano;
- distinguere **hash** e **cifratura**.

## Prerequisiti

- Capitolo 03, paragrafo 7 (documentazione locale: `passwd(1)` e `passwd(5)`).
- Capitolo 04, paragrafo 3 (l'inode contiene UID e GID come numeri).

---

## Teoria

### 1. Cambiare una password: `passwd` e `chpasswd`

- **`passwd`** cambia la password di **un** utente in modo interattivo: senza argomenti la tua, con il nome di un utente (da root) quella di quell'utente.
- **`chpasswd`** legge righe `nome:password` dallo **standard input** e aggiorna **molti utenti insieme**. È pensato per gli script, e si usa con una redirezione o una pipe (capitolo 03).

### 2. Dove stanno le password: `/etc/shadow`

`/etc/passwd` contiene l'elenco degli utenti ed è leggibile da tutti. Le password stanno invece in `/etc/shadow`, leggibile solo da root. Il secondo campo di ogni riga ha questa forma:

```
$6$<sale>$<hash>
```

- `6` indica l'algoritmo usato (SHA-512).
- Il **sale** (*salt*) è una stringa casuale diversa per ogni utente, mescolata alla password prima del calcolo. Così due utenti con la stessa password hanno valori diversi nel file.
- L'**hash** è il risultato del calcolo.

### 3. Hash e cifratura

| | Cifratura | Hash |
|---|---|---|
| Reversibile? | sì, con la chiave | **no**, è a senso unico |
| Scopo | nascondere dati per poterli rileggere | verificare un dato senza conservarlo |

Al login il sistema **non** "decifra" la password salvata. Calcola l'hash di quello che hai digitato, con lo stesso sale, e lo **confronta** con quello nel file. Se coincidono, la password è giusta.

Conseguenze:
- se scrivessi una password **in chiaro** in `/etc/shadow`, il confronto fallirebbe sempre, perché il sistema confronterebbe l'hash di quello che digiti con il testo in chiaro: l'utente non riuscirebbe ad accedere. Per questo il file si modifica solo con gli strumenti appositi;
- nemmeno **root** può leggere la tua password: la può solo **reimpostare**.

---

## Comandi e file di riferimento

| Comando / file | A cosa serve | Documentazione |
|---|---|---|
| `passwd` | Cambia la password di un utente | `man 1 passwd` |
| `chpasswd` | Cambia le password di molti utenti da stdin | `man 8 chpasswd` |
| `/etc/passwd` | Elenco degli utenti | `man 5 passwd` |
| `/etc/shadow` | Hash delle password e scadenze | `man 5 shadow` |

## Errori comuni e troubleshooting

- **Dire che le password in `/etc/shadow` sono "cifrate":** sono hash.
- **Modificare `/etc/shadow` a mano** per cambiare una password.
- **Usare `chpasswd` per un solo utente in modo interattivo:** è pensato per l'uso da script.

## Collegamento con l'esame EX200

Obiettivo *"Manage users and groups"*: *Create, delete, and modify local user accounts*; *Change passwords and adjust password aging for local user accounts*.

## Esercizi

1. Apri `/etc/shadow` in sola lettura e individua, per il tuo utente, l'algoritmo e il sale. Perché il comando per aprirlo richiede i privilegi di root?
2. Crea due utenti di prova con la stessa password. Confronta i loro campi in `/etc/shadow`. Cosa noti, e perché?
3. Usando `chpasswd` e una redirezione, cambia la password dei due utenti di prova in un solo comando, leggendo da un file. Poi cancella quel file: perché è importante farlo?

## Domande di autoverifica

1. Che differenza c'è tra `passwd(1)` e `passwd(5)`?
2. Perché root non può leggere la tua password?
3. A cosa serve il sale?
4. Cosa succede al login se nel campo della password c'è la password in chiaro?

## Fonti

- `man 1 passwd`, `man 8 chpasswd`, `man 5 passwd`, `man 5 shadow`, `man 3 crypt`

## Cronologia

- 2026-11-16: capitolo iniziato dal test d'ingresso della settimana 6 (domanda 8): `passwd` e `chpasswd`, formato di `/etc/shadow`, hash e cifratura.
