#!/bin/bash

BULLPEN=/opt/homebrew/bin/bullpen
LOG=~/Documents/bullpen-dashboard/redeem-wrap.log
export BULLPEN_POLYGON_RPC_URL="https://polygon-bor-rpc.publicnode.com"

echo "$(date): Running redeem and wrap" >> "$LOG"

# Redeem all winning positions
$BULLPEN polymarket redeem --yes >> "$LOG" 2>&1

# Get USDC.e balance
USDC=$($BULLPEN funds balances --output json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
chains = data.get('chains', [])
for chain in chains:
    if chain.get('label') == 'Polymarket':
        for item in chain.get('items', []):
            if item.get('symbol') == 'USDC.e':
                val = float(item.get('balance', 0))
                if val > 0.01:
                    print(f'{val:.6f}')
" 2>/dev/null)

# Wrap if balance exists
if [ -n "$USDC" ]; then
    echo "$(date): Wrapping $USDC USDC.e to pUSD" >> "$LOG"
    $BULLPEN polymarket wrap "$USDC" --yes >> "$LOG" 2>&1
else
    echo "$(date): No USDC.e to wrap" >> "$LOG"
fi
