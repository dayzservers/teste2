import os
import pty
import subprocess
from flask import Flask, render_template, request, redirect, session
from flask_socketio import SocketIO, emit
import select

APP_USER = os.getenv("WEB_USER")
APP_PASS = os.getenv("WEB_PASS")

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET")
socketio = SocketIO(app, cors_allowed_origins="*")

@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if request.form["username"] == APP_USER and request.form["password"] == APP_PASS:
            session["auth"] = True
            return redirect("/terminal")
        return render_template("login.html", error="Login inválido")
    return render_template("login.html")

@app.route("/terminal")
def terminal():
    if not session.get("auth"):
        return redirect("/")
    return render_template("terminal.html")

@socketio.on("start")
def start_terminal():
    if not session.get("auth"):
        return

    pid, fd = pty.fork()
    if pid == 0:
        os.execvp("/bin/bash", ["/bin/bash"])
    else:
        while True:
            r, _, _ = select.select([fd], [], [], 0.1)
            if fd in r:
                data = os.read(fd, 1024).decode(errors="ignore")
                emit("output", data)

@socketio.on("input")
def terminal_input(data):
    os.write(data["fd"], data["data"].encode())

if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=5000)
