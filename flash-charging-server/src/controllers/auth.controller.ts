import { Response, NextFunction } from 'express'
import { authService } from '../services/auth.service'
import { success, fail } from '../utils/response'
import { AuthRequest, LoginForm } from '../types'

export async function register(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const { account, userName, password } = req.body as { account: string, userName: string, password: string }
    if (!account || !password) {
      res.json(fail('账号和密码不能为空'))
      return
    }
    if (account.length < 3 || account.length > 20) {
      res.json(fail('账号长度需在3-20个字符之间'))
      return
    }
    if (password.length < 6) {
      res.json(fail('密码长度不能少于6位'))
      return
    }
    const result = await authService.register(account, userName || account, password)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function login(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const { account, password } = req.body as LoginForm
    if (!account || !password) {
      res.json(fail('账号和密码不能为空'))
      return
    }
    const result = await authService.login(account, password)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function getUserInfo(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const result = await authService.getUserInfo(userId)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function getCsrfToken(req: AuthRequest, res: Response) {
  // 兼容端点：JWT 认证不再需要 CSRF token，返回占位数据
  res.json(success({ recentClassId: '', csrfToken: '' }))
}
