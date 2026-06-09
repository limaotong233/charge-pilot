# 电寻后端服务

自建后端，为电寻 HarmonyOS 应用提供 API 服务。

## 技术栈

- **运行时**: Node.js + TypeScript
- **框架**: Express 4
- **数据库**: PostgreSQL + Drizzle ORM
- **认证**: JWT (JSON Web Token)

## 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 配置环境变量

复制 `.env.example` 为 `.env`，修改数据库连接信息：

```bash
cp .env.example .env
```

### 3. 创建数据库

在 PostgreSQL 中创建数据库：

```sql
CREATE DATABASE flash_charging;
CREATE USER charging_app WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE flash_charging TO charging_app;
```

### 4. 初始化数据库表

```bash
npm run db:push
```

### 5. 填充测试数据

```bash
npm run db:seed
```

测试账号：`admin` / `test`，密码：`123456`

### 6. 启动服务

```bash
npm run dev    # 开发模式（自动重启）
npm run build  # 编译
npm start      # 生产模式
```

服务默认运行在 `http://localhost:3000`

## API 概览

### 认证（/userauth）
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /userauth/api/app/login | 登录，返回 JWT |
| POST | /userauth/user/selectUser | 获取用户信息（需认证） |
| GET | /userauth/api/file/downloadFile | 下载头像文件 |

### 充电站（/chargelab/app/station）
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /list | 站点列表（分页+筛选） |
| POST | /detail | 站点详情 |
| POST | /portList | 桩口列表 |

### 订单（/chargelab/app/order）
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /create | 创建充电订单 |
| POST | /detail | 订单详情（1秒轮询） |
| POST | /amount | 计算充电金额 |
| POST | /pay | 支付订单 |
| POST | /list | 订单列表 |

### 预约（/chargelab/app/reserve）
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /bind | 绑定充电桩 |
| POST | /unbind | 解绑充电桩 |
| POST | /bindDetail | 绑定详情 |
| POST | /add | 创建预约 |
| POST | /cancel | 取消预约 |
| POST | /detail | 预约详情（1秒轮询） |
| POST | /stationNameList | 站点名称搜索 |
| POST | /portNameList | 桩口名称列表 |

### 代金券（/chargelab/app/voucher）
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /list | 代金券列表 |
| POST | /count | 用户可领代金券数量 |
| POST | /add | 领取代金券 |

### 收藏（/chargelab/app/collect）
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /list | 收藏列表 |
| POST | /add | 添加收藏 |
| POST | /cancel | 取消收藏 |

### 进站记录（/chargelab/app/stationAccessRecord）
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /add | 进入站点 |
| POST | /leave | 离开站点 |
| POST | /detail | 当前进站记录 |

## 认证方式

登录成功后返回 `{ accessToken, refreshToken }`，后续请求在 Header 中携带：

```
Authorization: Bearer <accessToken>
```

Token 过期返回 `code: EDU99999`，客户端自动跳转登录页。

## Web 管理面板

浏览器访问 **http://localhost:3000/admin** 即可使用。

### 功能模块

| 模块 | 功能 |
|------|------|
| 概览（仪表盘） | 注册用户数、充电站数、完成订单数、总收入；月度充电量柱状图、订单状态环形图、关键指标面板 |
| 用户管理 | 用户列表、按账号搜索、编辑用户名、重置密码 |
| 充电站管理 | 充电站 CRUD（新增/编辑/删除），桩口管理（查看/新增/删除），支持按站名搜索 |
| 订单管理 | 订单列表，按状态筛选（进行中/待支付/已完成），显示订单号、站点、电量、金额 |
| 预约管理 | 预约列表，支持取消进行中的预约 |
| 代金券管理 | 代金券 CRUD（新增/删除），显示面值、总量、已领数量 |
| 收藏管理 | 查看用户收藏记录 |

### 使用方式

1. 启动后端服务：`npm run dev`
2. 浏览器打开：`http://localhost:3000/admin`
3. 左侧菜单切换模块，右侧内容区操作数据

### 技术说明

- 纯 HTML + CSS + JavaScript，无需构建，由 Express 静态托管
- 通过 `fetch()` 调用 `/admin/api/*` 专用管理端 API
- 极简白风格 + 蓝色主色调，含 CSS 柱状图和 SVG 环形图
- 支持搜索、分页、弹窗编辑表单
- 文件位置：`public/` 目录
