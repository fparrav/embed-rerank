#!/usr/bin/env bash
# Start embed-rerank server with conda environment
# Usage: ./tools/server-start-conda.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PIDFILE="/tmp/embed-rerank.pid"
LOGFILE="/tmp/embed-rerank.log"
CONDA_ENV="embed-rerank"
CONDA_BASE="/opt/homebrew/anaconda3"

# Check if already running
if [[ -f "$PIDFILE" ]]; then
  PID=$(cat "$PIDFILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo "✅ Server already running (PID $PID)"
    echo "   Logs: tail -f $LOGFILE"
    echo "   Stop: ./tools/server-stop-conda.sh"
    exit 0
  else
    echo "⚠️  Removing stale PID file"
    rm -f "$PIDFILE"
  fi
fi

# Load .env if exists
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
  echo "✅ Loaded .env configuration"
fi

# Set defaults from .env or use fallbacks
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-9000}"

echo "🚀 Starting embed-rerank server..."
echo "   Environment: conda ($CONDA_ENV)"
echo "   Backend: ${BACKEND:-auto}"
echo "   Embedding Model: ${MODEL_NAME:-not set}"
echo "   Reranker Model: ${RERANKER_MODEL_ID:-not set}"
echo "   Listen: http://${HOST}:${PORT}"
echo "   Logs: $LOGFILE"

# Start server in background
nohup "$CONDA_BASE/envs/$CONDA_ENV/bin/python" -m uvicorn app.main:app \
  --host "$HOST" \
  --port "$PORT" \
  >> "$LOGFILE" 2>&1 &

PID=$!
echo $PID > "$PIDFILE"

# Wait a moment and check if it started
sleep 2
if kill -0 "$PID" 2>/dev/null; then
  echo "✅ Server started successfully (PID $PID)"
  echo ""
  echo "📋 Commands:"
  echo "   View logs:  tail -f $LOGFILE"
  echo "   Health:     curl http://localhost:$PORT/health/"
  echo "   Stop:       ./tools/server-stop-conda.sh"
else
  echo "❌ Server failed to start. Check logs:"
  tail -20 "$LOGFILE"
  rm -f "$PIDFILE"
  exit 1
fi
