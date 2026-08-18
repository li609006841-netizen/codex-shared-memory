# Codex 共享记忆

本目录是 Codex、飞书小C及后续模块共享的显式业务记忆事实源。内部会话缓存和自动生成的 Codex memories 只能作为辅助召回，不得覆盖本目录中的已确认事实。

## 读取顺序

1. 每次新会话先读 `INDEX.md`。
2. 只读取与当前任务匹配的 `modules/*.md`。
3. 需要当前执行状态时读 `state/current-state.json`。
4. 需要具体事项时按 `item_id` 检索 `items/items.jsonl`；不要整文件注入提示词。
5. 需要长期偏好时读 `preferences/preferences.json`。
6. 仅在审计或冲突处理时读 `audit/change-log.jsonl`。

## 写入原则

- 只有用户明确确认、外部系统已验证或工具执行成功的事实才能持久化。
- 推测、模型建议和待确认内容必须标记 `status: proposed` 或写入 `inbox/pending.jsonl`。
- 单次优先级调整不得自动写成长期偏好。
- 不保存密码、Token、Cookie、App Secret、个人敏感信息或完整客户原文。
- 所有修改先追加 `audit/change-log.jsonl`，再更新派生文件。
- JSON 文件使用 `revision` 做乐观并发控制；写入前重读，版本不符则停止并合并。
- 更新 JSON 时先写同目录临时文件，校验成功后原子替换。
- JSONL 只追加，不就地修改；撤销通过追加补偿事件完成。

## 冲突优先级

用户本轮明确指令 > 已验证外部事实 > `state/current-state.json` > 模块规则 > 长期偏好 > 旧会话摘要。

发生冲突时不静默覆盖：保留两个值，在 `inbox/pending.jsonl` 创建待确认项。

## 时间与来源

- 时间统一采用 ISO 8601，时区使用 `+08:00`。
- 每条事实包含 `source_type`、`source_ref`、`updated_at` 和 `updated_by`。
- 飞书消息使用 message_id 或可访问链接；Codex 使用任务/会话标识，不依赖内部缓存路径。

