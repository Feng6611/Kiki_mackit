# Kiki_mackit 0.7.0 Refactor Plan — High-Level Features

## 关系与定位

本文件是工作区 [`build/BUILD_SYSTEM.md`](../../BUILD_SYSTEM.md) §2.2 "Base Kit" 在 Kit 内的落地计划，承接 [`Refactor-0.6.0.md`](Refactor-0.6.0.md)。

0.6.0 已经把 Kit 升级到"native first, atoms + presets"。0.7.0 在此基础上叠加 **高层 Feature**：让 App 不再需要自己组装 SettingsCoordinator / OnboardingFlow / Paywall presets / Standard About。

**范围严格限定在 `Kiki_mackit` 仓库内。**

- 不动 `Kiki_menubar_starter`。
- 不动任何 `mac-*` App。
- 不动 `RevenueCatCommerceKit`。
- 不重构 `KikiCommerce` target（其中 `KikiProAccessStatus`、`KikiTrialPolicy`、`KikiProAccessConfiguration` 等仍按 0.6 形态保留），它的合并/拆分是工作区 §6 阶段 2b 的事。

## 设计标准

1. **加法不破旧**：0.7.0 只新增公共 API。0.6.0 已有的 `KikiOnboardingScaffold`、`KikiPaywallSheet`、`KikiSettingsShell`、`KikiAboutPane`、`KikiAppIdentityView` 保留为 atom 层。Hidden Dot 已经基于 0.6.0 跑通，不能要求它再迁移一次。
2. **Commerce 解耦**：新 Feature 不引入对 `KikiCommerce` 的依赖。Settings 显示的"访问状态"卡片、Onboarding 的"paywallHandoff"步骤、Paywall 的展示都通过 Commerce-agnostic 的"presentation"结构通信。App（或 2b 后的 `KikiCommerceKit`）负责把 Commerce 状态翻译为 presentation。
3. **App Composition 仍由 App 写**：Coordinator 接受 closure / Binding，不接管路由决策。`KikiSettingsCoordinator` 不知道有 Paywall；`KikiOnboardingCoordinator` 不知道 Trial 怎么扣。
4. **测试可达**：每个新公共类型至少有一个 smoke test。

## Module-By-Module Plan

### A. KikiSettings

新增文件（target 内）：

- `KikiAppMetadata.swift`
  - `public struct KikiAppMetadata: Sendable`：`appName / bundleIdentifier / shortVersion / buildNumber / displayVersion / iconName?`，提供 `static func bundle(_:)` 从 `Bundle.main` 直接读取。
- `KikiAccessStatusPresentation.swift`
  - `public struct KikiAccessStatusPresentation: Equatable, Sendable`：`title / subtitle / tone (active/trial/expired/none) / actionTitle? / action?`。
  - `public enum KikiAccessStatusTone`。
  - 不携带 Commerce 类型；调用方自行构造。
- `KikiAccessStatusCard.swift`
  - SwiftUI `View`，按 tone 渲染颜色徽章/按钮，可在 Settings/About 复用。
- `KikiStandardAboutPane.swift`
  - 复用 0.6 的 `KikiAboutPane`，预置布局：`KikiAppIdentityView` + `KikiAccessStatusCard?` + 链接列表（terms/privacy/support/feedback）。
  - 链接通过 `KikiStandardAboutLinks` 结构传入；每项可为空。
- `KikiSettingsCoordinator.swift`
  - `@MainActor public final class KikiSettingsCoordinator<Tab: Hashable>`：组合 `KikiSettingsNavigationModel<Tab>` + `KikiSettingsApplications` (opener) + `KikiSettingsWindowController` (autosave/visibility)。
  - 暴露 `open(tab:)`, `close()`, `isVisible`, `select(_:)`。
  - 渲染由调用方传入 `@ViewBuilder content: (Tab) -> some View`，Coordinator 只组装一次 `KikiSettingsShell`。

API 边界守则：

- Coordinator **不依赖** `KikiCommerce`、`KikiPaywall`、`KikiOnboarding`。
- StandardAbout 通过 closure 暴露 `onUpgrade` / `onOpenLink(URL)` 给 App，App 决定路由。

### B. KikiOnboarding

新增文件（target 内）：

- `KikiOnboardingStep.swift`
  - `public enum KikiOnboardingStep`：
    - `case welcome(KikiOnboardingWelcomeContent)`
    - `case features(KikiOnboardingFeatureContent)`
    - `case permission(KikiOnboardingPermissionContent)`
    - `case success(KikiOnboardingSuccessContent)`
    - `case paywallHandoff`
    - `case custom(id: String, view: @MainActor () -> AnyView)`
  - 每个 case 自带必要的内容结构体；都是 `Sendable`/`Equatable` 在结构体内只放数据。
- `KikiOnboardingConfiguration.swift`
  - `public struct KikiOnboardingConfiguration`：`appName / tint / steps / canSkip / completionStoreKey / windowAutosaveName`。
- `KikiOnboardingCompletionStore.swift`
  - `public protocol KikiOnboardingCompletionStore: AnyObject`：`isCompleted(for:) -> Bool`, `markCompleted(for:)`, `reset(for:)`。
  - `public final class KikiOnboardingUserDefaultsCompletionStore`：默认实现，UserDefaults 后端。
- `KikiOnboardingCoordinator.swift`
  - `@MainActor public final class KikiOnboardingCoordinator`：
    - `init(configuration:completionStore:onPaywallHandoff:onFinished:)`。
    - 内部维护当前 step index，提供 `start()`, `advance()`, `back()`, `skip()`, `finish()`。
    - 调用 `KikiOnboardingWindowController` 承载内容；按 step kind 渲染不同 view，custom 使用调用方的 AnyView。
    - 命中 `.paywallHandoff` 时调用 `onPaywallHandoff()`，由 App 决定是显示 Paywall 还是直接 finish。
    - `finish()` 时调用 completionStore 写入完成状态并 close。
- Window 复用 0.6 的 `KikiOnboardingWindowController`（无需重写）。

API 边界守则：

- Onboarding 完成状态由 `KikiOnboardingCompletionStore` 持久化，**不再依赖 Commerce storage**。
- Coordinator 不知道 Trial 是否启动、是否付费。`paywallHandoff` 只是回调点。

### C. KikiPaywall

新增文件（target 内）：

- `KikiPaywallPresentation.swift`
  - `public struct KikiPaywallPresentation: Sendable`：
    - `accessState: KikiAccessPresentationState`（本地枚举，不依赖 Commerce：`.notStarted / .trial(daysRemaining:) / .expired / .entitled(planTitle:)`）
    - `plans: [KikiPaywallPlanPresentation]`
    - `features: [String]`
    - `headerTitle / subtitle / footnote?`
    - `actions: KikiPaywallActions`（purchase / restore / startTrial / dismiss closures）
- `KikiCompactPaywall.swift`
  - SwiftUI `View`，紧凑布局，适合 Settings sheet。仅消费 `KikiPaywallPresentation`，内部复用 0.6 的 `KikiPaywallSheet`/`KikiPaywallShell` atoms。
- `KikiOnboardingPaywall.swift`
  - SwiftUI `View`，首启布局，更大尺寸、可配 hero。仅消费 `KikiPaywallPresentation`。

API 边界守则：

- 仍然 **不 import RevenueCat**。
- 0.6 的 `KikiPaywallSheet` 不动，作为 atom 保留。
- Compact / Onboarding preset 共享一份内部子视图，避免视觉漂移。

## Package.swift / 依赖

- `KikiSettings` 不增加依赖（保持 `KikiCore, KikiDesign`）。新文件全部归在 `KikiSettings` target。
- `KikiOnboarding` 已依赖 `KikiAuthorization, KikiWindow, KikiDesign`，足够；新文件归入该 target。
- `KikiPaywall` 已依赖 `KikiDesign, KikiWindow`，足够。
- `KikiCommerce` target 不动；后续 2b 才会拆。

## 测试

新增 / 扩展：

- `Tests/KikiSettingsTests`
  - `KikiAppMetadataTests`：从 Mock bundle dict 构造，校验字段。
  - `KikiAccessStatusPresentationTests`：tone 与 action 行为。
  - `KikiSettingsCoordinatorTests`：构造 + select(_:) 行为（不实际打开窗口）。
- `Tests/KikiOnboardingTests`
  - `KikiOnboardingCompletionStoreTests`：UserDefaults 读写。
  - `KikiOnboardingCoordinatorTests`：advance / back / skip / paywallHandoff 调用次数。
- `Tests/KikiPaywallTests`
  - `KikiPaywallPresentationTests`：state 构造、action closure 调用计数。

## 执行顺序

1. KikiPaywall: `KikiPaywallPresentation` + `KikiCompactPaywall` + `KikiOnboardingPaywall`（最独立）。
2. KikiSettings: `KikiAppMetadata` → `KikiAccessStatusPresentation` / `KikiAccessStatusCard` → `KikiStandardAboutPane` → `KikiSettingsCoordinator`。
3. KikiOnboarding: `KikiOnboardingStep` 数据结构 → `KikiOnboardingCompletionStore` → `KikiOnboardingConfiguration` → `KikiOnboardingCoordinator`。
4. 测试与文档（`Docs/KikiSettings.md`、`Docs/KikiOnboarding.md`、`Docs/KikiPaywall.md` 增补"高层 Feature"小节；`CHANGELOG.md` 加 0.7.0 Unreleased）。
5. `swift test` 在 `build/Kiki_mackit` 全部通过。

## 验收

- `swift test` 全绿。
- 新增公共类型在 `Docs/` 中有一段说明。
- `CHANGELOG.md` 0.7.0 条目列出新增 API。
- 0.6 公共 API 一个都没改签名。
- `KikiSettings` / `KikiOnboarding` / `KikiPaywall` target 都不引入新的 dependency 行。
- 没有任何 commit 修改 `KikiCommerce` target 文件。

## 与 2b 的衔接

2b 合并 `KikiCommerceKit` 时：

- 新包提供 `KikiAccessStatusPresentation.from(state:)` / `KikiPaywallPresentation.from(state:plans:)` 这类 adapter，**App 写一行就能把 AccessState 灌进 Kit 的 Feature**。
- 现 `KikiCommerce` target 的 `KikiProPaywallSheet` 后续会改成 thin wrapper，内部调用 `KikiCompactPaywall(presentation:)`。这一步留到 2b，不在 0.7.0。
