#!/usr/bin/env python3
import http.server
import json
import subprocess
import re
from urllib.parse import urlparse

PORT = 8765

def run_bullpen(args):
    try:
        result = subprocess.run(
            ["bullpen"] + args,
            capture_output=True, text=True, timeout=15
        )
        return json.loads(result.stdout)
    except Exception as e:
        return {"error": str(e)}

class Handler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def send_json(self, data, status=200):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", len(body))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST")
        self.end_headers()

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/":
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            with open("index.html", "rb") as f:
                self.wfile.write(f.read())
        elif path == "/api/balances":
            self.send_json(run_bullpen(["portfolio", "balances", "--output", "json"]))
        elif path == "/api/subscriptions":
            self.send_json(run_bullpen(["tracker", "copy", "list", "--output", "json"]))
        elif path == "/api/pending":
            self.send_json(run_bullpen(["tracker", "copy", "pending", "--output", "json"]))
        elif path == "/api/executions":
            data = run_bullpen(["tracker", "copy", "executions", "--output", "json"])
            self.send_json(data.get("executions", data) if isinstance(data, dict) else data)
        elif path == "/api/positions":
            self.send_json(run_bullpen(["polymarket", "positions", "--output", "json"]))
        else:
            self.send_json({"error": "not found"}, 404)

    def do_POST(self):
        path = urlparse(self.path).path
        m = re.match(r"^/api/(confirm|reject)/([a-f0-9\-]+)$", path)
        if m:
            action, trade_id = m.group(1), m.group(2)
            result = run_bullpen(["tracker", "copy", action, trade_id])
            self.send_json(result)
        else:
            self.send_json({"error": "not found"}, 404)

if __name__ == "__main__":
    print(f"Bullpen Dashboard running at http://localhost:{PORT}")
    http.server.HTTPServer(("", PORT), Handler).serve_forever()
