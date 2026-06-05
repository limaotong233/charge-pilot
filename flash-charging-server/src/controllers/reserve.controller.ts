import { Response, NextFunction } from 'express'
import { reserveService } from '../services/reserve.service'
import { success } from '../utils/response'
import { AuthRequest, BindBody, UnbindBody, ReserveAddBody, ReserveCancelBody, StationNameListBody, PortNameListBody } from '../types'

export async function getBindDetail(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { id } = req.body as UnbindBody
    const result = await reserveService.getBindDetail(userId, id)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function bind(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const body = req.body as BindBody
    await reserveService.bind(userId, body)
    res.json(success(null))
  } catch (err) {
    next(err)
  }
}

export async function unbind(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { id } = req.body as UnbindBody
    await reserveService.unbind(userId, id)
    res.json(success(null))
  } catch (err) {
    next(err)
  }
}

export async function addReservation(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const body = req.body as ReserveAddBody
    await reserveService.addReservation(userId, body)
    res.json(success(null))
  } catch (err) {
    next(err)
  }
}

export async function cancelReservation(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { reserveId } = req.body as ReserveCancelBody
    await reserveService.cancelReservation(userId, reserveId)
    res.json(success(null))
  } catch (err) {
    next(err)
  }
}

export async function getReserveDetail(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { id } = req.body as UnbindBody
    const result = await reserveService.getReserveDetail(userId, id)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function getStationNameList(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const body = req.body as StationNameListBody
    const result = await reserveService.getStationNameList(body)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function getPortNameList(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const body = req.body as PortNameListBody
    const result = await reserveService.getPortNameList(body)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}
