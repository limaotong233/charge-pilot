import { db } from '../config/database'
import { users, stations, ports, orders, reservations, vouchers, userVouchers, collections, stationAccessRecords } from '../models/schema'
import { eq, like, sql, desc, and, count } from 'drizzle-orm'
import { getPagination } from '../utils/pagination'
import { hashPassword } from '../utils/password'

export class AdminService {
  // ============ 仪表盘 ============
  async getDashboard() {
    const [userCount] = await db.select({ count: count() }).from(users).where(eq(users.delFlag, 0))
    const [stationCount] = await db.select({ count: count() }).from(stations).where(eq(stations.delFlag, 1))
    const [orderCount] = await db.select({ count: count() }).from(orders)
    const [completedOrders] = await db.select({
      count: count(),
      totalCapacity: sql<number>`coalesce(sum(${orders.chargeCapacity}), 0)::float`,
      totalAmount: sql<number>`coalesce(sum(${orders.orderAmount}), 0)::float`,
    }).from(orders).where(eq(orders.orderStatus, 2))

    return {
      userCount: userCount.count,
      stationCount: stationCount.count,
      orderCount: orderCount.count,
      completedOrderCount: completedOrders.count,
      totalCapacity: Math.round((completedOrders.totalCapacity || 0) * 100) / 100,
      totalAmount: Math.round((completedOrders.totalAmount || 0) * 100) / 100,
    }
  }

  // ============ 用户管理 ============
  async getUsers(page: number, size: number, keyword: string) {
    const { offset, limit } = getPagination({ currentPage: page, pageSize: size })
    const conditions = keyword ? like(users.account, `%${keyword}%`) : undefined

    const [total] = await db.select({ count: count() }).from(users).where(conditions)
    const list = await db.select({
      id: users.id, account: users.account, userName: users.userName,
      createdAt: users.createdAt, delFlag: users.delFlag, role: users.role,
    }).from(users).where(conditions).orderBy(desc(users.createdAt)).limit(limit).offset(offset)

    return { total: total.count, list }
  }

  async updateUser(id: string, data: { userName?: string; password?: string }) {
    const updateData: Record<string, string> = {}
    if (data.userName) updateData.userName = data.userName
    if (data.password) updateData.passwordHash = await hashPassword(data.password)
    if (Object.keys(updateData).length === 0) return
    await db.update(users).set({ ...updateData, updatedAt: new Date() }).where(eq(users.id, id))
  }

  async createUser(data: { account: string; userName: string; password: string; role: string }) {
    const [existing] = await db.select({ id: users.id }).from(users).where(eq(users.account, data.account)).limit(1)
    if (existing) throw new Error('账号已存在')

    const passwordHash = await hashPassword(data.password)
    const [user] = await db.insert(users).values({
      account: data.account,
      userName: data.userName || data.account,
      passwordHash,
      role: data.role || 'user',
      delFlag: 0,
    }).returning({ id: users.id })

    return user.id
  }

  // ============ 充电站管理 ============
  async getStations(page: number, size: number, keyword: string) {
    const { offset, limit } = getPagination({ currentPage: page, pageSize: size })
    const conditions = [eq(stations.delFlag, 1)]
    if (keyword) conditions.push(like(stations.stationName, `%${keyword}%`))

    const [total] = await db.select({ count: count() }).from(stations).where(and(...conditions))
    const list = await db.select().from(stations).where(and(...conditions)).orderBy(desc(stations.createdAt)).limit(limit).offset(offset)

    return { total: total.count, list }
  }

  async createStation(data: Record<string, string | number | Date>) {
    const [station] = await db.insert(stations).values({
      stationName: data.stationName as string,
      stationType: (data.stationType as number) || 0,
      latitude: String(data.latitude || '0'),
      longitude: String(data.longitude || '0'),
      chargeType: (data.chargeType as number) || 0,
      portCount: (data.portCount as number) || 0,
      chargeFee: String(data.chargeFee || '0'),
      chargePower: String(data.chargePower || '0'),
      serviceProvider: (data.serviceProvider as string) || '',
      openTime: (data.openTime as string) || '00:00-24:00',
      delFlag: 1,
    }).returning({ id: stations.id })
    return station.id
  }

  async updateStation(id: string, data: Record<string, string | number | Date>) {
    const updateData: Record<string, string | number | Date> = {}
    if (data.stationName !== undefined) updateData.stationName = data.stationName
    if (data.chargeType !== undefined) updateData.chargeType = data.chargeType
    if (data.chargeFee !== undefined) updateData.chargeFee = String(data.chargeFee)
    if (data.chargePower !== undefined) updateData.chargePower = String(data.chargePower)
    if (data.latitude !== undefined) updateData.latitude = String(data.latitude)
    if (data.longitude !== undefined) updateData.longitude = String(data.longitude)
    if (data.serviceProvider !== undefined) updateData.serviceProvider = data.serviceProvider
    if (data.openTime !== undefined) updateData.openTime = data.openTime
    if (Object.keys(updateData).length === 0) return
    updateData.updatedAt = new Date()
    await db.update(stations).set(updateData as any).where(eq(stations.id, id))
  }

  async deleteStation(id: string) {
    await db.update(stations).set({ delFlag: 0, updatedAt: new Date() }).where(eq(stations.id, id))
  }

  // ============ 桩口管理 ============
  async getPorts(stationId: string) {
    return db.select().from(ports).where(eq(ports.stationId, stationId))
  }

  async createPort(data: Record<string, string | number | Date>) {
    await db.insert(ports).values({
      stationId: data.stationId as string,
      portName: data.portName as string,
      chargeFee: String(data.chargeFee || '0'),
      chargePower: String(data.chargePower || '0'),
      serviceProvider: (data.serviceProvider as string) || '',
      portStatus: 0,
    })
  }

  async updatePort(id: string, data: Record<string, string | number | Date>) {
    const updateData: Record<string, string | number | Date> = {}
    if (data.portName !== undefined) updateData.portName = data.portName
    if (data.chargeFee !== undefined) updateData.chargeFee = String(data.chargeFee)
    if (data.chargePower !== undefined) updateData.chargePower = String(data.chargePower)
    if (Object.keys(updateData).length === 0) return
    updateData.updatedAt = new Date()
    await db.update(ports).set(updateData).where(eq(ports.id, id))
  }

  async deletePort(id: string) {
    await db.delete(ports).where(eq(ports.id, id))
  }

  // ============ 订单管理 ============
  async getOrders(page: number, size: number, status: string) {
    const { offset, limit } = getPagination({ currentPage: page, pageSize: size })
    const conditions = status !== '' && status !== undefined ? eq(orders.orderStatus, Number(status)) : undefined

    const [total] = await db.select({ count: count() }).from(orders).where(conditions)
    const list = await db.select().from(orders).where(conditions).orderBy(desc(orders.createdAt)).limit(limit).offset(offset)

    return { total: total.count, list }
  }

  // ============ 预约管理 ============
  async getReservations(page: number, size: number) {
    const { offset, limit } = getPagination({ currentPage: page, pageSize: size })

    const [total] = await db.select({ count: count() }).from(reservations)
    const list = await db.select().from(reservations).orderBy(desc(reservations.createdAt)).limit(limit).offset(offset)

    return { total: total.count, list }
  }

  async cancelReservation(id: string) {
    await db.update(reservations).set({ status: 2, updatedAt: new Date() }).where(eq(reservations.id, id))
  }

  // ============ 代金券管理 ============
  async getVouchers(page: number, size: number) {
    const { offset, limit } = getPagination({ currentPage: page, pageSize: size })

    const [total] = await db.select({ count: count() }).from(vouchers)
    const list = await db.select().from(vouchers).orderBy(desc(vouchers.createdAt)).limit(limit).offset(offset)

    return { total: total.count, list }
  }

  async createVoucher(data: Record<string, string | number | Date>) {
    await db.insert(vouchers).values({
      voucherType: data.voucherType as string,
      voucherValue: String(data.voucherValue || '0'),
      totalNum: (data.totalNum as number) || 100,
    })
  }

  async updateVoucher(id: string, data: Record<string, string | number | Date>) {
    const updateData: Record<string, string | number | Date> = {}
    if (data.voucherType !== undefined) updateData.voucherType = data.voucherType
    if (data.voucherValue !== undefined) updateData.voucherValue = String(data.voucherValue)
    if (data.totalNum !== undefined) updateData.totalNum = data.totalNum
    if (Object.keys(updateData).length === 0) return
    updateData.updatedAt = new Date()
    await db.update(vouchers).set(updateData).where(eq(vouchers.id, id))
  }

  async deleteVoucher(id: string) {
    await db.delete(vouchers).where(eq(vouchers.id, id))
  }

  // ============ 收藏管理 ============
  async getCollections(page: number, size: number) {
    const { offset, limit } = getPagination({ currentPage: page, pageSize: size })

    const [total] = await db.select({ count: count() }).from(collections)
    const list = await db.select({
      id: collections.id,
      userId: collections.userId,
      stationId: collections.stationId,
      createdAt: collections.createdAt,
      stationName: stations.stationName,
      userName: users.userName,
    }).from(collections)
      .leftJoin(stations, eq(collections.stationId, stations.id))
      .leftJoin(users, eq(collections.userId, users.id))
      .orderBy(desc(collections.createdAt))
      .limit(limit).offset(offset)

    return { total: total.count, list }
  }
}

export const adminService = new AdminService()
