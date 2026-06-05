import http from '@ohos.net.http';
import { request } from '../utils/Http'
import { AddCollectVO, CollectionListVO, downLoadFileVO } from '../model/interface/api/CollectionApiInterface'

// 获取收藏列表列表
export const getCollectList = <T>(extraData: CollectionListVO) => {
  return request<T, CollectionListVO>({
    url: '/chargelab/app/collect/list',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 添加收藏
export const addCollectList = <T>(extraData: AddCollectVO) => {
  return request<T, AddCollectVO>({
    url: '/chargelab/app/collect/add',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 取消收藏
export const cancelCollectList = <T>(extraData: AddCollectVO) => {
  return request<T, AddCollectVO>({
    url: '/chargelab/app/collect/cancel',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 获取图片
export const downLoadFile = <T>(extraData: downLoadFileVO) => {
  return request<T, downLoadFileVO>({
    url: '/chargelab/app/file/downloadFile',
    method: http.RequestMethod.GET,
    extraData
  })
}
