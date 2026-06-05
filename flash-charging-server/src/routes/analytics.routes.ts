import { Router } from 'express'
import { getOverview } from '../controllers/analytics.controller'
import { authMiddleware } from '../middleware/auth'

const router = Router()
router.use(authMiddleware)

router.post('/overview', getOverview)

export default router
