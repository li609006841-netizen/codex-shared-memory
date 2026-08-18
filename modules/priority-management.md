# Priority Management

## 目标

总结当前优先事项，并回答“我现在应该做什么”。

## 交互边界

- 飞书入口：`小C｜优先事项`。
- 该模块只处理优先事项、行动项、风险、阻塞、截止时间和即时任务推荐。
- 完整 PRD、市场研究或技术方案应切换模块；当前模块最多创建对应行动项。
- 私人群免 `@` 仅在权限和事件验证后启用；多人群必须 `@小C`。

## 能力

- `current-priorities`：汇总解释 P0/P1/P2。
- `available-time-recommender`：结合日历空档与执行条件推荐即时任务。
- `meeting-action-extractor`：提取会议行动项、承诺、风险和微任务。
- `priority-feedback`：记录完成、调整、纠错和明确的长期偏好。

## 排序

紧急度 25%、业务影响 25%、战略价值 15%、阻塞 15%、风险 15%、可执行性 5%。重大客户承诺、关键路径阻塞、质量/合规或重大商业风险可强制提升为 P0。

不得编造负责人、日期、来源或预计用时。缺失字段写入待确认队列。

## 即时任务推荐

综合下一场会议、可用分钟、优先级、截止时间、预计耗时、最小专注时间、执行条件、依赖和可中断性。5–30 分钟任务标记为 `micro`。

## 飞书机器人基线

- 已确认：`im:message:send_as_bot`、`im:message:readonly`。
- 应核查：`im:message.group_at_msg:readonly`、`im:message.p2p_msg:readonly`、事件 `im.message.receive_v1`。
- 私人群免 `@` 才需要 `im:message.group_msg:readonly` 或相应群全消息权限。
- 可选订阅：`im.chat.member.bot.added_v1`。
- 当前不需要：`im:message.group_at_msg.include_bot:readonly`。

## 验收

1. 今日优先事项排序正确且有来源。
2. 15 分钟空档不推荐 90 分钟深度任务。
3. 模糊承诺不生成确定日期。
4. 单次调整不自动泛化为长期偏好。
5. 越界请求不污染模块上下文。

