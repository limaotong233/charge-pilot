import { Router } from 'express'
import { authMiddleware, adminMiddleware } from '../middleware/auth'
import {
  getDashboard, getUsers, updateUser, createUser,
  getStations, createStation, updateStation, deleteStation,
  getPorts, createPort, updatePort, deletePort,
  getOrders, getReservations, cancelReservation,
  getVouchers, createVoucher, updateVoucher, deleteVoucher,
  getCollections,
} from '../controllers/admin.controller'
import { login } from '../controllers/auth.controller'

const router = Router()

// 管理端登录（公开）
router.post('/login', login)

// 以下路由需要管理员权限
router.use(authMiddleware, adminMiddleware)

// 仪表盘
router.get('/dashboard', getDashboard)

// 用户
router.get('/users', getUsers)
router.post('/users', createUser)
router.put('/users/:id', updateUser)

// 充电站
router.get('/stations', getStations)
router.post('/stations', createStation)
router.put('/stations/:id', updateStation)
router.delete('/stations/:id', deleteStation)

// 桩口
router.get('/stations/:stationId/ports', getPorts)
router.post('/ports', createPort)
router.put('/ports/:id', updatePort)
router.delete('/ports/:id', deletePort)

// 订单
router.get('/orders', getOrders)

// 预约
router.get('/reservations', getReservations)
router.delete('/reservations/:id', cancelReservation)

// 代金券
router.get('/vouchers', getVouchers)
router.post('/vouchers', createVoucher)
router.put('/vouchers/:id', updateVoucher)
router.delete('/vouchers/:id', deleteVoucher)

// 收藏
router.get('/collections', getCollections)

export default router
