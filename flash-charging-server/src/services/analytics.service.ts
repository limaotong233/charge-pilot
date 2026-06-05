import { db } from '../config/database'
import { orders } from '../models/schema'
import { eq, and, sql, desc } from 'drizzle-orm'
import { AnalyticsOverview } from '../types'

// 碳减排系数：每 kWh 电动车替代燃油车平均减排 CO₂ (kg)
const CO2_FACTOR = 0.785

export class AnalyticsService {
  async getOverview(userId: string): Promise<AnalyticsOverview> {
    // 只统计已完成的订单（orderStatus = 2）
    const conditions = and(eq(orders.userId, userId), eq(orders.orderStatus, 2))

    // 1. 总体统计
    const [stats] = await db
      .select({
        totalOrders: sql<number>`count(*)::int`,
        totalCapacity: sql<number>`coalesce(sum(${orders.chargeCapacity}), 0)::float`,
        totalAmount: sql<number>`coalesce(sum(${orders.orderAmount}), 0)::float`,
      })
      .from(orders)
      .where(conditions)

    const totalOrders = stats.totalOrders || 0
    const totalCapacity = Math.round((stats.totalCapacity || 0) * 100) / 100
    const totalAmount = Math.round((stats.totalAmount || 0) * 100) / 100
    const avgCapacity = totalOrders > 0 ? Math.round((totalCapacity / totalOrders) * 100) / 100 : 0
    const avgAmount = totalOrders > 0 ? Math.round((totalAmount / totalOrders) * 100) / 100 : 0
    const co2Reduction = Math.round(totalCapacity * CO2_FACTOR * 100) / 100

    // 2. 常去充电站 TOP5
    const topStations = await db
      .select({
        stationName: orders.stationName,
        count: sql<number>`count(*)::int`,
      })
      .from(orders)
      .where(conditions)
      .groupBy(orders.stationName)
      .orderBy(desc(sql`count(*)`))
      .limit(5)

    // 3. 近6个月充电趋势
    const monthlyTrend = await db
      .select({
        month: sql<string>`to_char(${orders.startTime}, 'YYYY-MM')`,
        capacity: sql<number>`coalesce(sum(${orders.chargeCapacity}), 0)::float`,
        amount: sql<number>`coalesce(sum(${orders.orderAmount}), 0)::float`,
      })
      .from(orders)
      .where(and(
        conditions,
        sql`${orders.startTime} >= (current_date - interval '6 months')`
      ))
      .groupBy(sql`to_char(${orders.startTime}, 'YYYY-MM')`)
      .orderBy(sql`to_char(${orders.startTime}, 'YYYY-MM')`)

    return {
      totalOrders,
      totalCapacity,
      totalAmount,
      avgCapacity,
      avgAmount,
      co2Reduction,
      topStations: topStations.map(s => ({
        stationName: s.stationName,
        count: s.count,
      })),
      monthlyTrend: monthlyTrend.map(m => ({
        month: m.month,
        capacity: Math.round(m.capacity * 100) / 100,
        amount: Math.round(m.amount * 100) / 100,
      })),
    }
  }
}

export const analyticsService = new AnalyticsService()
