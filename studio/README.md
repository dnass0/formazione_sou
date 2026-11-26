# Studio – lezioni a problemi e laboratorio

| Percorso | Cosa contiene |
|---|---|
| [`lezioni/scripting/`](lezioni/scripting/00-percorso.md) | 24 lezioni di scripting bash a problemi e gli [allenamenti](lezioni/scripting/allenamenti.md). Si parte da `00-percorso.md` |
| [`lab/scripting/`](lab/scripting/) | Il kit: `prepara.sh` genera i dati della palestra, `verifica.sh` corregge gli script |
| `lab/scripting/palestra/` | Creata da `prepara.sh`: qui scrivo i miei script (`dati/` si rigenera e non va su git) |

Come si usa (sulla VM Rocky, non sul Mac):

```sh
cd formazione_sou/studio/lab/scripting
./prepara.sh 01              # prepara la lezione 01
cd palestra/l01
../../verifica.sh 01 1       # lezione 01, problema 1
../../verifica.sh stato      # riepilogo di tutto
```

Le regole per lavorarci con Claude sono in `CLAUDE.md`, sezione «Lezioni di scripting a problemi».

**Origine.** Lezioni e kit vengono dal repository di un collega dell'Academy, [DMGiulioRomano/formazione_sou](https://github.com/DMGiulioRomano/formazione_sou) (copiati il 26/11/2026), con i diari svuotati e gli stati azzerati per ripartire da zero. Le parti derivate dalle guide Rocky restano sotto CC BY-SA 4.0 (vedi le fonti in `00-percorso.md`).
