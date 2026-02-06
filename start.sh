#!/bin/bash

while true; do
  echo "🚀 Iniciando ttyd + Flask"

  ttyd -p 7681 -i 127.0.0.1 /bin/bash &
  TTYD_PID=$!

  python app.py &
  FLASK_PID=$!

  ngrok http 5000 --log=stdout &
  NGROK_PID=$!

  wait -n $TTYD_PID $FLASK_PID $NGROK_PID

  echo "⚠️ Algo caiu — reiniciando tudo..."
  kill $TTYD_PID $FLASK_PID $NGROK_PID 2>/dev/null || true
  sleep 3
done
