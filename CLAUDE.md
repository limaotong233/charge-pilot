# CLAUDE.md

本项目请遵循如下规范，并在项目中称呼我为“wind“

- 每次修改/生成鸿蒙项目代码后必须在鸿蒙项目目录下编译(为了避免影响上下文，可以开一个subagent编译，将结果返回)

```
hvigorw assembleHap -p module=entry
```

- ArkTS语法规范@/rules/arkts-rule.md
- 创建ArkTS项目需要让用户自行创建，不要自动生成项目结构

## 项目概述

鸿蒙原生电动汽车充电服务平台（闪充），基于 ArkTS + ArkUI 声明式 UI 构建，Bundle: `com.zjhw.charging`，支持 Phone/Tablet/2in1 多端响应式布局。

## 项目结构

本项目包含两个子项目：

| 目录 | 说明 |
|------|------|
| `charging/` | HarmonyOS NEXT 客户端（ArkTS） |
| `flash-charging-server/` | 自建后端服务（Node.js + Express + PostgreSQL） |

## 开发环境与构建

### HarmonyOS 客户端（charging/）

- **IDE**: DevEco Studio，**构建系统**: Hvigor，**包管理**: ohpm
- **项目根目录**: `charging/`（Hvigor 项目入口，所有构建命令在此目录下执行）
- **主模块**: `charging/entry/`（HAP 模块）
- **目标 SDK**: HarmonyOS NEXT API 22，targetSdkVersion 6.0.2(22)

```bash
# 构建（在 charging/ 目录下）
hvigor assembleHap            # 构建 HAP 包

# 代码检查
# 配置文件: charging/code-linter.json5（检查所有 *.ets 文件）
# 规则集: @performance/recommended, @typescript-eslint/recommended

# 运行测试
# 测试框架: @ohos/hypium，mock: @ohos/hamock
# 本地单元测试: entry/src/test/
# 设备测试: entry/src/ohosTest/
```

### 后端服务（flash-charging-server/）

- **运行时**: Node.js + TypeScript，**框架**: Express 4
- **数据库**: PostgreSQL + Drizzle ORM，**认证**: JWT (JSON Web Token)
- **包管理**: npm

```bash
cd flash-charging-server
npm install                    # 安装依赖
npm run db:push                # 初始化数据库表
npm run db:seed                # 填充测试数据（admin/test，密码 123456）
npm run dev                    # 开发模式（自动重启，默认端口 3000）
npm run build                  # 编译 TypeScript
npm start                      # 生产模式
```

## 架构分层

```
Pages (pages/) → Components (components/) → API Layer (api/) → HTTP Utility (utils/Http.ets) → 后端服务
```

### 关键目录（均在 `charging/entry/src/main/ets/` 下）

| 目录 | 职责 |
|---|---|
| `entryability/` | EntryAbility 主入口，处理窗口生命周期、断点检测、KV 存储初始化、页面路由 |
| `entryformability/` | 桌面服务卡片（Widget）扩展 |
| `pages/` | 19 个页面，路由配置在 `resources/base/profile/main_pages.json`（designWidth 360） |
| `components/` | 14 个可复用组件（底部导航、搜索栏、站点卡片、底部弹窗等） |
| `api/` | 6 个 API 模块（Home/Login/Order/AdvanceCharging/CardCoupons/Collection），均为 `utils/Http.ets` 的薄封装 |
| `service/` | 6 个服务（Http 请求封装、分布式 KV 数据库、本地偏好存储、桌面卡片、Toast、懒加载数据源） |
| `model/` | 接口定义：`interface/api/` 存放 API DTO，`interface/` 存放 UI 层接口 |
| `utils/` | 工具类（HTTP 客户端、距离计算、日期格式化、懒加载列表组件） |
| `widget/` | 桌面服务卡片 WidgetCard 实现 |

### 核心服务

- **HTTP 客户端** (`utils/Http.ets`): 基于 `@kit.RemoteCommunicationKit`（rcp），JWT Token 认证（`Authorization: Bearer`），会话过期码（EDU99999/EDU30021）自动跳转登录
- **数据持久化**: `LocalPreferences`（本地 KV 存储，单例）+ `DataBaseService`（分布式 KV 存储，跨设备同步，单例）
- **路由导航**: `router.pushUrl()` / `router.replaceUrl()` / `router.clear()`

## 编码规范

- **文件命名**: camelCase（API/Service 文件如 `HomeApi.ets`、`DataBaseService.ets`），PascalCase（组件/Ability 如 `EntryAbility.ets`、`WidgetCard.ets`）
- **组件**: PascalCase struct + `@Component` / `@Entry @Component` 装饰器
- **状态管理**: ArkTS 装饰器（`@State` 组件内、`@Link` 父子双向、`@Prop` 父子单向、`@StorageProp` AppStorage 单向、`@Watch` 状态监听）
- **响应式布局**: `@StorageProp('currentBreakpoint')` 区分 `sm`（手机）/ `md`（平板/2in1），手机底部 Tab 导航 vs 平板左侧导航栏
- **尺寸单位**: 统一使用 `lpx`（逻辑像素）
- **常量**: UPPER_SNAKE_CASE
- **API 调用**: 使用泛型参数，如 `getStationList<StationListReturning>(extraData)`
- **服务模式**: 单例（静态 `__instance` / `__preferences`）
- **缩进**: 2 空格，注释使用中文
- **代码检查**: `plugin:@performance/recommended` + `plugin:@typescript-eslint/recommended`

## 关键 HarmonyOS Kit 依赖

- **MapKit**: 地图展示、站点标记、路线规划、驾驶距离矩阵计算
- **ScanKit**: 扫码识别充电桩二维码
- **CoreSpeechKit (TTS)**: 充电进度语音播报（支持 15s/30s/60s 间隔），配合 BackgroundTasksKit 实现息屏后台播报
- **NotificationKit**: 充电完成系统通知
- **FormKit**: 桌面服务卡片（预约状态展示）
- **ArkData**: 分布式 KV 存储（跨设备同步）+ 本地偏好存储
- **LocationKit**: 定位与距离计算

## 注意事项
- ArkTS语法规范@/rules/arkts-rule.md
- 后端 API 基础地址在 `charging/entry/src/main/ets/utils/Http.ets` 中配置，默认 `http://localhost:3000`
- 认证使用 JWT Token（`Authorization: Bearer` 头），不再使用 Cookie + CSRF Token
- 后端响应格式保持 `ResultVO<T>` 兼容：`{ status, msg, data, code }`，成功码 `EDU00000`，会话过期码 `EDU99999`/`EDU30021`
- 页面路由注册在 `main_pages.json`，新增页面需在此文件注册
- 桌面服务卡片配置在 `form_config.json`，尺寸 2x4
- Release 构建启用代码混淆（属性名、顶层变量、文件名、导出均混淆），见 `obfuscation-rules.txt`
- 项目使用 Claude Code Skills（`arkts-syntax-assistant`、`harmony-next`）辅助 ArkTS 开发
