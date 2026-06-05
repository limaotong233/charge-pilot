import { db } from '../config/database'
import { collections, stations } from '../models/schema'
import { eq, and, like, sql } from 'drizzle-orm'
import { getPagination, PaginatedResult } from '../utils/pagination'
import { CollectionListBody, CollectionListItem } from '../types'

export class CollectService {
  async getCollectList(
    userId: string, body: CollectionListBody
  ): Promise<PaginatedResult<CollectionListItem>> {
    const { offset, limit } = getPagination(body)

    const conditions = [
      eq(collections.userId, userId),
      eq(stations.delFlag, 1),
    ]
    if (body.stationName) {
      conditions.push(like(stations.stationName, `%${body.stationName}%`))
    }

    const whereClause = and(...conditions)

    const [countResult] = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(collections)
      .innerJoin(stations, eq(collections.stationId, stations.id))
      .where(whereClause)

    const rows = await db
      .select({
        id: collections.id,
        stationId: stations.id,
        stationName: stations.stationName,
        stationType: stations.stationType,
        chargeType: stations.chargeType,
        latitude: stations.latitude,
        longitude: stations.longitude,
        chargeFee: stations.chargeFee,
        portCount: stations.portCount,
        chargePower: stations.chargePower,
        usedCount: stations.usedCount,
        fileCode: stations.fileCode,
        delFlag: stations.delFlag,
      })
      .from(collections)
      .innerJoin(stations, eq(collections.stationId, stations.id))
      .where(whereClause)
      .limit(limit)
      .offset(offset)

    const list: CollectionListItem[] = rows.map(r => ({
      id: r.id,
      stationId: r.stationId,
      stationName: r.stationName,
      stationType: r.stationType,
      chargeType: r.chargeType,
      latitude: Number(r.latitude),
      longitude: Number(r.longitude),
      chargeFee: Number(r.chargeFee),
      portCount: r.portCount,
      chargePower: Number(r.chargePower),
      usedCount: r.usedCount,
      distance: 0,
      isCollect: 1,
      delFlag: r.delFlag,
      fileCode: r.fileCode || '',
    }))

    return { total: countResult.count, list }
  }

  async addCollect(userId: string, stationId: string): Promise<void> {
    const [existing] = await db
      .select({ id: collections.id })
      .from(collections)
      .where(and(eq(collections.userId, userId), eq(collections.stationId, stationId)))
      .limit(1)

    if (existing) return // 已收藏，静默返回

    await db.insert(collections).values({ userId, stationId })
  }

  async cancelCollect(userId: string, stationId: string): Promise<void> {
    await db.delete(collections)
      .where(and(eq(collections.userId, userId), eq(collections.stationId, stationId)))
  }
}

export const collectService = new CollectService()
