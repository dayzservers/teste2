import os
import requests
from flask import Flask, request, redirect, session, render_template, Response

WEB_USER = os.getenv("WEB_USER")
WEB_PASS = os.getenv("WEB_PASS")

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET")

TTYD_INTERNAL = "http://127.0.0.1:7681"


@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if (
            request.form.get("username") == WEB_USER
            and request.form.get("password") == WEB_PASS
        ):
            session["auth"] = True
            return redirect("/terminal/")
        return render_template("login.html", error="Credenciais inválidas")

    return render_template("login.html")


@app.route("/terminal/")
@app.route("/terminal/<path:path>")
def terminal(path=""):
    if not session.get("auth"):
        return redirect("/")

    return proxy_ttyd(path)


def proxy_ttyd(path):
    url = f"{TTYD_INTERNAL}/{path}"

    resp = requests.request(
        method=request.method,
        url=url,
        headers={k: v for k, v in request.headers if k.lower() != "host"},
        data=request.get_data(),
        cookies=request.cookies,
        stream=True,
        allow_redirects=False,
    )

    excluded = ["content-encoding", "content-length", "transfer-encoding", "connection"]
    headers = [(k, v) for k, v in resp.headers.items() if k.lower() not in excluded]

    return Response(resp.iter_content(chunk_size=1024),
                    status=resp.status_code,
                    headers=headers)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
