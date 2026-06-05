# 闪充（鸿蒙智能充电）| HarmonyOS / ArkTS / ArkUI / MapKit / ScanKit / TTS

- 独立开发鸿蒙原生跨设备充电服务平台，基于 **ArkTS 声明式 UI** 构建，通过 **6 大 API 模块 + 6 个 Service 服务** 实现业务层解耦

- 自建 **Node.js + Express + PostgreSQL** 后端替代原企业平台，基于 **Drizzle ORM** 实现类型安全持久化，设计 **9 张关联表**，通过 **PostgreSQL 排他约束** 防止预约时间冲突

- 基于 **JWT 无状态认证** 替代原 Cookie + CSRF 方案，实现登录/注册/Token 刷新全链路，统一 **ResultVO 响应封装** 与会话过期自动跳转

- 集成 **华为 MapKit 地图引擎**，实现充电站热力分布、路线规划导航与驾驶距离矩阵计算，支持 **distributedDataObject 跨设备续接**

- 实现 **扫码即充** 全闭环：ScanKit 扫码 → 选择桩口 → 创建订单 → 环形进度实时展示（SOC/电量/金额） → 支付结算，后端支持 **充电加速模拟**

- 集成 **CoreSpeechKit TTS** 按可配间隔播报进度，通过 **BackgroundTasksKit 长时任务** 实现息屏后台播报，电量满时推送 **系统通知**

- 支持 **预约充电**：模糊搜索站/桩 → 时段预约 → SOC 目标设置 → 定时轮询 → **FormKit 桌面服务卡片** 实时展示

- 基于 **状态装饰器（@State/@Prop/@Link/@StorageProp）** 构建多端响应式布局，**currentBreakpoint** 动态适配手机/平板导航切换

- 实现 **充电数据分析看板**，SQL 聚合输出充电量/消费/碳减排/站点 TOP5/趋势，前端 **CSS 柱状图 + SVG 环形图** 可视化

- 构建 **Web 管理面板**（Express 静态托管），覆盖用户/充电站/订单/预约/代金券 **7 大 CRUD 模块**，支持搜索、分页与弹窗编辑
