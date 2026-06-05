import http from '@ohos.net.http';
import { OrderCreateVO, OrderListVO, OrderPayVO } from '../model/interface/api/OrderApiInterface';
import { request } from '../utils/Http'

// 获取卡券列表 支付订单
export const getOrderPay = <T>(extraData: OrderPayVO) => {
  return request<T, OrderPayVO>({
    url: '/chargelab/app/order/pay',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 创建订单
export const getOrderCreate = <T>(extraData: OrderCreateVO) => {
  return request<T, OrderCreateVO>({
    url: '/chargelab/app/order/create',
    method: http.RequestMethod.POST,
    extraData
  })
}

//充电结束 计算金额
export const getOrderAmount = <T>(extraData: OrderPayVO) => {
  return request<T, OrderPayVO>({
    url: '/chargelab/app/order/amount',
    method: http.RequestMethod.POST,
    extraData
  })
}

//订单列表
export const getOrderList = <T>(extraData: OrderListVO) => {
  return request<T, OrderListVO>({
    url: '/chargelab/app/order/list',
    method: http.RequestMethod.POST,
    extraData
  })
}

//订单详情
export const getOrderDetail = <T>(extraData: OrderPayVO) => {
  return request<T, OrderPayVO>({
    url: '/chargelab/app/order/detail',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 加速充电模拟
export const getOrderSpeedUp = <T>(extraData: OrderPayVO) => {
  return request<T, OrderPayVO>({
    url: '/chargelab/app/order/speedUp',
    method: http.RequestMethod.POST,
    extraData
  })
}
