# Workflow : une session = un ticket = une branche = une PR

Objectif : pouvoir travailler 1 h ici, 2 h là, sur le PC ou le Mac, sans jamais perdre le fil.
Règle absolue : **on ne pousse jamais sur `main`** (hook local + protection GitHub).

Tout passe par un seul script : `scripts/session.sh`.

## 1. Ouvrir une session

```bash
scripts/session.sh start 7
```

Le script, pour le ticket n°7 :
1. met `main` à jour ;
2. crée la branche `<type>/7-<titre-du-ticket>` (le type vient du label du ticket) ;
3. crée la note de session `docs/sessions/AAAA-MM-JJ-<machine>-7.md` ;
4. commit, pousse la branche, et ouvre une **PR en brouillon** avec `Closes #7` ;
5. vous laisse prêt à travailler.

Si une branche existe déjà pour ce ticket (session précédente, autre machine), il la **reprend**
au lieu d'en créer une nouvelle.

## 2. Pendant la session

- Remplissez la note de session : commandes, chiffres, incompréhensions.
- Sauvegardez régulièrement :

```bash
scripts/session.sh save "ce que j'ai fait"
```

Cela commit tout (`type(#7): ce que j'ai fait`) et pousse la branche.
Vous pouvez vous arrêter n'importe quand : tout est sur GitHub.

## 3. Clôturer

```bash
scripts/session.sh done
```

Vérifie que tout est commité, passe la PR de « brouillon » à « prête », affiche son adresse
et demande confirmation avant de fusionner (squash), supprimer la branche et revenir sur `main`.
Répondez `n` si vous voulez d'abord relire la PR dans le navigateur.

## Deux machines, un dépôt

- Au premier clone sur chaque machine, lancez simplement `scripts/session.sh start <n°>` : il active le hook.
- Chaque machine a sa fiche dans `docs/hardware/` ; les benchmarks mentionnent toujours la machine.
- Ne comparez des chiffres que s'ils viennent de la même machine.

## Milestones

Un milestone regroupe plusieurs tickets d'un même thème (voir [PROGRAMME.md](PROGRAMME.md)).
Il est terminé quand tous ses tickets sont fermés. On fait alors une courte rétrospective dans `docs/sessions/`.

## Limites connues

- `gh issue view <n>` sans option plante (bug Projects classic) ; utilisez
  `gh issue view <n> --json title,body --jq '.title, .body'`.
