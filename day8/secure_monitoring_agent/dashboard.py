"""Web dashboard for Secure Monitoring Agent Manager: metrics, agent status, and application workflow."""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from flask import Flask, render_template, jsonify
from system_health import get_system_health_dict

APP_DIR = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(APP_DIR, 'logs', 'agent.log')

app = Flask(__name__, template_folder=os.path.join(APP_DIR, 'templates'))

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/metrics')
def api_metrics():
    """Return current system metrics as JSON for live updates."""
    try:
        data = get_system_health_dict()
        return jsonify(data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/agent_status')
def agent_status():
    """Return last few agent log lines (heartbeats) so the dashboard can show live operation."""
    try:
        if not os.path.isfile(LOG_FILE):
            return jsonify({"running": False, "lines": [], "message": "Agent log not found. Start the app with start.sh."})
        with open(LOG_FILE, 'r') as f:
            lines = f.readlines()
        last_lines = [l.strip() for l in lines[-10:] if l.strip()]
        return jsonify({"running": True, "lines": last_lines})
    except Exception as e:
        return jsonify({"running": False, "lines": [], "message": str(e)})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', '5000'))
    app.run(host='0.0.0.0', port=port, debug=False, threaded=True)
