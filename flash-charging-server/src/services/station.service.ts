import { db } from '../config/database'
import { stations, ports, collections } from '../models/schema'
import { eq, and, like, sql, desc, inArray } from 'drizzle-orm'
import { getPagination, PaginatedResult } from '../utils/pagination'
import {
  StationListBody, StationListItem, StationDetailItem,
  StationPortItem, CollectionListBody, CollectionListItem,
} from '../types'

export class StationService {
  async getStationList(
    userId: string, body: StationListBody
  ): Promise<PaginatedResult<StationListItem>> {
    const { offset, limit } = getPagination(body)

    const conditions = [eq(stations.delFlag, 1)]
    if (body.stationName) {
      conditions.push(like(stations.stationName, `%${body.stationName}%`))
    }
    if (body.chargeType !== null && body.chargeType !== undefined) {
      conditions.push(eq(stations.chargeType, body.chargeType))
    }

    const whereClause = and(...conditions)

    const [countResult] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(stations)
      .where(whereClause)

    const rows = await db
      .select({
        stationId: stations.id,
        stationName: stations.stationName,
        latitude: stations.latitude,
        longitude: stations.longitude,
        chargeType: stations.chargeType,
        portCount: stations.portCount,
        chargeFee: stations.chargeFee,
        chargePower: stations.chargePower,
        usedCount: stations.usedCount,
        fileCode: stations.fileCode,
        delFlag: stations.delFlag,
      })
      .from(stations)
      .where(whereClause)
      .orderBy(desc(stations.usedCount))
      .limit(limit)
      .offset(offset)

    // 查询用户收藏状态
    const stationIds = rows.map(r => r.stationId)
    const collectedSet = new Set<string>()
    if (stationIds.length > 0) {
      const collected = await db
        .select({ stationId: collections.stationId })
        .from(collections)
        .where(and(
          eq(collections.userId, userId),
          inArray(collections.stationId, stationIds)
        ))
      collected.forEach(c => collectedSet.add(c.stationId))
    }

    const list: StationListItem[] = rows.map(r => ({
      stationId: r.stationId,
      stationName: r.stationName,
      latitude: Number(r.latitude),
      longitude: Number(r.longitude),
      chargeType: r.chargeType,
      portCount: r.portCount,
      chargeFee: Number(r.chargeFee),
      chargePower: Number(r.chargePower),
      usedCount: r.usedCount,
      isCollect: collectedSet.has(r.stationId) ? 1 : 0,
      distance: 0,
      fileCode: r.fileCode || '',
      delFlag: r.delFlag,
    }))

    return { total: countResult.count, list }
  }

  async getStationDetail(userId: string, stationId: string): Promise<StationDetailItem | null> {
    const [station] = await db
      .select()
      .from(stations)
      .where(and(eq(stations.id, stationId), eq(stations.delFlag, 1)))
      .limit(1)

    if (!station) return null

    const [collected] = await db
      .select({ id: collections.id })
      .from(collections)
      .where(and(eq(collections.userId, userId), eq(collections.stationId, stationId)))
      .limit(1)

    return {
      stationId: station.id,
      stationName: station.stationName,
      stationType: station.stationType,
      latitude: Number(station.latitude),
      longitude: Number(station.longitude),
      chargeType: station.chargeType,
      portCount: station.portCount,
      chargeFee: Number(station.chargeFee),
      chargePower: Number(station.chargePower),
      usedCount: station.usedCount,
      serviceProvider: station.serviceProvider || '',
      openTime: station.openTime || '',
      invoiceType: station.invoiceType || '',
      paymentMethod: station.paymentMethod || '',
      isCollect: collected ? 1 : 0,
      distance: 0,
      fileCode: station.fileCode || '',
    }
  }

  async getStationPortList(stationId: string): Promise<StationPortItem[]> {
    const rows = await db
      .select()
      .from(ports)
      .where(eq(ports.stationId, stationId))

    const [station] = await db
      .select({ stationName: stations.stationName })
      .from(stations)
      .where(eq(stations.id, stationId))
      .limit(1)

    return rows.map(p => ({
      portId: p.id,
      portName: p.portName,
      stationId: p.stationId,
      stationName: station?.stationName || '',
      chargeFee: Number(p.chargeFee),
      chargePower: Number(p.chargePower),
      serviceProvider: p.serviceProvider || '',
      openTime: p.openTime || '',
      invoiceType: p.invoiceType || '',
      paymentMethod: p.paymentMethod || '',
      reserveTime: p.reserveTime?.toISOString() || null,
      portStatus: p.portStatus,
    }))
  }
}

export const stationService = new StationService()
