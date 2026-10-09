import os
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/config")
def get_config():
    return jsonify({
        "app_env": os.environ.get("APP_ENV", "not-set"),
        "db_host": os.environ.get("DB_HOST", "not-set"),
        "db_name": os.environ.get("DB_NAME", "not-set"),
        "db_user": os.environ.get("DB_USER", "not-set"),
        "db_password": "<secret>"
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
