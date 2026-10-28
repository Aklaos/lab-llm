# Programme : de zéro à une plateforme d'inférence documentée

Rythme visé : 5-6 h/semaine en 2 à 3 sessions de 1 h 30 à 3 h. Un ticket vaut en général une session.
Durée indicative : ~6 mois. Aller plus vite est très bien ; on ne saute jamais un milestone, on le raccourcit.

Positionnement final : *« Plateforme d'inférence LLM auto-hébergée : déployée, instrumentée, benchmarkée, documentée. »*

Chaque ticket a : un **objectif**, une **preuve** (ce qui montre que c'est fait) et un **apprentissage visé**.
Les tickets sont créés sur GitHub par `scripts/bootstrap-github.sh` (source de vérité : ce fichier + ce script).

---

## M0 Socle (semaine 1)
| # | Ticket | Apprentissage visé |
|---|---|---|
| M0-1 | Charte du dépôt : README, .gitignore, hook pre-push, templates | workflow git propre, hooks |
| M0-2 | Protéger `main` sur GitHub (ruleset) et vérifier SSH + `gh` sur les 2 machines | sécurité d'un dépôt, auth |
| M0-3 | Inventaire matériel : `scripts/inventory.sh` + fiches `docs/hardware/` | savoir décrire une machine d'inférence |
| M0-4 | Script de session `scripts/session.sh` (start / save / done) | automatiser son workflow |

## M1 Premier contact (semaines 2-3)
| # | Ticket | Apprentissage visé |
|---|---|---|
| M1-1 | Compiler llama.cpp (CPU sur Linux, Metal sur Mac) | chaîne de build, options de backend |
| M1-2 | Premier modèle GGUF avec `llama-cli` ; lire les logs de chargement | ce que contient un modèle, où va la RAM |
| M1-3 | Fiche « tokens, contexte, KV cache » avec calcul de RAM fait à la main | modèle mental du coût mémoire |
| M1-4 | Quantization : comparer Q4_K_M et Q8_0 (taille, RAM, tokens/s, qualité ressentie) | compromis qualité / vitesse / mémoire |

## M2 Servir (semaines 4-6)
| # | Ticket | Apprentissage visé |
|---|---|---|
| M2-1 | `llama-server` + appels `curl` sur `/v1/chat/completions` | API compatible OpenAI, paramètres de génération |
| M2-2 | Client Python (SDK openai pointé sur le serveur local) | intégrer un modèle comme n'importe quelle API |
| M2-3 | Conteneuriser : Dockerfile + Compose, volume de modèles, healthcheck | packaging d'un service d'inférence |
| M2-4 | Lancement au démarrage : unité systemd (Linux) / launchd (Mac) | exploitation d'un service |
| M2-5 | Reverse proxy (Caddy) avec TLS et authentification | exposer proprement un service |

## M3 Mesurer (semaines 7-9)
| # | Ticket | Apprentissage visé |
|---|---|---|
| M3-1 | Script de bench : TTFT (temps au premier token) et tokens/s | savoir mesurer, protocole reproductible |
| M3-2 | Concurrence : 1, 2, 4, 8 requêtes simultanées, slots du serveur | débit vs latence |
| M3-3 | Prometheus + Grafana sur les métriques du serveur | observabilité d'un service LLM |
| M3-4 | Tableau de dimensionnement `docs/sizing.md` (modèle × quant × contexte → RAM, vitesse) | capacity planning |
| M3-5 | Mini-évaluation : 20 questions, 2-3 modèles, notation écrite | évaluer la qualité, pas seulement la vitesse |

## M4 GPU et Mac (semaines 10-12)
| # | Ticket | Apprentissage visé |
|---|---|---|
| M4-1 | Mac : llama.cpp Metal vs MLX-LM, même protocole de bench | mémoire unifiée, autre backend |
| M4-2 | Louer un GPU à l'heure (budget plafonné) et lancer vLLM | environnement GPU, coût réel |
| M4-3 | vLLM vs llama.cpp : batching continu, même protocole | pourquoi vLLM scale mieux |
| M4-4 | Note de coût : €/million de tokens auto-hébergé vs API | raisonner en coût total |

## M5 Passerelle et sécurité (semaines 13-15)
| # | Ticket | Apprentissage visé |
|---|---|---|
| M5-1 | LiteLLM devant les modèles : clés, quotas, logs | passerelle LLM, multi-tenant |
| M5-2 | Routage et fallback entre modèle local et API externe | résilience |
| M5-3 | Prompt injection : démonstration et mitigations | risques propres aux LLM |
| M5-4 | RAG minimal (embeddings + pgvector ou Qdrant) vu côté infra | ce que les équipes applicatives vous demanderont |

## M6 Industrialiser et valoriser (semaines 16-20)
| # | Ticket | Apprentissage visé |
|---|---|---|
| M6-1 | Reproductibilité : `make up` ou Ansible pour monter toute la stack | infra as code |
| M6-2 | CI GitHub Actions : shellcheck, validation Compose, lint | qualité automatisée |
| M6-3 | k3s : déployer un modèle sur Kubernetes | orchestration, requests/limits mémoire |
| M6-4 | Portfolio : README final, schéma d'architecture, article de retour d'expérience | raconter son travail |

---

## Principes du mentor
1. On **comprend avant d'automatiser** : on tape d'abord les commandes à la main, on script ensuite.
2. Chaque ticket produit une **preuve** : sortie de commande, chiffre daté, ou schéma.
3. On se trompe, on note, on corrige : les blocages de la note de session sont de la matière à progresser.
4. Si on va plus vite que prévu, on enchaîne le ticket suivant sans attendre la semaine d'après.
