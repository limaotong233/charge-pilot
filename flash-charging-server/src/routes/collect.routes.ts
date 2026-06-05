import { Router } from 'express'
import { getCollectList, addCollect, cancelCollect } from '../controllers/collect.controller'
import { authMiddleware } from '../middleware/auth'

const router = Router()
router.use(authMiddleware)

router.post('/list', getCollectList)
router.post('/add', addCollect)
router.post('/cancel', cancelCollect)

export default router
