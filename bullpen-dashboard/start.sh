#!/bin/bash
cd "$(dirname "$0")"
echo "Starting Bullpen Dashboard..."
echo "Open http://localhost:8765 in your browser"
python3 server.py
