import { Router } from 'express'
import { getVoucherList, getVoucherCount, addVoucher } from '../controllers/voucher.controller'
import { authMiddleware } from '../middleware/auth'

const router = Router()
router.use(authMiddleware)

router.post('/list', getVoucherList)
router.post('/count', getVoucherCount)
router.post('/add', addVoucher)

export default router
