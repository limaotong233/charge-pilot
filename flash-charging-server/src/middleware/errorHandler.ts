import { Request, Response, NextFunction } from 'express'
import { fail, ResultCode } from '../utils/response'

export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction): void {
  console.error('服务器错误:', err)

  if (err.name === 'MulterError') {
    res.json(fail('文件上传错误: ' + err.message))
    return
  }

  res.json(fail(err.message || '服务异常'))
}

export function notFoundHandler(_req: Request, res: Response): void {
  res.json(fail('接口不存在'))
}
