# llama-bench : MacBook (Metal) et poste Linux (CPU)

Mesures du 2026-10-30 (Mac) et du 2026-10-28 (Linux). Ne comparer que les tendances : machines et versions de llama.cpp différentes.

## Protocole
- Outil : `llama-bench -m <modèle>.gguf -p 64 -n 16 -r 2`
  - `pp64` : lecture d'un prompt de 64 tokens ; `tg16` : génération de 16 tokens ; 2 répétitions, moyenne ± écart.
- Modèles : Qwen2.5-Instruct en Q4_K_M (GGUF).
- Mac : llama.cpp build 5047748, backend Metal (+ BLAS), démarrage à froid sur secteur non vérifié, aucun autre gros programme volontairement lancé.
- Linux : llama.cpp compilé en CPU, 4 threads (version non relevée dans la note de session).

## Résultats

| Machine | Modèle | Taille | pp64 (t/s) | tg16 (t/s) |
|---|---|---|---:|---:|
| poste linux (CPU) | Qwen2.5-3B Q4_K_M | 1,95 GiB | ≈ 57 | 14,4 ± 0,2 |
| macbook (Metal) | Qwen2.5-3B Q4_K_M | 1,95 GiB | 1910,3 ± 4,6 | 193,6 ± 0,4 |
| macbook (Metal) | Qwen2.5-14B Q4_K_M | 8,37 GiB | 620,6 ± 0,1 | 57,2 ± 0,4 |

## Lecture
- Écriture (`tg`) ≈ bande passante mémoire ÷ taille du modèle : chaque token relit tous les poids.
  - Linux : 1,95 GiB × 14,4 t/s ≈ 30 Go/s.
  - Mac, 3B : ≈ 405 Go/s ; Mac, 14B : ≈ 510 Go/s (le petit modèle est freiné par des frais fixes).
- Lecture du prompt (`pp`) : limitée par le calcul, d'où un écart bien plus grand entre GPU et CPU (≈ ×33) que pour l'écriture (≈ ×13).
- Le 14B est 4,3 fois plus gros que le 3B et 3,4 fois plus lent à écrire : cohérent avec la règle ci-dessus.

## Limites
- Mesure courte (64 + 16 tokens) : pas de test de contexte long ni de charge soutenue (chauffe d'un portable).
- Une seule série par modèle ; pas de contrôle de l'alimentation ni de la température.
