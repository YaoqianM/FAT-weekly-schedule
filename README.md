# Feishu 周日卸货轮值通知机器人

每周日上午 9:00（太平洋时间）自动向 Feishu 群发送下周卸货 DSP 轮值通知。

轮换顺序（无限循环）：**YMB → PEL → DAE → SDG**

## 目录结构

```
feishu-dsp-bot/
├── .github/
│   └── workflows/
│       └── feishu-sunday.yml    # GitHub Actions 定时任务
├── config/
│   └── rotation.json            # 轮换配置（改动只需动这个文件）
├── scripts/
│   └── send_notification.sh     # 计算轮值 + 发送消息
└── README.md
```

## 首次部署

1. 在 GitHub 新建仓库（建议 **Private**，防止他人看到站点信息），把本目录所有文件推上去
2. 仓库 **Settings → Secrets and variables → Actions → New repository secret**
   - Name: `FEISHU_WEBHOOK`
   - Value: 你的完整 webhook 地址（`https://open.feishu.cn/open-apis/bot/v2/hook/xxxx`）
   - ⚠️ webhook 地址包含密钥，**不要**写进任何代码文件
3. 校准轮换起点：编辑 `config/rotation.json` 里的 `anchor_sunday`，填**轮到 YMB 的那个周日**（当前默认 `2026-08-02`）
4. 测试：仓库 **Actions → Feishu 周日卸货轮值通知 → Run workflow**，确认群里收到消息

## 日常维护

| 需求 | 操作 |
|------|------|
| 换负责人 | 改 `rotation.json` 里对应的 `owner` |
| 增减 DSP | 在 `rotation` 数组增删条目（脚本自动按数组长度循环） |
| 轮换乱了要重新校准 | 改 `anchor_sunday` 为第一个 DSP 轮值的任意周日 |
| 让 @负责人 真正弹提醒 | 在 `rotation.json` 填入每人的 `open_id`（`ou_` 开头） |
| 改发送时间 | 改 workflow 里的 cron（注意是 UTC 时间） |

## 获取 open_id（可选）

Feishu 自定义机器人的纯文字 `@名字` 不会真正提醒到人，需要 open_id：
- 群管理员可在 Feishu 管理后台或通过开放平台 API（`contact/v3/users`）查询成员 open_id
- 填入 `rotation.json` 后脚本会自动改用 `<at user_id="ou_xxx">` 真 @ 格式
- `@所有人` 不受影响，始终生效

## 已知限制

- GitHub 定时任务高峰期可能延迟 5–15 分钟以上；对时间敏感可把 cron 提前
- 仓库 60 天无活动会暂停 schedule，需手动重新启用（偶尔 push 一次即可避免）
- 美国夏令时/冬令时切换时，cron 需手动在 16:00/17:00 UTC 之间调整
