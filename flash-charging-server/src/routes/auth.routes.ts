import { Router } from 'express'
import { login, register, getUserInfo, getCsrfToken } from '../controllers/auth.controller'
import { authMiddleware } from '../middleware/auth'

const router = Router()

// 公开接口
router.post('/api/app/login', login)
router.post('/api/app/register', register)
router.post('/api/app/getCsrfToken', getCsrfToken) // 兼容端点

// 需要认证的接口
router.post('/user/selectUser', authMiddleware, getUserInfo)

export default router
