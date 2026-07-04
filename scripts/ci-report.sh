#!/usr/bin/env bash
# Distils build/test logs into a small markdown report and publishes it to the
# ci-logs branch so an unauthenticated observer can read failure detail via
# raw.githubusercontent.com (Actions log downloads require a token; this does not).
set -uo pipefail

: "${GITHUB_TOKEN:?GITHUB_TOKEN must be exported}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set}"

BRANCH="${GITHUB_REF_NAME:-local}"
OUT=$(mktemp -d)
REPORT="$OUT/latest.md"

{
  echo "# CI report — ${BRANCH} @ ${GITHUB_SHA:-unknown}"
  echo ""
  echo "- run: ${GITHUB_RUN_ID:-?} attempt ${GITHUB_RUN_ATTEMPT:-?}"
  echo "- outcome: ${OUTCOME:-unknown}"
  echo "- date: $(date -u +%FT%TZ)"
  echo "- url: ${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID:-0}"

  for f in build/lint.log build/test-packages.log build/app-build.log; do
    [ -f "$f" ] || continue
    echo ""
    echo "## ${f}"
    echo ""
    echo "### errors and warnings"
    echo '```'
    grep -E "(error|warning):" "$f" | grep -v "warnings-as-errors" | grep -v "appintentsmetadataprocessor" | sort -u | head -120 || true
    echo '```'
    echo ""
    echo "### summary lines"
    echo '```'
    grep -E "(Test Suite|Test run|Executed|tests? passed|tests? failed|BUILD SUCCEEDED|BUILD FAILED|TEST SUCCEEDED|TEST FAILED|Linting|Done linting|violations)" "$f" | tail -60 || true
    echo '```'
    if grep -qE "(recorded an issue|Expectation failed|✘ Test)" "$f"; then
      echo ""
      echo "### test failures"
      echo '```'
      grep -E "(recorded an issue|Expectation failed|✘ Test)" "$f" | head -40 || true
      echo '```'
    fi
  done

  if [ -f build/coverage.txt ]; then
    echo ""
    echo "## coverage (per target)"
    echo '```'
    cat build/coverage.txt | head -60 || true
    echo '```'
  fi
} > "$REPORT"

REMOTE="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

if git clone -q --depth 1 --branch ci-logs "$REMOTE" "$OUT/repo" 2>/dev/null; then
  :
else
  mkdir -p "$OUT/repo"
  git -C "$OUT/repo" init -q -b ci-logs
  git -C "$OUT/repo" remote add origin "$REMOTE"
fi

mkdir -p "$OUT/repo/ci/${BRANCH}"
cp "$REPORT" "$OUT/repo/ci/${BRANCH}/latest.md"

cd "$OUT/repo"
git config user.name "ci"
git config user.email "ci@users.noreply.github.com"
git add -A
if git commit -qm "ci report ${BRANCH} ${GITHUB_SHA:-}"; then
  git push -q origin ci-logs --force-with-lease 2>/dev/null || git push -qf origin ci-logs
fi

echo "Published ci report for ${BRANCH}"
