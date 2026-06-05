import rateLimit from 'express-rate-limit'

// 全局速率限制：每 IP 每分钟 120 次
export const globalLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 120,
  standardHeaders: true,
  legacyHeaders: false,
  message: { status: 200, msg: '请求过于频繁，请稍后再试', data: null, code: 'EDU00003' },
})

// 轮询接口专用：每用户每秒最多 2 次
export const pollingLimiter = rateLimit({
  windowMs: 1000,
  max: 2,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => (req as any).user?.userId || req.ip || 'unknown',
  message: { status: 200, msg: '请求过于频繁', data: null, code: 'EDU00003' },
})
