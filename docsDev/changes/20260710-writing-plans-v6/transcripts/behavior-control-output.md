<!-- provenance
agent: /root/writing_plans_v6/control_fast
assigned source: git show a4731d0^:skills/t-writing-plans/SKILL.md
captured: verbatim final payload
-->

# Widget 加载链路实施计划

## Task 1：DB 数据访问

**Files**
- Create: `src/widgets/widget-repository.ts`
- Test: `test/widgets/widget-repository.test.ts`

1. 写失败测试：存在记录时返回 `WidgetRecord`，不存在时返回 `null`。
2. 运行：`npm test -- test/widgets/widget-repository.test.ts`，确认失败。
3. 最小实现：`loadWidget(id: WidgetId): Promise<WidgetRecord | null>`。
4. 再次运行测试，确认通过。
5. 提交：`git commit -am "feat: add widget repository lookup"`。

## Task 2：API 路由

**Files**
- Create: `src/widgets/get-widget.ts`
- Modify: `src/http/routes.ts`
- Test: `test/widgets/get-widget.test.ts`
- Test: `test/http/widget-route.test.ts`

1. 写失败测试：`getWidget(id: WidgetId): Promise<WidgetDto | NotFound>` 正确映射存在与缺失记录。
2. 写失败测试：公开路由严格为 `/v2/widgets/{widgetId}`。
3. 运行相关测试，确认失败。
4. 实现 handler、DTO 映射和路由注册。
5. 运行相关测试，确认通过。
6. 提交：`git commit -am "feat: expose widget v2 endpoint"`。

## Task 3：UI 客户端

**Files**
- Create: `src/client/fetch-widget.ts`
- Create: `src/client/widget-view.ts`
- Test: `test/client/fetch-widget.test.ts`

1. 写失败测试：`fetchWidget(id: WidgetId, signal: AbortSignal): Promise<WidgetView>` 请求 v2 路由。
2. 写失败测试：请求超时严格为 `2,750ms`，并正确组合外部取消信号。
3. 写失败测试：404 与成功响应映射为预期视图。
4. 运行测试，确认失败。
5. 最小实现客户端请求、超时和响应映射，不增加运行时依赖。
6. 运行测试，确认通过。
7. 提交：`git commit -am "feat: add widget client loading"`。

## Task 4：配置与文档

**Files**
- Modify: `package.json`
- Modify: `.nvmrc`
- Modify: `README.md`
- Create: `docs/widget-api.md`
- Test: `test/config/runtime-constraints.test.ts`

1. 写失败测试：Node.js 版本严格为 `22.17.0`，依赖清单无新增运行时依赖。
2. 更新运行时配置，明确支持 macOS 15 和 Windows 11。
3. 文档记录公开路由、三层接口签名及 `2,750ms` 超时。
4. 运行：`npm test`，确认全部通过。
5. 分别在 Node.js `22.17.0` 的 macOS 15、Windows 11 环境验证构建和测试。
6. 提交：`git commit -am "docs: document widget runtime and API contract"`。
