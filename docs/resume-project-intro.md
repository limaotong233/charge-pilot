## 简历项目介绍 — 闪充

::: start
**闪充（电动汽车充电服务平台） | HarmonyOS NEXT / ArkTS / ArkUI / MapKit / Node.js / Express / PostgreSQL**
::: end

- **独立负责**鸿蒙原生全栈充电平台架构设计与开发，客户端采用 **ArkUI 声明式 UI** 构建 19 个业务页面，后端基于 **Express + Drizzle ORM + PostgreSQL** 实现 10 个 RESTful 模块，通过 **JWT + RemoteCommunicationKit** 构建安全通信层

- 深度集成 **MapKit** 实现 LBS 核心能力：充电站地理围栏标注、多路线规划与**驾驶距离矩阵**实时计算，结合 **LocationKit** 构建用户位置感知与站点智能推荐

- 设计并实现**跨端无缝续接**方案，基于 **distributedDataObject** 分布式数据对象完成页面栈、导航状态、业务上下文的全量迁移，支持手机→平板/2in1 **零感知流转**

- 构建**一多响应式布局体系**，通过断点系统（sm/md/lg）驱动 19 个页面在手机底部 Tab 与平板侧边栏间自适应切换，实现**一套代码多端部署**

- 集成 **CoreSpeechKit TTS** + **BackgroundTasksKit 长时任务**实现充电进度息屏后台持续语音播报，集成 **ScanKit** 扫码秒级识别充电桩启动充电，**FormKit** 桌面卡片实时同步预约状态

- 设计完整充电业务引擎：站点详情→**仿真充电**（实时功率曲线/SOC 动态计算/费用实时结算）→订单全生命周期管理，支持有序桩预约与多维车辆参数建模

- 构建**分布式数据持久化层**：KV 存储实现业务数据跨设备实时同步，**LazyForEach** 虚拟列表优化大数据量站点渲染，**LocalPreferences** 单例封装用户偏好管理
