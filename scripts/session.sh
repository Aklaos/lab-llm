#!/usr/bin/env bash
# Gestion d'une session de travail : un ticket = une branche = une PR.
#
#   scripts/session.sh start <n°>      ouvre la session sur le ticket n°
#   scripts/session.sh save "message"  commit + push de la branche courante
#   scripts/session.sh done            PR prête, puis fusion (avec confirmation)
#
# Ne pousse jamais sur main : start refuse de partir de main sans créer de branche,
# save et done refusent de tourner sur main.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

die() { echo "✋ $*" >&2; exit 1; }

for cmd in git gh python3; do
  command -v "$cmd" >/dev/null || die "commande introuvable : $cmd"
done

# Active le hook anti-push-sur-main (utile sur un clone neuf, ex. le Mac).
git config core.hooksPath scripts/hooks

# "Protéger main et vérifier SSH" -> "proteger-main-et-verifier-ssh"
slugify() {
  python3 - "$1" <<'PY'
import re, sys, unicodedata
s = unicodedata.normalize("NFKD", sys.argv[1]).encode("ascii", "ignore").decode()
s = re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")
print(s[:40].rstrip("-"))
PY
}

# Renseigne $type et $num à partir du nom de la branche courante (type/num-slug).
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

  git fetch origin --prune

  # Reprise : une branche existe déjà pour ce ticket (autre machine, session précédente).
  local existing
  existing=$(git for-each-ref --format='%(refname:short)' "refs/remotes/origin/*/${n}-*" | head -n1)
  existing=${existing#origin/}
  if [[ -n "$existing" ]]; then
    echo "↻ Reprise de la branche existante : $existing"
    git switch "$existing"
    git pull --ff-only
    return
  fi

  git switch main
  git pull --ff-only

  local title label
  title=$(gh issue view "$n" --json title --jq .title)
  label=$(gh issue view "$n" --json labels --jq '.labels[0].name // "chore"')
  branch="$label/$n-$(slugify "$title")"

  echo "→ Ticket #$n : $title"
  echo "→ Branche   : $branch"
  git switch -c "$branch"

  # Note de session préremplie depuis le modèle.
  local note
  note="docs/sessions/$(date +%F)-$(hostname -s)-$n.md"
  sed -e "s|AAAA-MM-JJ|$(date +%F)|" \
      -e "s|ticket #N|ticket #$n|" \
      -e "s|^- Machine : .*|- Machine : $(hostname -s)|" \
      -e "s|^- Branche : .*|- Branche : $branch|" \
      docs/sessions/_template.md > "$note"

  git add -A
  git commit -m "$label(#$n): ouvre la session"
  git push -u origin HEAD

  # PR en brouillon, construite depuis le modèle de PR.
  local body
  body=$(sed "s|^Closes #\$|Closes #$n|" .github/pull_request_template.md)
  gh pr create --draft --title "$label(#$n): $title" --body "$body"

  echo
  echo "✔ Session prête. Note à remplir : $note"
  echo "  Pendant le travail : scripts/session.sh save \"ce que j'ai fait\""
  echo "  Pour finir         : scripts/session.sh done"
}

cmd_save() {
  local msg=${1:-}
  [[ -n "$msg" ]] || die "usage : session.sh save \"message\""
  branch_info
  git add -A
  if git diff --cached --quiet; then
    echo "Rien de nouveau à commiter."
  else
    git status --short
    git commit -m "$type(#$num): $msg"
  fi
  git push -u origin HEAD
}

cmd_done() {
  branch_info
  [[ -z "$(git status --porcelain)" ]] || die "il reste des changements non commités : lance « session.sh save "message" » d'abord."
  git push -u origin HEAD

  gh pr ready || true     # sort du mode brouillon (sans erreur si déjà prête)
  gh pr view --json url --jq .url
  echo
  read -r -p "Fusionner cette PR (squash) et supprimer la branche ? [o/N] " ok
  [[ "$ok" == "o" ]] || { echo "PR prête, non fusionnée. Relis-la puis relance « done »."; exit 0; }

  gh pr merge --squash --delete-branch
  git switch main
  git pull --ff-only
  echo "✔ Ticket #$num terminé et fusionné."
}

case "${1:-}" in
  start) shift; cmd_start "$@" ;;
  save)  shift; cmd_save "$@" ;;
  done)  shift; cmd_done "$@" ;;
  *) sed -n '2,9p' "$0"; exit 1 ;;
esac
