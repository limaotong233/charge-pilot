import { Response, NextFunction } from 'express'
import { voucherService } from '../services/voucher.service'
import { success } from '../utils/response'
import { AuthRequest, VoucherListBody, VoucherAddBody } from '../types'

export async function getVoucherList(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const body = req.body as VoucherListBody
    const result = await voucherService.getVoucherList(userId, body)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function getVoucherCount(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const count = await voucherService.getVoucherCount(userId)
    res.json(success({ data: count }))
  } catch (err) {
    next(err)
  }
}

export async function addVoucher(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { voucherId } = req.body as VoucherAddBody
    await voucherService.addVoucher(userId, voucherId)
    res.json(success(null))
  } catch (err) {
    next(err)
  }
}
