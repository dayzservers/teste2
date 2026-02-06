#!/bin/bash

set -e

PORT=7681
FLASK_PORT=5000

cleanup() {
  echo "🧹 Limpando processos antigos..."
  pkill -f "ttyd -p $PORT" || true
  pkill -f "python app.py" || true
  pkill ngrok || true
  sleep 2
}

while true; do
  cleanup

  echo "▶️ Subindo ttyd..."
  ttyd -p $PORT -i 127.0.0.1 /bin/bash &
  TTYD_PID=$!

  sleep 1

  echo "▶️ Subindo Flask..."
  python app.py &
  FLASK_PID=$!

  sleep 1

  echo "▶️ Subindo ngrok..."
  ngrok http $FLASK_PORT --log=stdout &
  NGROK_PID=$!

  echo "🧠 PIDs → ttyd=$TTYD_PID flask=$FLASK_PID ngrok=$NGROK_PID"

  echo "🌍 Aguardando URL do ngrok..."
  for i in {1..15}; do
    sleep 1
    URL=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^"]*' | head -n 1 || true)
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

  # espera qualquer processo cair
  wait -n $TTYD_PID $FLASK_PID $NGROK_PID

  echo "⚠️ Processo caiu! Reiniciando em 5s..."
  cleanup
  sleep 5
done
