#!/usr/bin/env bash
# Décrit la machine courante (CPU, RAM, GPU, disque) dans docs/hardware/<libellé>.md.
# La fiche est locale (dossier ignoré par git) : elle contient des infos personnelles.
# Le nom d'hôte n'est jamais lu ni écrit.
set -euo pipefail
cd "$(dirname "$0")/.."

case "$(uname -s)" in
  Darwin) label=macbook ;;
  Linux)  label=poste-linux-ubuntu ;;
  *)      label=machine ;;
esac
out="docs/hardware/$label.md"

{
  echo "# Fiche matériel : $label"
  echo
  echo "Générée le $(date +%F) par scripts/inventory.sh (fichier local, non versionné)."
  echo

  if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "## Système"
    echo "- macOS $(sw_vers -productVersion), $(uname -m)"
    echo "## CPU"
    echo "- Modèle : $(sysctl -n machdep.cpu.brand_string)"
    echo "- Cœurs : $(sysctl -n hw.physicalcpu) physiques, $(sysctl -n hw.logicalcpu) logiques"
    echo "## Mémoire (unifiée CPU/GPU)"
    echo "- Total : $(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 )) Go"
    echo "## GPU"
    echo "- $(system_profiler SPDisplaysDataType 2>/dev/null | awk -F': ' '/Chipset Model/ {print $2; exit}') (Metal)"
  else
    echo "## Système"
    echo "- $(. /etc/os-release && echo "$PRETTY_NAME"), noyau $(uname -r)"
    echo "## CPU"
    echo "- Modèle : $(lscpu | awk -F': *' '/^Model name/ {print $2}')"
    echo "- Threads : $(nproc)"
    echo "- Instructions utiles : $(grep -o -wE 'avx2|avx512f|fma' /proc/cpuinfo | sort -u | tr '\n' ' ')"
    echo "## Mémoire"
    free -h | awk '/^Mem:/ {print "- Total : " $2 ", disponible : " $7}'
    echo "## GPU"
    if command -v nvidia-smi >/dev/null; then
      echo "- $(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader)"
    else
      echo "- Aucun GPU NVIDIA détecté (inférence sur CPU)"
    fi
  fi

  echo "## Disque (dossier du projet)"
  df -h . | awk 'NR==2 {print "- Libre : " $4 " sur " $2}'
} > "$out"

echo "Fiche écrite : $out"
cat "$out"
