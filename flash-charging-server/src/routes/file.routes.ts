import { Router } from 'express'
import { downloadFile } from '../controllers/file.controller'

const router = Router()

// 文件下载无需认证（通过 fileCode 访问）
router.get('/downloadFile', downloadFile)

export default router
