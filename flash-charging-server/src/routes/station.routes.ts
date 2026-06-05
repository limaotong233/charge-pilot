import { Router } from 'express'
import { getStationList, getStationDetail, getStationPortList } from '../controllers/station.controller'
import { authMiddleware } from '../middleware/auth'

const router = Router()
router.use(authMiddleware)

router.post('/list', getStationList)
router.post('/detail', getStationDetail)
router.post('/portList', getStationPortList)

export default router
