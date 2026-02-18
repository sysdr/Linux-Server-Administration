"""Web dashboard showing live system metrics (no zero values when running)."""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from flask import Flask, render_template, jsonify
from system_health import get_system_health_dict

app = Flask(__name__, template_folder=os.path.join(os.path.dirname(__file__), 'templates'))

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/metrics')
def api_metrics():
    """Return current metrics as JSON for live updates."""
    try:
        data = get_system_health_dict()
        return jsonify(data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', '5000'))
    app.run(host='0.0.0.0', port=port, debug=False, threaded=True)
