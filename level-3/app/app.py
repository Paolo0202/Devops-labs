import os
import json
import boto3
from flask import Flask, request, jsonify, render_template_string
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
metrics = PrometheusMetrics(app)

# Configuración S3
S3_ENDPOINT = os.environ.get("S3_ENDPOINT", "http://localhost:5000")
S3_BUCKET = os.environ.get("S3_BUCKET", "devops-bootcamp-1792292801")
AWS_ACCESS_KEY = os.environ.get("AWS_ACCESS_KEY_ID", "test")
AWS_SECRET_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY", "test")

s3 = boto3.client(
    "s3",
    endpoint_url=S3_ENDPOINT,
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
    region_name="us-east-1",
)

HTML = """
<!DOCTYPE html>
<html>
<body>
  <h1>📦 Flask + S3</h1>
  <p>Bucket: <code>{{ bucket }}</code></p>
  <h2>Subir archivo</h2>
  <form method="POST" enctype="multipart/form-data">
    <input type="file" name="file">
    <button type="submit">Subir</button>
  </form>
  <h2>Archivos en S3</h2>
  <ul>
  {% for obj in objects %}
    <li>
      <a href="{{ url_for('get_file', key=obj) }}">{{ obj }}</a>
      (<a href="{{ url_for('presigned', key=obj) }}">🔗 presigned</a>)
      <a href="{{ url_for('delete_file', key=obj) }}">❌</a>
    </li>
  {% endfor %}
  </ul>
  <h2>Health</h2>
  <p><a href="/health">/health</a></p>
</body>
</html>
"""


@app.route("/")
def index():
    try:
        response = s3.list_objects_v2(Bucket=S3_BUCKET)
        objects = [obj["Key"] for obj in response.get("Contents", [])]
    except Exception:
        objects = []
    return render_template_string(HTML, bucket=S3_BUCKET, objects=objects)


@app.route("/", methods=["POST"])
def upload():
    file = request.files["file"]
    if file:
        s3.upload_fileobj(file, S3_BUCKET, file.filename)
    return index()


@app.route("/file/<path:key>")
def get_file(key):
    url = s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": S3_BUCKET, "Key": key},
        ExpiresIn=300,
    )
    return f'<a href="{url}">Abrir {key}</a> (válido 5 min)'


@app.route("/presigned/<path:key>")
def presigned(key):
    url = s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": S3_BUCKET, "Key": key},
        ExpiresIn=300,
    )
    return jsonify({"url": url, "expires_in": "300 seconds"})


@app.route("/delete/<path:key>")
def delete_file(key):
    s3.delete_object(Bucket=S3_BUCKET, Key=key)
    return index()


@app.route("/health")
def health():
    try:
        s3.head_bucket(Bucket=S3_BUCKET)
        return jsonify({"status": "ok", "bucket": S3_BUCKET, "s3": "connected"})
    except Exception as e:
        return jsonify({"status": "error", "error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True, use_reloader=False)
