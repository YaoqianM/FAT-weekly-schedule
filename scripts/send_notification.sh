#!/usr/bin/env bash
# 周日卸货轮值通知脚本
# 读取 config/rotation.json，计算本周轮值 DSP，向 Feishu webhook 发送通知
# 依赖：jq、curl（GitHub Actions ubuntu-latest 自带）
set -euo pipefail

CONFIG="config/rotation.json"

if [ -z "${FEISHU_WEBHOOK:-}" ]; then
  echo "❌ 缺少环境变量 FEISHU_WEBHOOK" >&2
  exit 1
fi

# ===== 读取配置 =====
ANCHOR=$(jq -r '.anchor_sunday' "$CONFIG")
COUNT=$(jq '.rotation | length' "$CONFIG")

# ===== 计算本周轮值序号 =====
TODAY=$(date -u +%Y-%m-%d)
DIFF_DAYS=$(( ( $(date -ud "$TODAY" +%s) - $(date -ud "$ANCHOR" +%s) ) / 86400 ))
IDX=$(( ((DIFF_DAYS / 7) % COUNT + COUNT) % COUNT ))

DSP=$(jq -r ".rotation[$IDX].dsp" "$CONFIG")
OWNER=$(jq -r ".rotation[$IDX].owner" "$CONFIG")
OPEN_ID=$(jq -r ".rotation[$IDX].open_id" "$CONFIG")

echo "📅 今天: $TODAY | 本周轮值: $DSP / $OWNER (index=$IDX)"

# ===== 负责人 @ 格式 =====
# 有 open_id 时用真 @，否则用纯文字
if [ -n "$OPEN_ID" ] && [ "$OPEN_ID" != "null" ]; then
  OWNER_TAG="<at user_id=\"$OPEN_ID\">$OWNER</at>"
else
  OWNER_TAG="@$OWNER"
fi

# ===== 拼装消息（用 jq 自动转义，避免特殊字符问题）=====
TEXT="📢 <at user_id=\"all\">所有人</at>
各位 DSP 团队：

提醒一下，下周负责卸货的 DSP 为：

🚛 ${DSP}
负责人：${OWNER_TAG}

请安排 4 名卸货人员（Loading Team）于 4:30 AM 准时到站参与卸货。

请提前做好人员安排，确保卸货工作顺利进行。

感谢大家配合！🌼"

PAYLOAD=$(jq -n --arg text "$TEXT" '{msg_type: "text", content: {text: $text}}')

# ===== 发送 =====
RESP=$(curl -sS -X POST "$FEISHU_WEBHOOK" \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD")

echo "Feishu 返回: $RESP"

# code=0 表示成功
if echo "$RESP" | jq -e '.code == 0' > /dev/null 2>&1; then
  echo "✅ 发送成功"
else
  echo "❌ 发送失败" >&2
  exit 1
fi
