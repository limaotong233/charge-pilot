# 闪充 — 鸿蒙智能充电服务平台

鸿蒙原生电动汽车充电服务平台，包含 HarmonyOS NEXT 客户端和自建后端服务。

## 项目结构

```
flash-charging/
├── charging/                   # HarmonyOS NEXT 客户端（ArkTS）
│   ├── entry/                  # 主 HAP 模块
│   │   └── src/main/ets/       # 源码（pages / api / components / service）
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
    │   ├── middleware/          # 中间件（JWT认证、错误处理、限流）
    │   └── config/             # 配置（数据库、环境变量）
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
| HarmonyOS SDK | API 12-23 | 客户端目标 SDK |
| ohpm | 随 DevEco 安装 | HarmonyOS 包管理器 |

## 快速开始

### 一、启动后端服务

#### 1. 安装 PostgreSQL

安装并启动 PostgreSQL 服务，然后创建数据库：

```sql
CREATE DATABASE flash_charging;
CREATE USER charging_app WITH PASSWORD 'your_password_here';
GRANT ALL PRIVILEGES ON DATABASE flash_charging TO charging_app;
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
npm run db:seed      # 填充测试数据
```

种子数据包含：
- 测试账号：`admin` / `test`，密码均为 `123456`
- 10 个充电站（杭州市各区，含快充/慢充）
- 每站 3 个充电桩
- 5 张代金券

#### 4. 启动后端

```bash
npm run dev          # 开发模式（热重启，默认端口 3000）
```

看到 `闪充后端服务已启动: http://localhost:3000` 表示启动成功。

### 二、运行客户端

#### 1. 打开项目

用 DevEco Studio 打开 `charging/` 目录。

#### 2. 确认后端地址

打开 `charging/entry/src/main/ets/utils/ets/Http.ets`，确认 `baseUrl` 指向后端地址：

```typescript
const baseUrl: string = 'http://localhost:3000'
```

> 如果使用模拟器，`localhost` 指向宿主机。如果使用真机，需改为电脑的局域网 IP（如 `http://192.168.1.100:3000`）。

#### 3. 构建运行

在 DevEco Studio 中点击 **Run** 按钮，或使用命令行：

```bash
cd charging
hvigor assembleHap    # 构建 HAP 包
```

## 认证流程

应用使用 JWT Token 认证（已替代原 Talent 平台的 Cookie + CSRF 方案）：

```
客户端                              后端
  │                                  │
  ├─ POST /login {account, password}─►│
  │◄── {accessToken, refreshToken} ──┤
  │                                  │
  ├─ Authorization: Bearer <token> ──►│  后续所有请求
  │◄── ResultVO<T> ──────────────────┤
  │                                  │
  ├─ token 过期 (EDU99999) ◄────────┤
  └─ 跳转登录页 ─────────────────────┘
```

## API 响应格式

所有接口统一返回 `ResultVO<T>` 格式：

```json
{
  "status": 200,
  "msg": "success",
  "data": { ... },
  "code": "EDU00000"
}
```

| 状态码 | 含义 |
|--------|------|
| `EDU00000` | 成功 |
| `EDU00001` | 业务错误 |
| `EDU99999` | 会话过期 |
| `EDU30021` | 会话无效 |
| `EDU53025` | 静默错误（不弹 Toast） |

## 主要技术栈

**客户端：**
- ArkTS + ArkUI 声明式 UI
- MapKit（地图/导航/距离矩阵）
- ScanKit（扫码识别充电桩）
- CoreSpeechKit（TTS 语音播报）
- NotificationKit（充电完成通知）
- FormKit（桌面服务卡片）

**后端：**
- Node.js + Express + TypeScript
- PostgreSQL + Drizzle ORM
- JWT 认证（jsonwebtoken + bcrypt）
- Zod 请求校验
