"""Dashboard showing real VM/lab metrics from status.json (written by start.sh after VM verification)."""
import os
import json
from urllib.request import urlopen, Request
from urllib.error import URLError

from flask import Flask, render_template, jsonify, Response

app = Flask(__name__, template_folder=os.path.join(os.path.dirname(__file__), 'templates'))
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
STATUS_FILE = os.path.join(SCRIPT_DIR, 'status.json')

def get_status():
    if not os.path.isfile(STATUS_FILE):
        return {"vm_ip": "", "nginx_ok": False, "ufw_ok": False, "ssh_ok": False,
                "timestamp": "", "vm_name": "", "ssh_user": "", "nginx_url": ""}
    with open(STATUS_FILE) as f:
        return json.load(f)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/status')
def api_status():
    return jsonify(get_status())

@app.route('/nginx')
@app.route('/nginx/')
def nginx_proxy():
    """Proxy to VM's Nginx so it works from Windows (VM IP is only reachable inside WSL2)."""
    status = get_status()
    vm_ip = status.get("vm_ip") or ""
    if not vm_ip:
        return "No VM IP in status. Run start.sh first.", 503
    url = f"http://{vm_ip}/"
    try:
        req = Request(url, headers={"User-Agent": "Dashboard-Proxy"})
        with urlopen(req, timeout=5) as r:
            body = r.read()
            content_type = r.headers.get("Content-Type", "text/html")
            return Response(body, status=200, content_type=content_type)
    except URLError as e:
        return f"Cannot reach VM Nginx at {url}: {e}", 502

if __name__ == '__main__':
    port = int(os.environ.get('PORT', '5000'))
    app.run(host='0.0.0.0', port=port, debug=False, threaded=True)
