# 闪充（鸿蒙智能充电）| HarmonyOS / ArkTS / MapKit / ScanKit / TTS

- 独立开发鸿蒙原生电动汽车充电服务平台，基于 **ArkTS + ArkUI 声明式 UI** 构建，自建 **Node.js + Express + PostgreSQL** 后端，通过 **JWT 无状态认证 + Drizzle ORM + Zod 校验** 实现全链路类型安全，**9 张关联表** + **PostgreSQL 排他约束** 保障预约时序一致性

- 集成 **华为 MapKit** 实现充电站热力分布、路线规划导航与驾驶距离矩阵计算，支持 **distributedDataObject 跨设备续接** 保持首页导航状态无缝迁移；基于 **@State/@Prop/@Link/@StorageProp** 装饰器 + **currentBreakpoint** 构建 Phone/Tablet/2in1 多端自适应布局，手机底部 Tab 与平板左侧导航栏智能切换

- 实现 **扫码即充** 全闭环：**ScanKit** 解析充电桩二维码 → 选择桩口 → 创建订单 → 环形进度实时展示（SOC/电量/金额/时长）→ 支付结算；集成 **CoreSpeechKit TTS** 按可配间隔播报进度，配合 **BackgroundTasksKit 长时任务（audioPlayback + location）** 实现息屏后台播报，电量满时推送 **NotificationKit 系统通知**

- 支持 **有序桩绑定 + 预约充电**：模糊搜索站/桩 → DatePickerDialog 预约时段 → SOC 目标设置（Slider 20%~100%，步长 5%）→ 1s 轮询状态 → **FormKit 桌面服务卡片**实时展示；启动时自动检测进站/充电状态并恢复界面

- 实现 **充电数据分析看板**：SQL 聚合查询输出总充电量/消费/碳减排/常去站点 TOP5/近 6 月趋势，前端 **CSS 柱状图 + SVG 环形图 + 迷你趋势线** 可视化

- 构建 **Web 管理面板**（Express 静态托管，纯 HTML/CSS/JS 零构建依赖），覆盖用户/充电站/桩口/订单/预约/代金券/收藏 **7 大 CRUD 管理模块**，支持搜索、分页与弹窗编辑

- 统一封装 **Http 请求层**，JWT Bearer Token 自动注入 + 会话过期码（EDU99999）自动跳转登录；覆盖位置、相机、麦克风、后台运行等 **多权限管理**
