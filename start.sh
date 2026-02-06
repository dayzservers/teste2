#!/bin/bash

find_free_port() {
python3 - <<EOF
import socket
s=socket.socket()
s.bind(('',0))
print(s.getsockname()[1])
s.close()
EOF
}

cleanup() {
  pkill ttyd 2>/dev/null || true
  pkill ngrok 2>/dev/null || true
  sleep 2
}

while true; do
  cleanup

  export TTYD_PORT=$(find_free_port)

  echo "▶️ Subindo ttyd na porta $TTYD_PORT"

  ttyd \
    -W \
    -p "$TTYD_PORT" \
    -i 0.0.0.0 \
    -c "$WEB_USER:$WEB_PASS" \
    /bin/bash &

  TTYD_PID=$!

  sleep 2
  if ! ps -p $TTYD_PID >/dev/null; then
    echo "❌ ttyd não subiu, retry..."
    sleep 2
    continue
  fi

  echo "▶️ Subindo ngrok"
  ngrok http "$TTYD_PORT" --log=stdout &
  NGROK_PID=$!

  echo "🌍 Aguardando URL..."
  for i in {1..20}; do
    sleep 1
    URL=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^"]*' | head -n1)
    if [ -n "$URL" ]; then
      echo ""
      echo "================================="
      echo "✅ ACESSO WEB SSH:"
      echo "$URL"
      echo "================================="
      echo ""
      break
    fi
  done

  wait -n $TTYD_PID $NGROK_PID
  echo "⚠️ Processo caiu — reiniciando tudo..."
done
