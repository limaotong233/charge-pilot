import { db } from '../config/database'
import { orders, ports, stations } from '../models/schema'
import { eq, and, sql, desc } from 'drizzle-orm'
import { getPagination, PaginatedResult } from '../utils/pagination'
import {
  OrderCreateBody, OrderCreateResult, OrderDetailItem,
  OrderListBody, OrderListItem, OrderPayPrice,
} from '../types'

// 活跃的充电模拟定时器
const activeSimulations = new Map<string, NodeJS.Timeout>()

export class OrderService {
  async createOrder(userId: string, userName: string, body: OrderCreateBody): Promise<OrderCreateResult> {
    // 检查用户是否有进行中的订单
    const [activeOrder] = await db
      .select({ id: orders.id })
      .from(orders)
      .where(and(eq(orders.userId, userId), eq(orders.orderStatus, 0)))
      .limit(1)

    if (activeOrder) {
      throw new Error('您有正在进行的订单，请先完成')
    }

    const orderNo = `OC${Date.now()}${Math.random().toString(36).substring(2, 6).toUpperCase()}`
    const seconds = 3600 // 默认充电时长限制 1 小时

    const [order] = await db.insert(orders).values({
      orderNo,
      userId,
      stationId: body.stationId,
      stationName: body.stationName,
      portId: body.portId,
      portName: body.portName,
      isReserve: body.isReserve,
      orderStatus: 0,
      initialValue: 20, // 默认起始SOC
      soc: 20,
      userName,
      startTime: new Date(),
    }).returning({ id: orders.id })

    // 更新充电桩状态为充电中
    await db.update(ports)
      .set({ portStatus: 2, updatedAt: new Date() })
      .where(eq(ports.id, body.portId))

    // 模拟充电进度更新（启动后台任务）
    this.simulateChargingProgress(order.id, 5000) // 默认5秒/1%

    return { number: orderNo, seconds, orderId: order.id }
  }

  private simulateChargingProgress(orderId: string, intervalMs: number) {
    // 清除已有的模拟
    const existing = activeSimulations.get(orderId)
    if (existing) clearInterval(existing)

    // 获取当前SOC作为起点
    db.select({ soc: orders.soc })
      .from(orders)
      .where(eq(orders.id, orderId))
      .limit(1)
      .then(([order]) => {
        let soc = order?.soc || 20

        const interval = setInterval(async () => {
          soc += 1
          if (soc > 100) soc = 100

          const chargeTime = (soc - 20) * (intervalMs / 1000)
          const chargeCapacity = ((soc - 20) / 100 * 60).toFixed(4)

          await db.update(orders)
            .set({
              soc,
              chargeTime: Math.round(chargeTime),
              chargeCapacity,
              updatedAt: new Date(),
            })
            .where(eq(orders.id, orderId))

          if (soc >= 100) {
            clearInterval(interval)
            activeSimulations.delete(orderId)
          }
        }, intervalMs)

        activeSimulations.set(orderId, interval)
      })
  }

  // 加速充电模拟（约1分钟充满）
  async speedUpSimulation(userId: string, orderId: string): Promise<void> {
    const [order] = await db
      .select()
      .from(orders)
      .where(and(eq(orders.id, orderId), eq(orders.userId, userId), eq(orders.orderStatus, 0)))
      .limit(1)

    if (!order) throw new Error('订单不存在或不在充电中')

    // 用快速模拟替换（~0.75秒/1%，约1分钟充满剩余部分）
    this.simulateChargingProgress(orderId, 750)
  }

  async getOrderDetail(userId: string, orderId: string): Promise<OrderDetailItem | null> {
    const [order] = await db
      .select()
      .from(orders)
      .where(and(eq(orders.id, orderId), eq(orders.userId, userId)))
      .limit(1)

    if (!order) return null

    return {
      orderId: order.id,
      stationName: order.stationName,
      portName: order.portName,
      orderAmount: Number(order.orderAmount) || 0,
      startTime: order.startTime?.toISOString() || '',
      endTime: order.endTime?.toISOString() || '',
      orderNo: order.orderNo,
      portId: order.portId,
      orderStatus: order.orderStatus,
      payTime: order.payTime?.toISOString() || '',
      chargeCapacity: Number(order.chargeCapacity) || 0,
      chargePower: Number(order.chargePower) || 0,
      chargeFee: Number(order.chargeFee) || 0,
      userName: order.userName || '',
      initialValue: order.initialValue || 0,
      paymentMethod: order.paymentMethod || '',
      chargeTime: order.chargeTime || 0,
      soc: order.soc || 0,
    }
  }

  async calculateAmount(userId: string, orderId: string): Promise<OrderPayPrice> {
    const [order] = await db
      .select()
      .from(orders)
      .where(and(eq(orders.id, orderId), eq(orders.userId, userId)))
      .limit(1)

    if (!order) throw new Error('订单不存在')

    // 计算充电金额：充电量 * 电费单价
    const capacity = parseFloat(order.chargeCapacity || '0')
    const fee = parseFloat(order.chargeFee || '0.5')
    const amount = (capacity * fee).toFixed(2)

    await db.update(orders)
      .set({
        orderAmount: amount,
        orderStatus: 1, // 待支付
        endTime: new Date(),
        updatedAt: new Date(),
      })
      .where(eq(orders.id, orderId))

    // 恢复充电桩为空闲
    await db.update(ports)
      .set({ portStatus: 0, updatedAt: new Date() })
      .where(eq(ports.id, order.portId))

    return { price: Number(amount) }
  }

  async payOrder(userId: string, orderId: string): Promise<void> {
    const [order] = await db
      .select()
      .from(orders)
      .where(and(
        eq(orders.id, orderId),
        eq(orders.userId, userId),
        eq(orders.orderStatus, 1)
      ))
      .limit(1)

    if (!order) throw new Error('订单不存在或状态异常')

    await db.update(orders)
      .set({
        orderStatus: 2, // 已支付
        payTime: new Date(),
        updatedAt: new Date(),
      })
      .where(eq(orders.id, orderId))

    // 支付完成后，站点使用次数 +1
    await db.update(stations)
      .set({ usedCount: sql`${stations.usedCount} + 1`, updatedAt: new Date() })
      .where(eq(stations.id, order.stationId))
  }

  async getOrderList(
    userId: string, body: OrderListBody
  ): Promise<PaginatedResult<OrderListItem>> {
    const { offset, limit } = getPagination(body)

    const conditions = [eq(orders.userId, userId)]
    if (body.orderStatus !== null && body.orderStatus !== undefined) {
      conditions.push(eq(orders.orderStatus, body.orderStatus))
    }

    const whereClause = and(...conditions)

    const [countResult] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(orders)
      .where(whereClause)

    const rows = await db
      .select({
        orderId: orders.id,
        stationName: orders.stationName,
        portName: orders.portName,
        orderAmount: orders.orderAmount,
        orderStatus: orders.orderStatus,
        startTime: orders.startTime,
        endTime: orders.endTime,
        chargeCapacity: orders.chargeCapacity,
      })
      .from(orders)
      .where(whereClause)
      .orderBy(desc(orders.createdAt))
      .limit(limit)
      .offset(offset)

    const list: OrderListItem[] = rows.map(r => ({
      orderId: r.orderId,
      stationName: r.stationName,
      portName: r.portName,
      orderAmount: Number(r.orderAmount) || 0,
      orderStatus: r.orderStatus,
      startTime: r.startTime?.toISOString() || '',
      endTime: r.endTime?.toISOString() || '',
      chargeCapacity: Number(r.chargeCapacity) || 0,
    }))

    return { total: countResult.count, list }
  }
}

export const orderService = new OrderService()
