import { Response, NextFunction } from 'express'
import { adminService } from '../services/admin.service'
import { success, fail } from '../utils/response'
import { AuthRequest } from '../types'

export async function getDashboard(_req: AuthRequest, res: Response, next: NextFunction) {
  try { res.json(success(await adminService.getDashboard())) } catch (err) { next(err) }
}

function qs(req: AuthRequest, key: string, def: string = ''): string {
  const v = req.query[key]
  return Array.isArray(v) ? (v[0] as string || def) : (v as string || def)
}

export async function getUsers(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    res.json(success(await adminService.getUsers(Number(qs(req,'page','1')), Number(qs(req,'size','20')), qs(req,'keyword'))))
  } catch (err) { next(err) }
}

export async function updateUser(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    await adminService.updateUser(req.params.id as string as string, req.body)
    res.json(success(null))
  } catch (err) { next(err) }
}

export async function createUser(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const { account, userName, password, role } = req.body as { account: string; userName: string; password: string; role: string }
    if (!account || !password) {
      res.json(fail('账号和密码不能为空'))
      return
    }
    const id = await adminService.createUser({ account, userName, password, role: role || 'user' })
    res.json(success({ id }))
  } catch (err) { next(err) }
}

export async function getStations(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    res.json(success(await adminService.getStations(Number(qs(req,'page','1')), Number(qs(req,'size','20')), qs(req,'keyword'))))
  } catch (err) { next(err) }
}

export async function createStation(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const id = await adminService.createStation(req.body)
    res.json(success({ id }))
  } catch (err) { next(err) }
}

export async function updateStation(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    await adminService.updateStation(req.params.id as string as string, req.body)
    res.json(success(null))
  } catch (err) { next(err) }
}

export async function deleteStation(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    await adminService.deleteStation(req.params.id as string as string)
    res.json(success(null))
  } catch (err) { next(err) }
}

export async function getPorts(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    res.json(success(await adminService.getPorts(req.params.stationId as string as string)))
  } catch (err) { next(err) }
}

export async function createPort(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    await adminService.createPort(req.body)
    res.json(success(null))
  } catch (err) { next(err) }
}

export async function updatePort(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    await adminService.updatePort(req.params.id as string, req.body)
    res.json(success(null))
  } catch (err) { next(err) }
}

export async function deletePort(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    await adminService.deletePort(req.params.id as string)
    res.json(success(null))
  } catch (err) { next(err) }
}

export async function getOrders(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    res.json(success(await adminService.getOrders(Number(qs(req,'page','1')), Number(qs(req,'size','20')), qs(req,'status'))))
  } catch (err) { next(err) }
}

export async function getReservations(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    res.json(success(await adminService.getReservations(Number(qs(req,'page','1')), Number(qs(req,'size','20')))))
  } catch (err) { next(err) }
}

export async function cancelReservation(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    await adminService.cancelReservation(req.params.id as string)
    res.json(success(null))
  } catch (err) { next(err) }
}

export async function getVouchers(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    res.json(success(await adminService.getVouchers(Number(qs(req,'page','1')), Number(qs(req,'size','20')))))
  } catch (err) { next(err) }
}

export async function createVoucher(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    await adminService.createVoucher(req.body)
    res.json(success(null))
  } catch (err) { next(err) }
}

export async function updateVoucher(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    await adminService.updateVoucher(req.params.id as string, req.body)
    res.json(success(null))
  } catch (err) { next(err) }
}

export async function deleteVoucher(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    await adminService.deleteVoucher(req.params.id as string)
    res.json(success(null))
  } catch (err) { next(err) }
}

export async function getCollections(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    res.json(success(await adminService.getCollections(Number(qs(req,'page','1')), Number(qs(req,'size','20')))))
  } catch (err) { next(err) }
}
