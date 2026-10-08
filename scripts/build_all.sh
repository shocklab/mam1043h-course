#!/usr/bin/env bash
# build_all.sh — Parse all MAM1043H Mathematica notebooks into Hugo content pages.
#
# Usage:
#   ./scripts/build_all.sh [notebooks-dir]
#
# Default notebooks dir: /Users/jonathanshock/Cursor folders/Teaching/MAM2046/MAM1043H

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
NB_DIR="${1:-/Users/jonathanshock/Cursor folders/Teaching/MAM2046/MAM1043H}"

PARSER="$SCRIPT_DIR/parse_nb.py"

echo "=== Building all MAM1043H notebooks ==="
echo "  Notebooks: $NB_DIR"
echo "  Output:    $PROJECT_DIR/content/"
echo ""

# Map: nb_file|output_md|weight|images_dir|title_override|extra_flags
NOTEBOOKS=(
  # Section 1: Introduction
  "MAM1043part1a.nb|sec1-1-overview.md|11|part1a|1.1 Overview of the Course|"
  "MAM1043part1b.nb|sec1-2a-history-beginnings.md|12|part1b|1.2a History of Dynamics — Beginnings|"
  "MAM1043part1c.nb|sec1-2b-history-poincare.md|13|part1c|1.2b History of Dynamics — Poincaré and Chaos|"
  "MAM1043part1d.nb|sec1-3-systems-of-differential-equations.md|14|part1d|1.3 Systems of Differential Equations|"
  "MAM1043part1e.nb|sec1-4-phase-space.md|15|part1e|1.4 Phase Space|"
  "MAM1043part1f.nb|sec1-5-spectrum-of-systems.md|16|part1f|1.5 Spectrum of Systems of Differential Equations|"
  "MAM1043part1exercises.nb|sec1-6-exercises.md|17|part1exercises|1.6 Exercises for Part 1|"

  # Section 2: Flows on the Line
  "MAM1043part2a.nb|sec2-1-fixed-points-and-trajectories.md|21|part2a|2.1 Fixed Points and Trajectories|"
  "MAM1043part2b.nb|sec2-2-fixed-points-and-stability.md|22|part2b|2.2 Fixed Points and their Stability|"
  "MAM1043part2c.nb|sec2-3-linear-stability-analysis.md|23|part2c|2.3 Linear Stability Analysis|"
  "MAM1043part2d.nb|sec2-4-existence-and-uniqueness.md|24|part2d|2.4 Existence and Uniqueness of Solutions|"
  "MAM1043part2e.nb|sec2-5-absence-of-oscillations.md|25|part2e|2.5 Absence of Oscillations|"
  "MAM1043part2f.nb|sec2-6-potentials.md|26|part2f|2.6 Potentials|"
  "MAM1043part2g.nb|sec2-7a-solving-on-computer.md|27|part2g|2.7a Solving Equations on the Computer|"
  "MAM1043part2h.nb|sec2-7b-back-to-basics.md|28|part2h|2.7b Back to Basics — Phase Spaces and Phase Portraits|"
  # NOTE: sec2-8-exercises.md is hand-curated (cleaner section headings &
  # (a)(b)(c) sub-labels than the auto-parser produces). Re-enable this
  # entry only if you want to regenerate from source.
  # "MAM1043part2exercises.nb|sec2-8-exercises.md|29|part2exercises|2.8 Exercises for Part 2|"
  "MAM1043part2answers.nb|sec2-8-answers.md|30|part2answers|2.8 Answers to Exercises for Part 2|"

  # Section 3: Bifurcations
  "MAM1043part3a.nb|sec3-1-saddle-node-bifurcation.md|31|part3a|3.1 & 3.2 Introduction and Saddle-Node Bifurcations|"
  "MAM1043part3b.nb|sec3-3-transcritical-bifurcation.md|32|part3b|3.3 Transcritical Bifurcations|"
  "MAM1043part3c.nb|sec3-4-pitchfork-bifurcation.md|33|part3c|3.4 Pitchfork Bifurcations|"
  "MAM1043part3d.nb|sec3-5-combinations-of-bifurcations.md|34|part3d|3.5 Combinations of Bifurcations|"
  "MAM1043part3e.nb|sec3-6-chaos-and-logistic-map.md|35|part3e|3.6 Chaos and the Logistic Map|"
  "MAM1043part3f.nb|sec3-7a-imperfect-bifurcations.md|36|part3f|3.7a Imperfect Bifurcations and Catastrophes|"
  "MAM1043part3fii.nb|sec3-7b-imperfect-bifurcations-2.md|37|part3fii|3.7b Imperfect Bifurcations and Catastrophes (Part 2)|"
  "MAM1043part3exercises.nb|sec3-8-exercises.md|38|part3exercises|3.8 Exercises for Part 3|"
  "MAM1043part3exercises1a.nb|sec3-8-exercise-1a.md|39|part3exercises1a|3.8 Exercise 1a|"
  "MAM1043part3exercises1b.nb|sec3-8-exercise-1b.md|40|part3exercises1b|3.8 Exercise 1b|"
  "MAM1043part3exercises1c.nb|sec3-8-exercise-1c.md|41|part3exercises1c|3.8 Exercise 1c|"
  "MAM1043part3exercises1d.nb|sec3-8-exercise-1d.md|42|part3exercises1d|3.8 Exercise 1d|"
  "MAM1043part3exercises4b.nb|sec3-8-exercise-4b.md|43|part3exercises4b|3.8 Exercise 4b|"
  "MAM1043part3exercises4c.nb|sec3-8-exercise-4c.md|44|part3exercises4c|3.8 Exercise 4c|"
  "MAM1043part3exercises4d.nb|sec3-8-exercise-4d.md|45|part3exercises4d|3.8 Exercise 4d|"
  "MAM1043part3exercises4e.nb|sec3-8-exercise-4e.md|46|part3exercises4e|3.8 Exercise 4e|"
  "MAM1043part3exercises5b.nb|sec3-8-exercise-5b.md|47|part3exercises5b|3.8 Exercise 5b|"

  # Section 4: Linear Systems in Two Dimensions
  "MAM1043part4a.nb|sec4-1-intro-2d-linear.md|61|part4a|4.1 Introduction to Linear Systems in Two Dimensions|"
  "MAM1043part4b.nb|sec4-2-classification-part-1.md|62|part4b|4.2 Classification of Linear Systems — Part 1|"
  "MAM1043part4c.nb|sec4-3-classification-part-2.md|63|part4c|4.3 Classification of Linear Systems — Part 2|"
  "MAM1043part4d.nb|sec4-4-love-affairs.md|64|part4d|4.4 Application — Love Affairs|"
  "MAM1043part4exercises.nb|sec4-5-exercises.md|65|part4exercises|4.5 Exercises for Part 4|"
  "MAM1043part4answers.nb|sec4-5-answers.md|66|part4answers|4.5 Answers to Exercises for Part 4|"
)

TOTAL=${#NOTEBOOKS[@]}
SUCCESS=0
FAILED=0

for entry in "${NOTEBOOKS[@]}"; do
  IFS='|' read -r nb_file md_file weight img_dir title_override extra_flags <<< "$entry"

  nb_path="$NB_DIR/$nb_file"
  md_path="$PROJECT_DIR/content/$md_file"

  if [ ! -f "$nb_path" ]; then
    echo "SKIP: $nb_file (not found)"
    FAILED=$((FAILED + 1))
    continue
  fi

  echo "[$((SUCCESS + FAILED + 1))/$TOTAL] $nb_file → $md_file"
  TITLE_ARG=()
  if [ -n "$title_override" ]; then
    TITLE_ARG=(--title "$title_override")
  fi

  python3 "$PARSER" "$nb_path" "$md_path" \
    --images-dir "/images/$img_dir" \
    --weight "$weight" "${TITLE_ARG[@]}" $extra_flags 2>&1 | grep -v "UserWarning" | sed 's/^/  /'

  if [ $? -eq 0 ]; then
    SUCCESS=$((SUCCESS + 1))
  else
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "=== Done ==="
echo "  Success: $SUCCESS / $TOTAL"
echo "  Failed:  $FAILED / $TOTAL"
