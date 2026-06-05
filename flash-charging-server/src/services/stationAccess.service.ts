import { db } from '../config/database'
import { stationAccessRecords, stations } from '../models/schema'
import { eq, and } from 'drizzle-orm'
import { EnterDetailItem } from '../types'

export class StationAccessService {
  async addRecord(userId: string, stationId: string): Promise<void> {
    const [station] = await db
      .select()
      .from(stations)
      .where(eq(stations.id, stationId))
      .limit(1)

    if (!station) throw new Error('充电站不存在')

    await db.insert(stationAccessRecords).values({
      userId,
      stationId,
      stationName: station.stationName,
      chargeFee: station.chargeFee,
      chargePower: station.chargePower,
      chargeType: station.chargeType,
      latitude: station.latitude,
      longitude: station.longitude,
      status: 0,
    })
  }

  async leaveRecord(userId: string, recordId: string): Promise<void> {
    const [record] = await db
      .select()
      .from(stationAccessRecords)
      .where(and(
        eq(stationAccessRecords.id, recordId),
        eq(stationAccessRecords.userId, userId),
        eq(stationAccessRecords.status, 0)
      ))
      .limit(1)

    if (!record) throw new Error('进站记录不存在')

    await db.update(stationAccessRecords)
      .set({ status: 1, leaveTime: new Date() })
      .where(eq(stationAccessRecords.id, recordId))
  }

  async getActiveRecord(userId: string, stationId: string): Promise<EnterDetailItem | null> {
    // 前端使用 stationId='1' 作为探针查询（检查是否有任意活跃进站记录）
    // 当 stationId 不是合法 UUID 时，只按 userId + status 查询
    const isValidUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(stationId)

    const conditions = [
      eq(stationAccessRecords.userId, userId),
      eq(stationAccessRecords.status, 0),
    ]
    if (isValidUuid) {
      conditions.push(eq(stationAccessRecords.stationId, stationId))
    }

    const [record] = await db
      .select()
      .from(stationAccessRecords)
      .where(and(...conditions))
      .limit(1)

    if (!record) return null

    return {
      id: record.id,
      portId: record.portId || '',
      portName: record.portName || '',
      stationId: record.stationId,
      stationName: record.stationName || '',
      chargeFee: Number(record.chargeFee) || 0,
      chargePower: Number(record.chargePower) || 0,
      chargeType: record.chargeType || 0,
      enterTime: record.enterTime,
      latitude: Number(record.latitude) || 0,
      longitude: Number(record.longitude) || 0,
    }
  }
}

export const stationAccessService = new StationAccessService()
