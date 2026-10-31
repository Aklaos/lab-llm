#!/usr/bin/env bash
# Gestion d'une session de travail : un ticket = une branche = une PR.
#
#   scripts/session.sh start <n°>      ouvre la session sur le ticket n°
#   scripts/session.sh save "message"  commit + push de la branche courante
#   scripts/session.sh done            refuse une note vide, commit du reste, push, relecture du diff + confirmation, fusion, retour sur main
#
# Transparence : chaque commande git/gh lancée est affichée en orange avec « ▶ ».
# start ne demande aucune confirmation ; save en demande deux (commit, push) ;
# done montre le diff de la PR et demande UNE confirmation avant de fusionner (dépôt public).
# Ne pousse jamais sur main : save et done refusent de tourner sur main.
# Aucun hook git n'est activé ici : la garde contre le push sur main est celle de cb et de GitHub.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

die() { echo "✋ $*" >&2; exit 1; }

# Affiche la commande (en orange) puis l'exécute.
run() {
  printf '\033[38;5;208m▶ %s\033[0m\n' "$*"
  "$@"
}

# Pose une question o/N ; réussit seulement si la réponse est « o ».
confirm() {
  local ok
  read -r -p "$1 [o/N] " ok
  [[ "$ok" == "o" ]]
}

for cmd in git gh python3; do
  command -v "$cmd" >/dev/null || die "commande introuvable : $cmd"
done

# Nom générique de la machine pour les notes (jamais le vrai nom d'hôte).
machine_label() {
  case "$(uname -s)" in
    Darwin) echo "macbook" ;;
    Linux)  echo "poste-linux-ubuntu" ;;
    *)      echo "machine" ;;
  esac
}

# "Protéger main et vérifier SSH" -> "proteger-main-et-verifier-ssh"
slugify() {
  python3 - "$1" <<'PY'
import re, sys, unicodedata
s = unicodedata.normalize("NFKD", sys.argv[1]).encode("ascii", "ignore").decode()
s = re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")
print(s[:40].rstrip("-"))
PY
}

# Renseigne $branch, $type et $num à partir du nom de la branche courante (type/num-slug).
branch_info() {
  branch=$(git branch --show-current)
  case "$branch" in
    main|master|"") die "tu es sur '${branch:-détaché}' : lance d'abord « session.sh start <n°> »." ;;
  esac
  type=${branch%%/*}
  rest=${branch#*/}
  num=${rest%%-*}
  [[ "$num" =~ ^[0-9]+$ ]] || die "la branche '$branch' ne suit pas le format type/n°-slug."
}

cmd_start() {
  local n=${1:-}
  [[ "$n" =~ ^[0-9]+$ ]] || die "usage : session.sh start <n° de ticket>"

  run git fetch origin --prune

  # Reprise : une branche existe déjà pour ce ticket (autre machine, session précédente).
  local existing
  existing=$(git for-each-ref --format='%(refname:short)' "refs/remotes/origin/*/${n}-*" | head -n1)
  existing=${existing#origin/}
  if [[ -n "$existing" ]]; then
    echo "↻ Reprise de la branche existante : $existing"
    run git switch "$existing"
    run git pull --ff-only
    return
  fi

  run git switch main
  run git pull --ff-only

  local title label
  title=$(gh issue view "$n" --json title --jq .title)
  label=$(gh issue view "$n" --json labels --jq '.labels[0].name // "chore"')
  branch="$label/$n-$(slugify "$title")"

  echo "→ Ticket #$n : $title"
  echo "→ Branche   : $branch"
  run git switch -c "$branch"

  # Note de session préremplie depuis le modèle.
  local note
  note="docs/sessions/$(date +%F)-$(machine_label)-$n.md"
  echo "▶ création de la note $note"
  sed -e "s|AAAA-MM-JJ|$(date +%F)|" \
      -e "s|ticket #N|ticket #$n|" \
      -e "s|^- Machine : .*|- Machine : $(machine_label)|" \
      -e "s|^- Branche : .*|- Branche : $branch|" \
      docs/sessions/_template.md > "$note"

  run git add -A
  echo
  echo "Fichiers commités dans « $label(#$n): ouvre la session » :"
  git status --short
  echo

  run git commit -m "$label(#$n): ouvre la session"
  run git push -u origin HEAD

  # PR en brouillon, construite depuis le modèle de PR.
  local body
  body=$(sed "s|^Closes #\$|Closes #$n|" .github/pull_request_template.md)
  run gh pr create --draft --title "$label(#$n): $title" --body "$body"

  echo
  echo "✔ Session prête. Note à remplir : $note"
  echo "  Pendant le travail : scripts/session.sh save \"ce que j'ai fait\""
  echo "  Pour finir         : scripts/session.sh done"
}

cmd_save() {
  local msg=${1:-}
  [[ -n "$msg" ]] || die "usage : session.sh save \"message\""
  branch_info

  run git add -A
  if git diff --cached --quiet; then
    echo "Rien de nouveau à commiter."
  else
    echo
    echo "Fichiers qui seront commités :"
    git status --short
    echo
    confirm "Commiter avec le message « $type(#$num): $msg » ?" || { echo "Annulé."; exit 1; }
    run git commit -m "$type(#$num): $msg"
  fi

  echo
  echo "Commits qui vont partir sur GitHub (branche $branch) :"
  git --no-pager log --oneline '@{u}..HEAD' 2>/dev/null || git --no-pager log --oneline -5
  echo
  confirm "Pousser la branche $branch ?" || { echo "Annulé (rien n'est poussé)."; exit 1; }
  run git push -u origin HEAD
}

cmd_done() {
  branch_info

  # Refuse de clôturer si la note de session est restée au modèle.
  local f
  for f in docs/sessions/*-"$num".md; do
    [[ -e "$f" ]] || continue
    ! grep -q '(une phrase)' "$f" || die "la note $f est restée au modèle : remplis-la avant « done »."
    ! grep -qE "^## (Ce que j'ai compris|Ce qui m'a bloqué)" "$f" \
      || die "la note $f contient des rubriques personnelles : elles vont dans /notes/sessions/, pas dans le dépôt public."
  done

  run git add -A
  if ! git diff --cached --quiet; then
    echo "Fichiers commités avant la clôture :"
    git status --short
    run git commit -m "$type(#$num): clôture de la session"
  fi
  run git push -u origin HEAD

  # Dernière relecture humaine : le dépôt est public, tout ce qui est fusionné l'est aussitôt.
  echo
  echo "Fichiers de la PR :"
  git --no-pager diff --stat origin/main...HEAD
  echo
  git --no-pager diff origin/main...HEAD
  echo
  confirm "Relu : fusionner cette PR (squash) et supprimer la branche ?" \
    || { echo "Rien n'est fusionné. Relis la PR (gh pr view --web), corrige, puis relance « done »."; exit 0; }

  run gh pr ready || true     # sort du mode brouillon (sans erreur si déjà prête)
  gh pr view --json url --jq .url

  run gh pr merge --squash --delete-branch
  run git switch main
  run git pull --ff-only
  echo "✔ Ticket #$num terminé et fusionné."
}

case "${1:-}" in
  start) shift; cmd_start "$@" ;;
  save)  shift; cmd_save "$@" ;;
  done)  shift; cmd_done "$@" ;;
  *) sed -n '2,11p' "$0"; exit 1 ;;
esac
