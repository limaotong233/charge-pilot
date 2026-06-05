import { Response, NextFunction } from 'express'
import { collectService } from '../services/collect.service'
import { success } from '../utils/response'
import { AuthRequest, CollectionListBody, AddCollectBody } from '../types'

export async function getCollectList(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const body = req.body as CollectionListBody
    const result = await collectService.getCollectList(userId, body)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function addCollect(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { stationId } = req.body as AddCollectBody
    await collectService.addCollect(userId, stationId)
    res.json(success(null))
  } catch (err) {
    next(err)
  }
}

export async function cancelCollect(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { stationId } = req.body as AddCollectBody
    await collectService.cancelCollect(userId, stationId)
    res.json(success(null))
  } catch (err) {
    next(err)
  }
}
