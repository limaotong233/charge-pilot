import http from '@ohos.net.http';
import { VoucherAddVO, VoucherListVO } from '../model/interface/api/CardCouponsApiInterface';
import { request } from '../utils/Http'

// 获取卡券列表
export const getVoucherList = <T>(extraData: VoucherListVO) => {
  return request<T, VoucherListVO>({
    url: '/chargelab/app/voucher/list',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 获取我的卡券 未使用数量
export const getVoucherCount = <T>(extraData: VoucherAddVO) => {
  return request<T, VoucherAddVO>({
    url: '/chargelab/app/voucher/count',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 领取卡券
export const getVoucherAdd = <T>(extraData: VoucherAddVO) => {
  return request<T, VoucherAddVO>({
    url: '/chargelab/app/voucher/add',
    method: http.RequestMethod.POST,
    extraData
  })
}