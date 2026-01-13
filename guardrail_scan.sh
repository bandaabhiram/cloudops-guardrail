#!/usr/bin/env bash
set -euo pipefail

# CloudOps Guardrail Box - IaC scanner
# - Checkov (Terraform/Azure) + custom checks (GR_AZURE_00X)
# - Trivy config (Terraform misconfig)
# - Writes TXT/JSON/SARIF + a Markdown summary

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IAC_ROOT="$ROOT/iac/terraform"
REPORTS_ROOT="$ROOT/reports"
POLICY_DIR="$ROOT/policies/checkov"

TARGET="${1:-}"
if [[ -z "$TARGET" || ( "$TARGET" != "good" && "$TARGET" != "bad" ) ]]; then
  echo "Usage: $0 {good|bad}"
  exit 1
fi

IAC_DIR="$IAC_ROOT/$TARGET"
OUT_DIR="$REPORTS_ROOT/$TARGET"
TS="$(date -u +"%Y-%m-%dT%H-%M-%SZ")"

mkdir -p "$OUT_DIR"

echo "[*] Scanning IaC folder: $IAC_DIR"
echo "[*] Output folder:      $OUT_DIR"
echo "[*] Timestamp:          $TS"
echo

# File names
C_TXT="$OUT_DIR/checkov_${TARGET}_${TS}.txt"
C_JSON="$OUT_DIR/checkov_${TARGET}_${TS}.json"
C_SARIF="$OUT_DIR/checkov_${TARGET}_${TS}.sarif"

T_TXT="$OUT_DIR/trivy_${TARGET}_${TS}.txt"
T_JSON="$OUT_DIR/trivy_${TARGET}_${TS}.json"
T_SARIF="$OUT_DIR/trivy_${TARGET}_${TS}.sarif"

MD="$OUT_DIR/guardrail_report_${TARGET}_${TS}.md"

# ---- CHECKOV ----
echo "[*] Running Checkov (built-in + custom GR_AZURE checks)..."

# Note:
# --run-all-external-checks is REQUIRED on your Checkov version to execute external checks.
# We soft-fail Checkov so the script continues to generate reports even if checks fail.
set +e
checkov -d "$IAC_DIR" --framework terraform \
  --external-checks-dir "$POLICY_DIR" \
  --run-all-external-checks \
  -o cli > "$C_TXT"

checkov -d "$IAC_DIR" --framework terraform \
  --external-checks-dir "$POLICY_DIR" \
  --run-all-external-checks \
  -o json > "$C_JSON"

checkov -d "$IAC_DIR" --framework terraform \
  --external-checks-dir "$POLICY_DIR" \
  --run-all-external-checks \
  -o sarif > "$C_SARIF"
set -e

# ---- TRIVY ----
echo "[*] Running Trivy config scan..."
# Trivy exits non-zero when it finds issues; we still want reports, so soft-fail.
set +e
trivy config "$IAC_DIR" --format table > "$T_TXT"
trivy config "$IAC_DIR" --format json  > "$T_JSON"
trivy config "$IAC_DIR" --format sarif > "$T_SARIF"
set -e

# ---- MARKDOWN SUMMARY ----
echo "[*] Writing Markdown report..."

{
  echo "# CloudOps Guardrail Report — **$TARGET**"
  echo
  echo "- **Timestamp (UTC):** \`$TS\`"
  echo "- **IaC folder:** \`$IAC_DIR\`"
  echo "- **Reports folder:** \`$OUT_DIR\`"
  echo
  echo "## Checkov summary"
  echo
  # Pull the first occurrence of the summary line
  grep -m 1 -E "Passed checks:|Failed checks:|Skipped checks:" "$C_TXT" || true
  grep -m 1 -E "^Passed checks:" "$C_TXT" || true
  echo
  echo "### Custom checks (GR_AZURE)"
  echo
  if grep -q "GR_AZURE_" "$C_TXT"; then
    grep -E "Check: GR_AZURE_|FAILED for resource:|PASSED for resource:" "$C_TXT" | sed -n '1,60p'
    echo
    echo "_(showing first 60 related lines)_"
  else
    echo "_No GR_AZURE checks found in this output._"
    echo
    echo "If you expected custom checks, confirm:"
    echo "- policies path exists: \`$POLICY_DIR\`"
    echo "- script includes: \`--run-all-external-checks\`"
  fi
  echo
  echo "## Trivy summary"
  echo
  # Trivy "Report Summary" + first finding headings (keeps it short)
  if grep -q "Report Summary" "$T_TXT"; then
    awk 'BEGIN{p=0} /Report Summary/{p=1} p==1{print} /Failures:/{exit}' "$T_TXT" || true
  else
    echo "_Trivy output not found or empty._"
  fi
  echo
  echo "## Artifacts"
  echo
  echo "- Checkov TXT:  \`$(basename "$C_TXT")\`"
  echo "- Checkov JSON: \`$(basename "$C_JSON")\`"
  echo "- Checkov SARIF:\`$(basename "$C_SARIF")\`"
  echo "- Trivy TXT:    \`$(basename "$T_TXT")\`"
  echo "- Trivy JSON:   \`$(basename "$T_JSON")\`"
  echo "- Trivy SARIF:  \`$(basename "$T_SARIF")\`"
  echo
} > "$MD"

echo "[+] Done."
echo "[+] Markdown report: $MD"
echo "[+] SARIF files:     $OUT_DIR/*.sarif"
