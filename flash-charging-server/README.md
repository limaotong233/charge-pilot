# 闪充后端服务

自建后端，替代原 Talent 平台，为闪充 HarmonyOS 应用提供 API 服务。

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
