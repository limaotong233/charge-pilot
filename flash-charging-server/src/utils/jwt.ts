import jwt from 'jsonwebtoken'
import { config } from '../config'

export interface JwtPayload {
  userId: string
  account: string
  role: string
}

export function signAccessToken(payload: JwtPayload): string {
  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.accessExpiry as any,
  })
}

export function signRefreshToken(payload: JwtPayload): string {
  return jwt.sign(payload, config.jwt.secret, {
    expiresIn: config.jwt.refreshExpiry as any,
  })
}

export function verifyToken(token: string): JwtPayload {
  return jwt.verify(token, config.jwt.secret) as JwtPayload
}
