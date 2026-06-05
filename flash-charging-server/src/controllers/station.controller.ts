import { Response, NextFunction } from 'express'
import { stationService } from '../services/station.service'
import { success } from '../utils/response'
import { AuthRequest, StationListBody, StationDetailBody } from '../types'

export async function getStationList(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const body = req.body as StationListBody
    const result = await stationService.getStationList(userId, body)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function getStationDetail(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { stationId } = req.body as StationDetailBody
    const result = await stationService.getStationDetail(userId, stationId)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function getStationPortList(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const { stationId } = req.body as StationDetailBody
    const result = await stationService.getStationPortList(stationId)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}
