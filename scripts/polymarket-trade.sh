#!/bin/bash
# Polymarket Trading Bot Wrapper
# Activates venv and runs trading commands

WORKSPACE="/root/.openclaw/workspace"
VENV="$WORKSPACE/.venv"
SCRIPT="$WORKSPACE/scripts/polymarket-trade.py"

# Activate virtual environment
source "$VENV/bin/activate"

# Run the Python script with all arguments
python3 "$SCRIPT" "$@"
