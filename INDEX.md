# 共享记忆索引

| 模块 | 入口 | 状态 | 说明 |
|---|---|---|---|
| 全局协议 | `README.md` | active | 读写、冲突、隐私和并发规则 |
| 优先事项 | `modules/priority-management.md` | active | 小C｜优先事项模块边界与排序规则 |
| Agent平台 | `modules/agent-platform.md` | active | 小C统一入口、多Agent、记忆、成本、自学习与跨设备方案 |
| 当前状态 | `state/current-state.json` | active | 当前模块状态及同步水位 |
| 事项库 | `items/items.jsonl` | active | 每行一个事项 |
| 长期偏好 | `preferences/preferences.json` | active | 仅保存明确确认的长期偏好 |
| 待确认 | `inbox/pending.jsonl` | active | 推测、冲突和待补字段 |
| 变更日志 | `audit/change-log.jsonl` | active | 追加式审计记录 |
| 会话索引 | `sessions/session-index.jsonl` | active | 会话与模块的弱关联，不保存内部缓存 |

默认模块为 `priority-management`，仅当对话明确属于优先事项时加载。Agent、Skill、插件、记忆、Token、跨设备或平台建设请求加载 `agent-platform`。
