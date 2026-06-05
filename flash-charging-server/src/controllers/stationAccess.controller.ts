import { Response, NextFunction } from 'express'
import { stationAccessService } from '../services/stationAccess.service'
import { success, fail } from '../utils/response'
import { AuthRequest, StationDetailBody } from '../types'

export async function addRecord(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { stationId } = req.body as StationDetailBody
    await stationAccessService.addRecord(userId, stationId)
    res.json(success(null))
  } catch (err) {
    next(err)
  }
}

export async function leaveRecord(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { id } = req.body as { id: string }
    await stationAccessService.leaveRecord(userId, id)
    res.json(success(null))
  } catch (err) {
    next(err)
  }
}

export async function getRecordDetail(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { stationId } = req.body as StationDetailBody
    const result = await stationAccessService.getActiveRecord(userId, stationId)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}
