import { Response, NextFunction } from 'express'
import { analyticsService } from '../services/analytics.service'
import { success } from '../utils/response'
import { AuthRequest } from '../types'

export async function getOverview(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const result = await analyticsService.getOverview(userId)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}
