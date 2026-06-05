import { Router } from 'express'
import {
  getBindDetail, bind, unbind,
  addReservation, cancelReservation, getReserveDetail,
  getStationNameList, getPortNameList,
} from '../controllers/reserve.controller'
import { authMiddleware } from '../middleware/auth'
import { pollingLimiter } from '../middleware/rateLimiter'

const router = Router()
router.use(authMiddleware)

router.post('/bindDetail', getBindDetail)
router.post('/bind', bind)
router.post('/unbind', unbind)
router.post('/add', addReservation)
router.post('/cancel', cancelReservation)
router.post('/detail', pollingLimiter, getReserveDetail) // 1秒轮询
router.post('/stationNameList', getStationNameList)
router.post('/portNameList', getPortNameList)

export default router
