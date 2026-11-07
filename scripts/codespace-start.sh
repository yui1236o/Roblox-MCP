#!/bin/bash
# Codespace 启动脚本: 构建并启动 MCP 桥 + 自动 pinggy 公网隧道
cd "$(dirname "$0")/.."

npm install
npm run build

pkill -f "node dist/index.js" 2>/dev/null || true
nohup npm run start > /tmp/mcp.log 2>&1 &

# 隧道保活循环 (pinggy 免费隧道 60 分钟过期后自动重连)
nohup bash -c 'while true; do
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o ServerAliveInterval=30 -N -p 443 -R0:localhost:16384 a.pinggy.io >> /tmp/tunnel.log 2>&1
  sleep 5
done' > /dev/null 2>&1 &

# 持续监视隧道地址, 自动生成手机端连接脚本
nohup bash -c 'LAST=""
while true; do
  URL=$(grep -oE "https://[A-Za-z0-9.-]+\.free\.pinggy\.net" /tmp/tunnel.log 2>/dev/null | tail -1)
  if [ -n "$URL" ] && [ "$URL" != "$LAST" ]; then
    LAST="$URL"
    {
      echo "getgenv().BridgeURL = \"$URL\""
      echo "loadstring(game:HttpGet(\"$URL/script.luau\"))()"
    } > /tmp/loader.txt
    echo "[loader] 新地址: $URL"
  fi
  sleep 10
done' > /tmp/loader.log 2>&1 &

echo "启动完成。等 1 分钟后运行: cat /tmp/loader.txt 获取手机连接代码"
