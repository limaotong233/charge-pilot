# 寻电 ChargePilot — 鸿蒙智能充电服务平台

鸿蒙原生电动汽车充电服务平台，包含 HarmonyOS NEXT 客户端和自建后端服务。

![image-20260606195235100](C:\Users\24634\AppData\Roaming\Typora\typora-user-images\image-20260606195235100.png)![image-20260606195237932](C:\Users\24634\AppData\Roaming\Typora\typora-user-images\image-20260606195237932.png)![image-20260606195407479](C:\Users\24634\AppData\Roaming\Typora\typora-user-images\image-20260606195407479.png)![image-20260606195439361](C:\Users\24634\AppData\Roaming\Typora\typora-user-images\image-20260606195439361.png)![image-20260606195523049](C:\Users\24634\AppData\Roaming\Typora\typora-user-images\image-20260606195523049.png![image-20260606195534755](C:\Users\24634\AppData\Roaming\Typora\typora-user-images\image-20260606195534755.png







## 项目结构

```
ChargePilot/
├── charging/                   # HarmonyOS NEXT 客户端（ArkTS）
│   ├── entry/                  # 主 HAP 模块
│   │   └── src/main/ets/       # 源码（pages / api / components / service / celia）
│   ├── AppScope/               # 应用级配置
│   ├── build-profile.json5     # 构建配置
│   └── README.md               # 客户端详细介绍
│
└── flash-charging-server/      # 自建后端服务（Node.js + Express + PostgreSQL）
    ├── src/                    # TypeScript 源码
    │   ├── controllers/        # 请求处理
    │   ├── services/           # 业务逻辑
    │   ├── models/             # 数据库 Schema（Drizzle ORM）
    │   ├── routes/             # 路由定义
    │   ├── middleware/         # 中间件（JWT认证、错误处理、限流）
    │   └── config/             # 配置（数据库、环境变量）
    ├── public/                 # Web 管理面板
    ├── uploads/                # 文件上传目录
    ├── .env                    # 环境变量
    └── README.md               # 后端 API 文档
```

## 环境要求

| 工具 | 版本要求 | 说明 |
|------|----------|------|
| Node.js | >= 18.x | 后端运行时 |
| PostgreSQL | >= 14.x | 数据库 |
| DevEco Studio | >= 5.0 | HarmonyOS IDE（含 Hvigor 构建工具） |
| HarmonyOS SDK | API 20-22 | 客户端目标 SDK |
| ohpm | 随 DevEco 安装 | HarmonyOS 包管理器 |

## 快速开始

### 一、启动后端服务

#### 1. 安装 PostgreSQL

安装并启动 PostgreSQL 服务，然后创建数据库：

```sql
CREATE DATABASE flash_charging;
CREATE USER charging_app WITH PASSWORD 'your_password_here';
GRANT ALL PRIVILEGES ON DATABASE flash_charging TO charging_app;
GRANT ALL ON SCHEMA public TO charging_app;
```

#### 2. 配置环境变量

```bash
cd flash-charging-server
cp .env.example .env
```

编辑 `.env` 文件，修改数据库连接信息：

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=flash_charging
DB_USER=charging_app
DB_PASSWORD=your_password_here
```

#### 3. 安装依赖并初始化数据库

```bash
npm install          # 安装依赖
npm run db:push      # 根据 Schema 创建数据库表
npm run db:seed      # 填充测试数据（哈尔滨充电站）
```

种子数据包含：
- 测试账号：`admin` / `test`，密码均为 `123456`
- 11 个充电站（哈尔滨各区，含快充/慢充）
- 每站 3 个充电桩
- 5 张代金券

#### 4. 启动后端

```bash
npm run dev          # 开发模式（热重启，默认端口 3000）
```

看到 `寻电后端服务已启动: http://0.0.0.0:3000` 表示启动成功。

#### 5. 管理面板

浏览器访问 `http://localhost:3000/admin`，可管理用户、充电站、订单、代金券等数据。

### 二、运行客户端

#### 1. 打开项目

用 DevEco Studio 打开 `charging/` 目录。

#### 2. 确认后端地址

打开 `charging/entry/src/main/ets/utils/Http.ets`，确认 `baseUrl` 指向后端地址：

```typescript
const baseUrl: string = 'http://192.168.x.x:3000'
```

> 模拟器使用 `localhost`，真机需改为电脑的局域网 IP。

#### 3. 构建运行

在 DevEco Studio 中点击 **Run** 按钮，或使用命令行：

```bash
cd charging
hvigorw assembleHap -p module=entry    # 构建 HAP 包
```

## 核心功能

### 客户端

- **扫码即充** — ScanKit 扫描充电桩二维码，自动创建订单
- **实时充电** — 环形进度展示（SOC/电量/金额/时长），支持加速模拟
- **语音播报** — TTS 按可配间隔播报充电进度，支持息屏后台播报
- **预约充电** — 绑定桩口、设置时段和 SOC 目标，桌面卡片实时展示
- **路线规划** — MapKit 驾驶路线规划和导航
- **充电统计** — 充电量/消费/碳减排趋势图表
- **代金券** — 领取和使用代金券
- **多端适配** — Phone/Tablet/2in1 响应式布局（sm/md 断点）

### 小艺智能体（Celia）

通过 `@InsightIntentEntry` 装饰器接入小艺语音控制：

| 语音指令 | 功能 |
|----------|------|
| "搜索充电站" | 打开地图展示充电站 |
| "开始充电" | 进入充电流程 |
| "停止充电" | 结束当前充电 |
| "查看订单" | 打开订单列表 |
| "导航去充电站" | 打开路线规划 |
| "充电统计" | 打开数据分析看板 |

### 后端

- **JWT 认证** — 登录返回 accessToken/refreshToken，Bearer 方式鉴权
- **管理面板** — Web 端 CRUD 管理（极简白风格 + 数据图表）
- **充电模拟** — 后端驱动 SOC 递增，支持变速（加速模拟约1分钟充满）
- **RESTful API** — 30+ 端点，统一 ResultVO 响应格式

## 页面说明

| 页面 | 路径 | 说明 |
|------|------|------|
| 首页地图 | `pages/Index` | 主页，集成 MapKit 地图展示充电站标记，底部 Tab 导航（首页/我的），支持 sm/md 响应式断点 |
| 站点搜索 | `pages/home/homeSearch` | 关键词搜索充电站，支持综合/距离/价格排序，搜索历史记录，常去站点和收藏站点 Tab |
| 站点详情搜索 | `pages/home/siteSearch` | 按区域搜索站点，收藏站点管理 |
| 充电中 | `pages/charging/inCharging` | 充电进度页面，环形进度条（SOC%），实时数据面板（功率/已充/单价），加速模拟按钮，TTS 语音播报设置 |
| 订单列表 | `pages/order/orderList` | 分页懒加载订单，全部/待支付/已完成三 Tab 筛选 |
| 订单详情 | `pages/order/orderInfo` | 充电信息（时间/SOC/电量）+ 费用信息，待支付时弹出支付确认弹窗 |
| 支付成功 | `pages/order/orderEnd` | 支付结果展示（金额/代金券抵扣） |
| 路线规划 | `pages/routePlanning/index` | 起终点输入，MapKit 驾驶路线规划 |
| 路线搜索 | `pages/routePlanning/routeSearch` | 搜索起终点地点 |
| 路线地图 | `pages/routePlanning/planningLineMap` | 路线地图展示，沿途充电站标记 |
| 收藏列表 | `pages/siteCollection/collectSpots` | 用户收藏的充电站列表，支持搜索和取消收藏 |
| 站点详情 | `pages/siteCollection/siteInfo` | 充电站详细信息（桩口/价格/营业时间/服务商） |
| 代金券 | `pages/cardCoupons/index` | 代金券列表，领取和查看可用券 |
| 预约充电 | `pages/advanceCharging/index` | 绑定桩口、设置预约时段和 SOC 目标值，桌面卡片同步展示 |
| 账号管理 | `pages/user/accountManage` | 个人信息展示，退出登录 |
| 登录 | `pages/login/index` | 账号密码登录，JWT 自动登录检测 |
| 注册 | `pages/register/index` | 新用户注册（账号+昵称+密码），注册后自动登录 |
| 充电统计 | `pages/analytics/index` | 数据看板：总充电量/消费/次数/碳减排，月度趋势柱状图，常去站点 TOP5 |
| 使用教程 | `pages/tutorial/index` | 5 步图文使用引导 |

## 认证流程

```
客户端                              后端
  ├─ POST /login {account, password}─►│
  │◄── {accessToken, refreshToken} ──┤
  ├─ Authorization: Bearer <token> ──►│  后续所有请求
  │◄── ResultVO<T> ──────────────────┤
  ├─ token 过期 (EDU99999) ◄────────┤
  └─ 跳转登录页 ─────────────────────┘
```

## 技术栈

| 层级 | 技术 |
|------|------|
| 客户端 | ArkTS + ArkUI、MapKit、ScanKit、CoreSpeechKit、NotificationKit、FormKit |
| 后端 | Node.js + Express + TypeScript |
| 数据库 | PostgreSQL + Drizzle ORM |
| 认证 | JWT（jsonwebtoken + bcrypt） |
| 管理面板 | 纯 HTML + CSS + JS（Express 静态托管） |
| 语音控制 | HarmonyOS InsightIntent + 小艺智能体 |
