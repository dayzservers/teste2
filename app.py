import os
from flask import Flask, request, redirect, session, render_template, Response
import requests

USER = os.getenv("WEB_USER")
PASS = os.getenv("WEB_PASS")

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET")

TTYD_URL = "http://127.0.0.1:7681"

@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if request.form["username"] == USER and request.form["password"] == PASS:
            session["auth"] = True
            return redirect("/terminal/")
        return render_template("login.html", error="Login inválido")
    return render_template("login.html")

@app.route("/terminal/")
def terminal():
    if not session.get("auth"):
        return redirect("/")
    return proxy("")

@app.route("/terminal/<path:path>")
def terminal_proxy(path):
    if not session.get("auth"):
        return redirect("/")
    return proxy(path)

def proxy(path):
    url = f"{TTYD_URL}/{path}"
    resp = requests.request(
        method=request.method,
        url=url,
        headers={k: v for k, v in request.headers if k != "Host"},
        data=request.get_data(),
        stream=True
    )

    return Response(resp.iter_content(1024), status=resp.status_code, headers=dict(resp.headers))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
