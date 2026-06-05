import { db } from '../config/database'
import { vouchers, userVouchers } from '../models/schema'
import { eq, and, sql } from 'drizzle-orm'
import { getPagination, PaginatedResult } from '../utils/pagination'
import { VoucherListBody, VoucherListItem } from '../types'

export class VoucherService {
  async getVoucherList(
    userId: string, body: VoucherListBody
  ): Promise<PaginatedResult<VoucherListItem>> {
    const { offset, limit } = getPagination(body)

    const [countResult] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(vouchers)

    const rows = await db
      .select({
        voucherId: vouchers.id,
        voucherType: vouchers.voucherType,
        usedNum: vouchers.usedNum,
        totalNum: vouchers.totalNum,
        voucherValue: vouchers.voucherValue,
      })
      .from(vouchers)
      .limit(limit)
      .offset(offset)

    const list: VoucherListItem[] = rows.map(r => ({
      voucherId: r.voucherId,
      voucherType: r.voucherType,
      usedNum: r.usedNum,
      totalNum: r.totalNum,
      voucherValue: Number(r.voucherValue),
    }))

    return { total: countResult.count, list }
  }

  async getVoucherCount(userId: string): Promise<number> {
    const [result] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(userVouchers)
      .where(and(eq(userVouchers.userId, userId), eq(userVouchers.isUsed, 0)))

    return result.count
  }

  async addVoucher(userId: string, voucherId: string): Promise<void> {
    // 检查是否已领取
    const [existing] = await db
      .select({ id: userVouchers.id })
      .from(userVouchers)
      .where(and(eq(userVouchers.userId, userId), eq(userVouchers.voucherId, voucherId)))
      .limit(1)

    if (existing) throw new Error('您已领取过该代金券')

    // 检查库存
    const [voucher] = await db
      .select({ totalNum: vouchers.totalNum, usedNum: vouchers.usedNum })
      .from(vouchers)
      .where(eq(vouchers.id, voucherId))
      .limit(1)

    if (!voucher) throw new Error('代金券不存在')
    if (voucher.usedNum >= voucher.totalNum) throw new Error('代金券已被领完')

    // 领取代金券
    await db.insert(userVouchers).values({
      userId,
      voucherId,
      isUsed: 0,
    })

    // 更新已领取数量
    await db.update(vouchers)
      .set({ usedNum: sql`${vouchers.usedNum} + 1`, updatedAt: new Date() })
      .where(eq(vouchers.id, voucherId))
  }
}

export const voucherService = new VoucherService()
