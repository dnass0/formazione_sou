# Esercizio Bonus

Risoluzione esercizio bonus assegnatoci oggi (19 Novembre) da Paolo.

Dato un file .csv, a colonne e separato da virgole, in cui ci sono i nostri dati (nome, cognome, indirizzo, numero di telefono):
- estrarre la colonna dei cognomi. 
- selezionare solamente due cognomi.
- rendere la prima lettera maiuscola.

tutto da fare utilizzando solamente le pipe ed i comandi grep, sed e awk.

## Risoluzione
- awk legge il file ed estrae solo la colonna dei cognomi;
- grep mantiene solo le righe che sono esattamente "cognome1" o "cognome2" (-x), in maiuscolo o minuscolo (-i), con l’"oppure" (|) che funziona grazie a -E;
- sed trasforma in maiuscola la prima lettera.

### creazione file “rubrica.csv”:

```
Mario,rossi,via Aorta 5,3518947586
federica,Anzio,via Margutta 12,3927658914
Fabio,de Mattia,via enrico toti 11,3318754971
domenico,nasso,via orvieto 11,3345645321
Simone,paoli,via Rossi 2,3334512349
```

### comando:

```
awk -F, '{ print $2 }' rubrica.csv | grep -Eix 'paoli|de mattia' | sed 's/./\U&/'
```

### output:

```
De Mattia
Paoli
```
