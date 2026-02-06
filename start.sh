#!/bin/bash

echo "🔥 Iniciando Web SSH estilo ShellInABox"

while true; do
  echo "▶️ Subindo ttyd..."
  ttyd -p 7681 -i 127.0.0.1 /bin/bash &
  TTYD_PID=$!

  echo "▶️ Subindo Flask..."
  python app.py &
  FLASK_PID=$!

  echo "▶️ Subindo ngrok..."
  ngrok http 5000 --log=stdout &
  NGROK_PID=$!

  echo "🧠 ttyd=$TTYD_PID flask=$FLASK_PID ngrok=$NGROK_PID"

  # espera qualquer processo cair
  wait -n $TTYD_PID $FLASK_PID $NGROK_PID

  echo "⚠️ Processo caiu! Reiniciando tudo em 3s..."
  kill $TTYD_PID $FLASK_PID $NGROK_PID 2>/dev/null || true
  sleep 3
done
