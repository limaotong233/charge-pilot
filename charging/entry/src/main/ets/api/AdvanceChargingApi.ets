import http from '@ohos.net.http';
import {
  BindVO,
  PortNameListVO,
  ReserveAddVO,
  ReserveCancelVO,
  StationNameListVO,
  UnbindVO
} from '../model/interface/api/AdvanceChargingApiInterface';
import { request } from '../utils/Http'

// 查询绑定的充电桩
export const getReserveBindDetail = <T>(extraData: UnbindVO) => {
  return request<T, UnbindVO>({
    url: '/chargelab/app/reserve/bindDetail',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 绑定充电桩
export const getReserveBind = <T>(extraData: BindVO) => {
  return request<T, BindVO>({
    url: '/chargelab/app/reserve/bind',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 解除绑定
export const getReserveUnbind = <T>(extraData: UnbindVO) => {
  return request<T, UnbindVO>({
    url: '/chargelab/app/reserve/unbind',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 预约充电桩
export const getReserveAdd = <T>(extraData: ReserveAddVO) => {
  return request<T, ReserveAddVO>({
    url: '/chargelab/app/reserve/add',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 取消预约
export const getReserveCancel = <T>(extraData: ReserveCancelVO) => {
  return request<T, ReserveCancelVO>({
    url: '/chargelab/app/reserve/cancel',
    method: http.RequestMethod.POST,
    extraData
  })
}

//用户预约信息
export const getReserveDetail = <T>(extraData: UnbindVO) => {
  return request<T, UnbindVO>({
    url: '/chargelab/app/reserve/detail',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 绑定时 选择充电站名称列表
export const getReserveStationNameList = <T>(extraData: StationNameListVO) => {
  return request<T, StationNameListVO>({
    url: '/chargelab/app/reserve/stationNameList',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 绑定时选择 充电桩名称列表
export const getReservePortNameList = <T>(extraData: PortNameListVO) => {
  return request<T, PortNameListVO>({
    url: '/chargelab/app/reserve/portNameList',
    method: http.RequestMethod.POST,
    extraData
  })
}