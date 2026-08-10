#!/usr/bin/env bash
# SEADS — Local development launcher
# Starts the backend with nodemon.
# For local machine testing (Linux / Web / Desktop): flutter run
# For Android emulator: flutter run --dart-define=BACKEND_URL=http://10.0.2.2:3000

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/../seads-backend"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SEADS Backend — Local Dev"
echo "  http://localhost:3000"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "$BACKEND_DIR/.env" ]; then
  echo ""
  echo "⚠  No .env found in seads-backend/"
  echo "   Copy the template and fill in your credentials:"
  echo "   cp seads-backend/.env.example seads-backend/.env"
  echo ""
  exit 1
fi

cd "$BACKEND_DIR"

if [ ! -d "node_modules" ]; then
  echo "→ Installing dependencies..."
  npm install
fi

echo "→ Starting backend (nodemon)..."
npm run dev
