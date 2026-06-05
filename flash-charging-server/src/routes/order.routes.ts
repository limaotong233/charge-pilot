import { Router } from 'express'
import { createOrder, getOrderDetail, getOrderAmount, payOrder, getOrderList, speedUpSimulation } from '../controllers/order.controller'
import { authMiddleware } from '../middleware/auth'
import { pollingLimiter } from '../middleware/rateLimiter'

const router = Router()
router.use(authMiddleware)

router.post('/create', createOrder)
router.post('/detail', pollingLimiter, getOrderDetail) // 1秒轮询，加限流
router.post('/amount', getOrderAmount)
router.post('/pay', payOrder)
router.post('/list', getOrderList)
router.post('/speedUp', speedUpSimulation)

export default router
