#!/usr/bin/env bash
# usage: stop_api.sh <port> — stops the local uvicorn listening on 127.0.0.1:<port> (only ports 18062-18069)
port=$1; [[ $port =~ ^1806[2-9]$ ]] || { echo "refusing port $port" >&2; exit 1; }
pid=$(ss -ltnp "sport = :$port" | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' | head -1)
[ -z "$pid" ] && { echo "nothing on $port"; exit 0; }
grep -q uvicorn /proc/$pid/cmdline || { echo "pid $pid on $port is not uvicorn" >&2; exit 1; }
kill "$pid"; for i in $(seq 50); do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
echo "stopped uvicorn pid $pid on $port"
