import http from '@ohos.net.http';
import { request } from '../utils/Http'
import { EnterDetailVO, StationDetailVO, StationListVO } from '../model/interface/api/HomeApiInterface'

// 获取地图上充电站位置列表
export const getStationList = <T>(extraData: StationListVO) => {
  return request<T, StationListVO>({
    url: '/chargelab/app/station/list',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 获取充电站 详情
export const getStationDetail = <T>(extraData: StationDetailVO) => {
  return request<T, StationDetailVO>({
    url: '/chargelab/app/station/detail',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 获取充电站对应充电桩列表
export const getStationPortList = <T>(extraData: StationDetailVO) => {
  return request<T, StationDetailVO>({
    url: '/chargelab/app/station/portList',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 进站
export const enterAdd = <T>(extraData: StationDetailVO) => {
  return request<T, StationDetailVO>({
    url: '/chargelab/app/stationAccessRecord/add',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 出站
export const enterLeave = <T>(extraData: EnterDetailVO) => {
  return request<T, EnterDetailVO>({
    url: '/chargelab/app/stationAccessRecord/leave',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 查询用户进站信息
export const enterDetail = <T>(extraData: StationDetailVO) => {
  return request<T, StationDetailVO>({
    url: '/chargelab/app/stationAccessRecord/detail',
    method: http.RequestMethod.POST,
    extraData
  })
}
