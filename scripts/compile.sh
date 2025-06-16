#!/usr/bin/env bash
set -e

EA_PATH="IntegratedPA_EA/MQL5/Experts/IntegratedPA_EA.mq5"
LOG_DIR="build"
LOG_FILE="$LOG_DIR/compile.log"
COMPILER_DIR="compiler"
COMPILER_EXE="$COMPILER_DIR/metaeditor64.exe"

mkdir -p "$LOG_DIR" "$COMPILER_DIR"

if ! command -v wine >/dev/null; then
  echo "wine not available; skipping compile" >&2
  echo "compile skipped: wine not installed" > "$LOG_FILE"
  exit 0
fi

if [ ! -f "$COMPILER_EXE" ]; then
  echo "Downloading MetaEditor..."
  curl -L -o "$COMPILER_EXE" "https://download.mql5.com/cdn/web/metaquotes.software/mt5/metaeditor64.exe"
fi

# Compila com Werror para tratar warnings como erros
wine "$COMPILER_EXE" /compile:"$EA_PATH" /log:"$LOG_FILE" /include:IntegratedPA_EA/MQL5/Include /Werror

# Checa se houve algum erro na compilação
if grep -E "error|warning" "$LOG_FILE"; then
  echo "Compilation completed with issues. Check $LOG_FILE"
  exit 1
else
  echo "Compilation succeeded with no errors or warnings."
fi
