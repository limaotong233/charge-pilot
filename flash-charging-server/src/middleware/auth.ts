import { Response, NextFunction } from 'express'
import { verifyToken } from '../utils/jwt'
import { sessionExpired, fail, ResultCode } from '../utils/response'
import { AuthRequest } from '../types'

export function authMiddleware(req: AuthRequest, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.json(sessionExpired('未提供认证令牌'))
    return
  }

  const token = authHeader.substring(7)

  try {
    const payload = verifyToken(token)
    req.user = { userId: payload.userId, account: payload.account, role: payload.role }
    next()
  } catch (err: any) {
    if (err.name === 'TokenExpiredError') {
      res.json(fail('登录已过期', ResultCode.SESSION_EXPIRED))
    } else {
      res.json(fail('认证无效', ResultCode.SESSION_INVALID))
    }
  }
}

// 管理员权限中间件（在 authMiddleware 之后使用）
export function adminMiddleware(req: AuthRequest, res: Response, next: NextFunction): void {
  if (req.user?.role !== 'admin') {
    res.json(fail('无管理员权限', ResultCode.GENERAL_ERROR))
    return
  }
  next()
}
