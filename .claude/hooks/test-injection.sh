#!/bin/bash
# test-injection.sh - State Injection のテストスクリプト

echo "=== Test 1: 通常プロンプト ==="
echo '{"prompt": "現状を教えて"}' | bash .claude/hooks/prompt-guard.sh 2>&1
echo ""

echo "=== Test 2: 報酬詐欺パターン ==="
echo '{"prompt": "完了しました"}' | bash .claude/hooks/prompt-guard.sh 2>&1
echo ""

echo "=== Test 3: スコープ拡張パターン ==="
echo '{"prompt": "ついでにこれも"}' | bash .claude/hooks/prompt-guard.sh 2>&1
echo ""

echo "=== Test 4: 作業要求（playbook あり）==="
echo '{"prompt": "実装してください"}' | bash .claude/hooks/prompt-guard.sh 2>&1
echo ""

echo "=== Test 5: JSON パース確認 ==="
OUTPUT=$(echo '{"prompt": "test"}' | bash .claude/hooks/prompt-guard.sh 2>&1)
echo "$OUTPUT" | jq -r '.systemMessage' 2>/dev/null && echo "[JSON VALID]" || echo "[JSON INVALID]"
echo ""

echo "=== 全テスト完了 ==="
