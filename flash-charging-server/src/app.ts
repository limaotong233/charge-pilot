import express from 'express'
import path from 'path'
import cors from 'cors'
import helmet from 'helmet'
import morgan from 'morgan'
import { globalLimiter } from './middleware/rateLimiter'
import { errorHandler, notFoundHandler } from './middleware/errorHandler'

// 路由导入
import authRoutes from './routes/auth.routes'
import stationRoutes from './routes/station.routes'
import stationAccessRoutes from './routes/stationAccess.routes'
import orderRoutes from './routes/order.routes'
import reserveRoutes from './routes/reserve.routes'
import voucherRoutes from './routes/voucher.routes'
import collectRoutes from './routes/collect.routes'
import analyticsRoutes from './routes/analytics.routes'
import fileRoutes from './routes/file.routes'
import adminRoutes from './routes/admin.routes'

const app = express()

// ============ 中间件 ============
app.use(helmet({ contentSecurityPolicy: false }))
app.use(cors())
app.use(express.json({ limit: '10mb' }))
app.use(morgan('dev'))
app.use(globalLimiter)

// ============ 静态文件托管（管理面板） ============
app.use('/admin', express.static(path.join(__dirname, '../public')))

// ============ 路由注册 ============
// 管理端 API
app.use('/admin/api', adminRoutes)

// 认证服务
app.use('/userauth', authRoutes)

// 充电业务服务
app.use('/chargelab/app/station', stationRoutes)
app.use('/chargelab/app/stationAccessRecord', stationAccessRoutes)
app.use('/chargelab/app/order', orderRoutes)
app.use('/chargelab/app/reserve', reserveRoutes)
app.use('/chargelab/app/voucher', voucherRoutes)
app.use('/chargelab/app/collect', collectRoutes)
app.use('/chargelab/app/analytics', analyticsRoutes)

// 文件下载
app.use('/chargelab/app/file', fileRoutes)
app.use('/userauth/api/file', fileRoutes)

// 管理面板首页（直接访问 /admin 时）
app.get('/admin', (_req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'))
})

// ============ 错误处理 ============
app.use(notFoundHandler)
app.use(errorHandler)

export default app
