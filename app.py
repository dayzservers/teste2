import os
import pty
import subprocess
from flask import Flask, render_template, request, redirect, session, jsonify

APP_USER = os.getenv("WEB_USER")
APP_PASS = os.getenv("WEB_PASS")

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET")

master_fd, slave_fd = pty.openpty()
shell = subprocess.Popen(
    ["/bin/bash"],
    stdin=slave_fd,
    stdout=slave_fd,
    stderr=slave_fd,
    text=True
)

@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if (
            request.form["username"] == APP_USER
            and request.form["password"] == APP_PASS
        ):
            session["auth"] = True
            return redirect("/terminal")
        return render_template("login.html", error="Login inválido")

    return render_template("login.html")

@app.route("/terminal")
def terminal():
    if not session.get("auth"):
        return redirect("/")
    return render_template("terminal.html")

@app.route("/cmd", methods=["POST"])
def cmd():
    if not session.get("auth"):
        return jsonify({"out": "Não autorizado"})

    command = request.json.get("cmd", "")
    os.write(master_fd, (command + "\n").encode())

    return jsonify({"out": ""})

@app.route("/read")
def read():
    try:
        data = os.read(master_fd, 4096).decode(errors="ignore")
        return jsonify({"out": data})
    except:
        return jsonify({"out": ""})

app.run(host="0.0.0.0", port=5000)
