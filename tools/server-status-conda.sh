#!/usr/bin/env bash
# Check embed-rerank server status
# Usage: ./tools/server-status-conda.sh
set -euo pipefail

PIDFILE="/tmp/embed-rerank.pid"
LOGFILE="/tmp/embed-rerank.log"
PORT="${PORT:-9000}"

echo "🔍 embed-rerank Server Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check PID file
if [[ -f "$PIDFILE" ]]; then
  PID=$(cat "$PIDFILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo "✅ Server is RUNNING"
    echo "   PID: $PID"
    
    # Check HTTP health endpoint
    if curl -s "http://localhost:$PORT/health/" > /dev/null 2>&1; then
      echo "   HTTP: ✅ Responding on port $PORT"
      echo ""
      echo "📊 Health Check:"
      curl -s "http://localhost:$PORT/health/" | python3 -m json.tool 2>/dev/null || echo "   (could not parse JSON)"
    else
      echo "   HTTP: ❌ Not responding on port $PORT"
    fi
    
    # Show recent logs
    if [[ -f "$LOGFILE" ]]; then
      echo ""
      echo "📋 Recent Logs (last 10 lines):"
      tail -10 "$LOGFILE"
    fi
  else
    echo "❌ Server is NOT running (stale PID file)"
    echo "   PID file exists but process $PID is dead"
  fi
else
  echo "❌ Server is NOT running"
  echo "   No PID file found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Commands:"
echo "   Start:      ./tools/server-start-conda.sh"
echo "   Stop:       ./tools/server-stop-conda.sh"
echo "   Logs:       tail -f $LOGFILE"
echo "   Health:     curl http://localhost:$PORT/health/"
