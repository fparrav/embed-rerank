#!/usr/bin/env bash
# Stop embed-rerank server
# Usage: ./tools/server-stop-conda.sh
set -euo pipefail

PIDFILE="/tmp/embed-rerank.pid"
GRACE_SECONDS=5

if [[ ! -f "$PIDFILE" ]]; then
  echo "❌ No PID file found at $PIDFILE"
  echo "   Server may not be running or was started manually."
  echo ""
  echo "💡 To find and kill manually:"
  echo "   ps aux | grep uvicorn | grep embed-rerank"
  echo "   kill <PID>"
  exit 1
fi

PID=$(cat "$PIDFILE")

if ! kill -0 "$PID" 2>/dev/null; then
  echo "⚠️  Process $PID not running (stale PID file)"
  rm -f "$PIDFILE"
  exit 0
fi

echo "🛑 Stopping embed-rerank server (PID $PID)..."
kill -TERM "$PID" 2>/dev/null || true

# Wait for graceful shutdown
for i in $(seq 1 "$GRACE_SECONDS"); do
  if ! kill -0 "$PID" 2>/dev/null; then
    echo "✅ Server stopped successfully"
    rm -f "$PIDFILE"
    exit 0
  fi
  sleep 1
done

# Force kill if still running
echo "⚠️  Graceful shutdown timeout, force killing..."
kill -KILL "$PID" 2>/dev/null || true
sleep 1

if kill -0 "$PID" 2>/dev/null; then
  echo "❌ Failed to stop PID $PID"
  exit 2
fi

rm -f "$PIDFILE"
echo "✅ Server stopped (force killed)"
