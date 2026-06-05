import { db } from '../config/database'
import { reservations, ports, stations, portBindings } from '../models/schema'
import { eq, and, like, sql } from 'drizzle-orm'
import { getPagination } from '../utils/pagination'
import {
  BindBody, BindDetailItem, ReserveAddBody, ReserveDetailItem,
  StationNameListBody, PortNameListBody, StationNameItem, PortNameItem,
} from '../types'

export class ReserveService {
  async getBindDetail(userId: string, id: string): Promise<BindDetailItem | null> {
    const [binding] = await db
      .select()
      .from(portBindings)
      .where(and(eq(portBindings.id, id), eq(portBindings.userId, userId)))
      .limit(1)

    if (!binding) return null

    return {
      id: binding.id,
      userId: binding.userId,
      stationId: binding.stationId,
      portId: binding.portId,
      stationName: binding.stationName,
      portName: binding.portName,
    }
  }

  async bind(userId: string, body: BindBody): Promise<void> {
    // 查找充电站
    const [station] = await db
      .select({ id: stations.id })
      .from(stations)
      .where(eq(stations.stationName, body.stationName))
      .limit(1)

    if (!station) throw new Error('充电站不存在')

    // 查找充电桩
    const [port] = await db
      .select({ id: ports.id })
      .from(ports)
      .where(and(eq(ports.stationId, station.id), eq(ports.portName, body.portName)))
      .limit(1)

    if (!port) throw new Error('充电桩不存在')

    // 检查是否已绑定
    const [existing] = await db
      .select({ id: portBindings.id })
      .from(portBindings)
      .where(and(eq(portBindings.userId, userId), eq(portBindings.portId, port.id)))
      .limit(1)

    if (existing) throw new Error('该充电桩已绑定')

    await db.insert(portBindings).values({
      userId,
      stationId: station.id,
      portId: port.id,
      stationName: body.stationName,
      portName: body.portName,
    })
  }

  async unbind(userId: string, id: string): Promise<void> {
    const result = await db
      .delete(portBindings)
      .where(and(eq(portBindings.id, id), eq(portBindings.userId, userId)))
      .returning({ id: portBindings.id })

    if (result.length === 0) throw new Error('绑定记录不存在')
  }

  async addReservation(userId: string, body: ReserveAddBody): Promise<void> {
    // 获取站点和桩口信息
    const [station] = await db
      .select({ stationName: stations.stationName })
      .from(stations)
      .where(eq(stations.id, body.stationId))
      .limit(1)

    const [port] = await db
      .select({ portName: ports.portName })
      .from(ports)
      .where(eq(ports.id, body.portId))
      .limit(1)

    if (!station || !port) throw new Error('充电站或充电桩不存在')

    // 检查时间冲突
    const conflict = await db
      .select({ id: reservations.id })
      .from(reservations)
      .where(and(
        eq(reservations.portId, body.portId),
        eq(reservations.status, 0),
        sql`tsrange(${reservations.startTime}, ${reservations.endTime}) && tsrange(${body.startTime}::timestamp, ${body.endTime}::timestamp)`
      ))
      .limit(1)

    if (conflict.length > 0) {
      throw new Error('该时段已被预约')
    }

    await db.insert(reservations).values({
      userId,
      stationId: body.stationId,
      portId: body.portId,
      stationName: station.stationName,
      portName: port.portName,
      startTime: new Date(body.startTime),
      endTime: new Date(body.endTime),
      socValue: body.socValue,
      status: 0,
    })

    // 更新充电桩状态为已预约
    await db.update(ports)
      .set({ portStatus: 1, reserveTime: new Date(body.startTime), updatedAt: new Date() })
      .where(eq(ports.id, body.portId))
  }

  async cancelReservation(userId: string, reserveId: string): Promise<void> {
    const [reservation] = await db
      .select()
      .from(reservations)
      .where(and(
        eq(reservations.id, reserveId),
        eq(reservations.userId, userId),
        eq(reservations.status, 0)
      ))
      .limit(1)

    if (!reservation) throw new Error('预约不存在或已取消')

    await db.update(reservations)
      .set({ status: 2, updatedAt: new Date() })
      .where(eq(reservations.id, reserveId))

    // 恢复充电桩状态
    await db.update(ports)
      .set({ portStatus: 0, reserveTime: null, updatedAt: new Date() })
      .where(eq(ports.id, reservation.portId))
  }

  async getReserveDetail(userId: string, id: string): Promise<ReserveDetailItem | null> {
    const [reservation] = await db
      .select()
      .from(reservations)
      .where(and(eq(reservations.id, id), eq(reservations.userId, userId)))
      .limit(1)

    if (!reservation) return null

    // 查询桩口状态
    const [port] = await db
      .select({ portStatus: ports.portStatus })
      .from(ports)
      .where(eq(ports.id, reservation.portId))
      .limit(1)

    return {
      reserveId: reservation.id,
      stationId: reservation.stationId,
      portId: reservation.portId,
      stationName: reservation.stationName,
      portName: reservation.portName,
      startTime: reservation.startTime.toISOString(),
      endTime: reservation.endTime.toISOString(),
      createdTime: reservation.createdAt.toISOString(),
      portStatus: port?.portStatus || 0,
      defferTime: reservation.deferTime,
    }
  }

  async getStationNameList(body: StationNameListBody) {
    const { offset, limit } = getPagination(body)

    const conditions = [eq(stations.delFlag, 1)]
    if (body.stationName) {
      conditions.push(like(stations.stationName, `%${body.stationName}%`))
    }

    const rows = await db
      .select({ stationId: stations.id, stationName: stations.stationName })
      .from(stations)
      .where(and(...conditions))
      .limit(limit)
      .offset(offset)

    return { list: rows as StationNameItem[] }
  }

  async getPortNameList(body: PortNameListBody): Promise<PortNameItem[]> {
    const rows = await db
      .select({ portId: ports.id, portName: ports.portName })
      .from(ports)
      .where(eq(ports.stationId, body.stationId))

    return rows
  }
}

export const reserveService = new ReserveService()
