#!/bin/bash

FLASK_PORT=5000

find_free_port() {
python3 - <<EOF
import socket
s = socket.socket()
s.bind(('', 0))
print(s.getsockname()[1])
s.close()
EOF
}

cleanup() {
  pkill ttyd 2>/dev/null || true
  pkill -f "python app.py" 2>/dev/null || true
  pkill ngrok 2>/dev/null || true
  sleep 2
}

while true; do
  cleanup

  export TTYD_PORT=$(find_free_port)

  echo "▶️ Subindo ttyd na porta $TTYD_PORT ..."
  ttyd -W -p "$TTYD_PORT" -i 127.0.0.1 /bin/bash &
  TTYD_PID=$!

  sleep 1
  if ! ps -p $TTYD_PID >/dev/null; then
    echo "❌ ttyd falhou ao subir, tentando novamente..."
    sleep 2
    continue
  fi

  echo "▶️ Subindo Flask..."
  python app.py &
  FLASK_PID=$!

  sleep 1

  echo "▶️ Subindo ngrok..."
  ngrok http $FLASK_PORT --log=stdout &
  NGROK_PID=$!

  echo "🧠 PIDs → ttyd=$TTYD_PID flask=$FLASK_PID ngrok=$NGROK_PID"

  echo "🌍 Aguardando URL do ngrok..."
  for i in {1..20}; do
    sleep 1
    URL=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^"]*' | head -n 1)
    if [ -n "$URL" ]; then
      echo ""
      echo "========================================="
      echo "✅ ACESSO WEB DISPONÍVEL:"
      echo "👉 $URL"
      echo "========================================="
      echo ""
      break
    fi
  done

  wait -n $TTYD_PID $FLASK_PID $NGROK_PID
  echo "⚠️ Um processo caiu. Reiniciando tudo..."
done
