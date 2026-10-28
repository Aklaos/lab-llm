# lab-llm

Lab personnel d'**inférence LLM** (servir, mesurer, sécuriser des modèles), orienté infra / OPS.
Pas de training : on apprend à faire tourner des modèles proprement et à *prouver* par des chiffres que ça marche.

- Programme complet : [docs/PROGRAMME.md](docs/PROGRAMME.md)
- Façon de travailler (sessions, tickets, branches, PR) : [docs/WORKFLOW.md](docs/WORKFLOW.md)
- Journal des sessions : [docs/sessions/](docs/sessions/)

## Arborescence

```
docs/         programme, workflow, notes de session, fiches matériel
benchmarks/   scripts et résultats de mesure (chiffres datés)
compose/      stacks Docker Compose
scripts/      outils (hooks git, bootstrap GitHub, inventaire)
```

## Règle d'or

On ne pousse **jamais** sur `main`. Un ticket = une branche = une PR.
