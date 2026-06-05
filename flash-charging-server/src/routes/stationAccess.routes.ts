import { Router } from 'express'
import { addRecord, leaveRecord, getRecordDetail } from '../controllers/stationAccess.controller'
import { authMiddleware } from '../middleware/auth'

const router = Router()
router.use(authMiddleware)

router.post('/add', addRecord)
router.post('/leave', leaveRecord)
router.post('/detail', getRecordDetail)

export default router
