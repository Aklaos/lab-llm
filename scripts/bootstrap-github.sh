#!/usr/bin/env bash
# Crée les labels, milestones et tickets du programme (docs/PROGRAMME.md).
# À lancer UNE SEULE FOIS, depuis la racine du dépôt, avec `gh` authentifié.
# Relancer créerait des doublons de tickets.
set -euo pipefail

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "Dépôt cible : $REPO"
read -r -p "Créer labels, milestones et tickets ici ? [o/N] " ok
[[ "$ok" == "o" ]] || { echo "Annulé."; exit 1; }

# --- Labels -----------------------------------------------------------------
for l in feat bench docs chore; do
  gh label create "$l" --force >/dev/null
done

# --- Milestones -------------------------------------------------------------
milestone() {
  gh api "repos/$REPO/milestones" -f title="$1" -f description="$2" >/dev/null
  echo "milestone : $1"
}
milestone "M0 Socle"                         "Dépôt, workflow, inventaire matériel"
milestone "M1 Premier contact"               "llama.cpp, premier modèle, quantization"
milestone "M2 Servir"                        "API, Docker, systemd, reverse proxy"
milestone "M3 Mesurer"                       "Bench, observabilité, dimensionnement, évaluation"
milestone "M4 GPU et Mac"                    "Metal/MLX, vLLM sur GPU loué, coûts"
milestone "M5 Passerelle et sécurité"        "LiteLLM, routage, prompt injection, RAG"
milestone "M6 Industrialiser et valoriser"   "IaC, CI, Kubernetes, portfolio"

# --- Tickets ----------------------------------------------------------------
# ticket <milestone> <label> <titre> <objectif> <preuve>
ticket() {
  local body
  body=$(printf '## Objectif\n%s\n\n## Preuve attendue\n%s\n\n## Rappel\nBranche `%s/<n°>-<slug>`, note dans `docs/sessions/`, PR avec `Closes #<n°>`. Jamais de push sur main.\n' "$4" "$5" "$2")
  gh issue create --milestone "$1" --label "$2" --title "$3" --body "$body" >/dev/null
  echo "ticket    : $3"
}

ticket "M0 Socle" chore "M0-1 Charte du dépôt" \
  "README, .gitignore, hook pre-push, templates de PR et de session." \
  "PR mergée ; un push direct sur main est refusé par le hook."
ticket "M0 Socle" chore "M0-2 Protéger main et vérifier SSH/gh sur les 2 machines" \
  "Ruleset GitHub empêchant le push direct sur main ; clone et auth fonctionnels sur PC et Mac." \
  "Tentative de push sur main refusée par GitHub ; capture ou sortie de commande."
ticket "M0 Socle" docs "M0-3 Inventaire matériel" \
  "Écrire scripts/inventory.sh (CPU, RAM, GPU, disque) et une fiche par machine dans docs/hardware/." \
  "Deux fiches : pc-linux.md et macbook.md."

ticket "M1 Premier contact" feat "M1-1 Compiler llama.cpp" \
  "Compiler llama.cpp depuis les sources (CPU sur Linux, Metal sur Mac) en lisant les options cmake." \
  "Binaire llama-cli qui répond à --version ; options de build notées."
ticket "M1 Premier contact" feat "M1-2 Premier modèle GGUF avec llama-cli" \
  "Télécharger un petit modèle (1-3B), générer du texte, lire les logs de chargement." \
  "Extrait annoté des logs : taille du modèle, couches, KV cache, tokens/s."
ticket "M1 Premier contact" docs "M1-3 Fiche tokens, contexte, KV cache" \
  "Expliquer avec ses mots et calculer à la main la RAM d'un modèle + KV cache pour un contexte donné." \
  "docs/notes/kv-cache.md avec un calcul vérifié contre les logs réels."
ticket "M1 Premier contact" bench "M1-4 Quantization Q4_K_M vs Q8_0" \
  "Comparer le même modèle en deux quantizations : taille, RAM, tokens/s, qualité ressentie." \
  "Tableau de résultats daté dans benchmarks/."

ticket "M2 Servir" feat "M2-1 llama-server et appels curl" \
  "Lancer llama-server et interroger /v1/chat/completions avec curl." \
  "Commande curl et réponse JSON commentée."
ticket "M2 Servir" feat "M2-2 Client Python" \
  "Appeler le serveur local avec le SDK openai (base_url personnalisée)." \
  "Script benchmarks/ou scripts/ client fonctionnel, avec streaming."
ticket "M2 Servir" feat "M2-3 Conteneuriser avec Docker Compose" \
  "Dockerfile ou image officielle, volume de modèles, healthcheck." \
  "docker compose up fonctionne ; healthcheck au vert."
ticket "M2 Servir" feat "M2-4 Lancement au démarrage (systemd / launchd)" \
  "Unité systemd sur Linux, launchd sur Mac." \
  "Service qui redémarre seul après reboot ou kill."
ticket "M2 Servir" feat "M2-5 Reverse proxy Caddy avec TLS et auth" \
  "Placer Caddy devant le serveur : TLS et authentification." \
  "Requête sans clé refusée, avec clé acceptée."

ticket "M3 Mesurer" bench "M3-1 Script de bench TTFT et tokens/s" \
  "Écrire un script de mesure reproductible (protocole documenté)." \
  "Résultats CSV + protocole écrit."
ticket "M3 Mesurer" bench "M3-2 Concurrence 1/2/4/8" \
  "Mesurer l'effet de la concurrence et des slots du serveur." \
  "Graphique ou tableau débit/latence selon la concurrence."
ticket "M3 Mesurer" feat "M3-3 Prometheus et Grafana" \
  "Brancher les métriques du serveur dans Prometheus et construire un dashboard." \
  "Capture du dashboard pendant un bench."
ticket "M3 Mesurer" docs "M3-4 Tableau de dimensionnement" \
  "docs/sizing.md : modèle × quantization × contexte → RAM et vitesse mesurées." \
  "Tableau avec chiffres issus de vos mesures."
ticket "M3 Mesurer" bench "M3-5 Mini-évaluation de qualité" \
  "20 questions, 2-3 modèles, grille de notation écrite à l'avance." \
  "Résultats et analyse dans benchmarks/eval/."

ticket "M4 GPU et Mac" bench "M4-1 Mac : llama.cpp Metal vs MLX-LM" \
  "Même protocole de bench sur les deux backends du MacBook." \
  "Tableau comparatif."
ticket "M4 GPU et Mac" feat "M4-2 Louer un GPU et lancer vLLM" \
  "Louer un GPU à l'heure (budget plafonné à l'avance) et servir un modèle avec vLLM." \
  "vLLM répond ; coût réel de la session noté."
ticket "M4 GPU et Mac" bench "M4-3 vLLM vs llama.cpp" \
  "Comparer sous concurrence avec le même protocole." \
  "Tableau et explication du batching continu avec vos mots."
ticket "M4 GPU et Mac" docs "M4-4 Note de coût par million de tokens" \
  "Comparer auto-hébergé et API commerciale." \
  "docs/cout.md avec hypothèses explicites."

ticket "M5 Passerelle et sécurité" feat "M5-1 LiteLLM devant les modèles" \
  "Clés par utilisateur, quotas, logs." \
  "Deux clés avec des quotas différents, démontrés."
ticket "M5 Passerelle et sécurité" feat "M5-2 Routage et fallback" \
  "Basculer sur une API externe si le modèle local est indisponible." \
  "Test d'arrêt du modèle local, bascule observée."
ticket "M5 Passerelle et sécurité" docs "M5-3 Prompt injection" \
  "Démontrer une injection sur un cas simple, puis tester des mitigations." \
  "Note avec attaque, mitigation et limites."
ticket "M5 Passerelle et sécurité" feat "M5-4 RAG minimal côté infra" \
  "Embeddings + pgvector ou Qdrant, requête de bout en bout." \
  "Question posée, passages retrouvés, réponse sourcée."

ticket "M6 Industrialiser et valoriser" chore "M6-1 Stack reproductible (make up ou Ansible)" \
  "Monter toute la stack depuis un clone vierge en une commande." \
  "Test sur une machine propre (ou VM)."
ticket "M6 Industrialiser et valoriser" chore "M6-2 CI GitHub Actions" \
  "shellcheck, validation Compose, lint markdown." \
  "Pipeline vert sur une PR."
ticket "M6 Industrialiser et valoriser" feat "M6-3 Déployer sur k3s" \
  "Déployer un modèle sur Kubernetes avec requests/limits mémoire cohérents." \
  "Pod Running, requête réussie, OOMKilled provoqué et compris."
ticket "M6 Industrialiser et valoriser" docs "M6-4 Portfolio" \
  "README final, schéma d'architecture, article de retour d'expérience." \
  "Article publié ou prêt à publier."

echo "Terminé."
