import { db } from '../config/database'
import { users, files } from '../models/schema'
import { eq, and } from 'drizzle-orm'
import { comparePassword, hashPassword } from '../utils/password'
import { signAccessToken, signRefreshToken } from '../utils/jwt'
import { LoginResult, UserInfoResult } from '../types'

export class AuthService {
  async register(account: string, userName: string, password: string): Promise<LoginResult> {
    // 检查账号是否已存在
    const [existing] = await db
      .select({ id: users.id })
      .from(users)
      .where(eq(users.account, account))
      .limit(1)

    if (existing) {
      throw new Error('账号已存在')
    }

    const passwordHash = await hashPassword(password)

    const [user] = await db.insert(users).values({
      account,
      userName,
      passwordHash,
      delFlag: 0,
    }).returning({ id: users.id, account: users.account })

    const payload = { userId: user.id, account: user.account }
    return {
      accessToken: signAccessToken(payload),
      refreshToken: signRefreshToken(payload),
    }
  }

  async login(account: string, password: string): Promise<LoginResult> {
    const [user] = await db
      .select()
      .from(users)
      .where(and(eq(users.account, account), eq(users.delFlag, 0)))
      .limit(1)

    if (!user) {
      throw new Error('账号或密码错误')
    }

    const valid = await comparePassword(password, user.passwordHash)
    if (!valid) {
      throw new Error('账号或密码错误')
    }

    const payload = { userId: user.id, account: user.account }
    return {
      accessToken: signAccessToken(payload),
      refreshToken: signRefreshToken(payload),
    }
  }

  async getUserInfo(userId: string): Promise<UserInfoResult> {
    const [user] = await db
      .select({
        account: users.account,
        userName: users.userName,
        avatarFileId: users.avatarFileId,
      })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1)

    if (!user) {
      throw new Error('用户不存在')
    }

    let fileAccessUrl = ''
    if (user.avatarFileId) {
      const [file] = await db
        .select({ fileCode: files.fileCode })
        .from(files)
        .where(eq(files.id, user.avatarFileId))
        .limit(1)
      if (file) {
        fileAccessUrl = `/userauth/api/file/downloadFile?fileCode=${file.fileCode}`
      }
    }

    return {
      account: user.account,
      userName: user.userName || user.account,
      avatar: { fileAccessUrl },
    }
  }
}

export const authService = new AuthService()
