# Workflow : une session = un ticket = une branche = une PR

Objectif : pouvoir travailler 1 h ici, 2 h là, sur le PC ou le Mac, sans jamais perdre le fil.
Règle absolue : **on ne pousse jamais sur `main`** (hook local + protection GitHub).

## Ouvrir une session

```bash
git switch main && git pull --ff-only      # repartir d'un main à jour
gh issue list --milestone "M1 Premier contact"   # choisir un ticket
gh issue view 7                             # relire le ticket
git switch -c feat/7-compiler-llama-cpp     # une branche par ticket : <type>/<n°>-<slug>
cp docs/sessions/_template.md docs/sessions/2026-11-02-pc-7.md   # note de session
```

Types de branche : `feat` (nouvelle capacité), `bench` (mesures), `docs`, `fix`, `chore`.

## Pendant la session

- Notez au fil de l'eau dans la note de session : commandes, chiffres, incompréhensions.
- Petits commits, souvent. Message : `type(#7): ce qui a changé` (ex. `bench(#12): ajoute le script TTFT`).
- Une session peut s'arrêter en plein ticket : commitez et poussez la branche, vous reprendrez
  depuis l'autre machine avec `git fetch && git switch feat/7-compiler-llama-cpp`.

## Clôturer une session

```bash
git add -A && git status                    # relire ce qui part
git commit -m "feat(#7): compile llama.cpp en mode CPU"
git push -u origin HEAD                     # pousse la BRANCHE, jamais main
gh pr create --fill                         # PR ; le corps contient "Closes #7"
```

Quand le ticket est terminé : relecture de la PR par vous-même (relire son propre diff est un excellent
exercice), puis `gh pr merge --squash --delete-branch` et retour sur `main` avec `git switch main && git pull`.

## Deux machines, un dépôt

- Au premier clone sur chaque machine : `git config core.hooksPath scripts/hooks`.
- Chaque machine a sa fiche dans `docs/hardware/` ; les benchmarks mentionnent toujours la machine.
- Ne comparez des chiffres que s'ils viennent de la même machine.

## Milestones

Un milestone regroupe plusieurs tickets d'un même thème (voir [PROGRAMME.md](PROGRAMME.md)).
Il est terminé quand tous ses tickets sont fermés. On fait alors une courte rétrospective dans `docs/sessions/`.
