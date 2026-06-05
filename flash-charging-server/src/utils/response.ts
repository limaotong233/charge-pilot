// 响应码定义（兼容客户端现有处理逻辑）
export const ResultCode = {
  SUCCESS: 'EDU00000',
  GENERAL_ERROR: 'EDU00001',
  VALIDATION_ERROR: 'EDU00002',
  RATE_LIMITED: 'EDU00003',
  SESSION_EXPIRED: 'EDU99999',
  SESSION_INVALID: 'EDU30021',
  SILENT_ERROR: 'EDU53025',
} as const

export interface ResultVO<T> {
  status: number
  msg: string
  data: T
  code: string
}

export function success<T>(data: T, msg = 'success'): ResultVO<T> {
  return { status: 200, msg, data, code: ResultCode.SUCCESS }
}

export function fail(msg: string, code: string = ResultCode.GENERAL_ERROR): ResultVO<null> {
  return { status: 200, msg, data: null, code }
}

export function sessionExpired(msg = '登录已过期'): ResultVO<null> {
  return { status: 200, msg, data: null, code: ResultCode.SESSION_EXPIRED }
}

export function validationError(msg: string): ResultVO<null> {
  return { status: 200, msg, data: null, code: ResultCode.VALIDATION_ERROR }
}
