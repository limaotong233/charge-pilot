import { Response, NextFunction } from 'express'
import { orderService } from '../services/order.service'
import { success } from '../utils/response'
import { AuthRequest, OrderCreateBody, OrderPayBody, OrderListBody } from '../types'

export async function createOrder(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const userName = req.user!.account
    const body = req.body as OrderCreateBody
    const result = await orderService.createOrder(userId, userName, body)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function getOrderDetail(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { orderId } = req.body as OrderPayBody
    const result = await orderService.getOrderDetail(userId, orderId)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function getOrderAmount(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { orderId } = req.body as OrderPayBody
    const result = await orderService.calculateAmount(userId, orderId)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function payOrder(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { orderId } = req.body as OrderPayBody
    await orderService.payOrder(userId, orderId)
    res.json(success(null))
  } catch (err) {
    next(err)
  }
}

export async function getOrderList(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const body = req.body as OrderListBody
    const result = await orderService.getOrderList(userId, body)
    res.json(success(result))
  } catch (err) {
    next(err)
  }
}

export async function speedUpSimulation(req: AuthRequest, res: Response, next: NextFunction) {
  try {
    const userId = req.user!.userId
    const { orderId } = req.body as OrderPayBody
    await orderService.speedUpSimulation(userId, orderId)
    res.json(success(null))
  } catch (err) {
    next(err)
  }
}
