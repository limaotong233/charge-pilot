import http from '@ohos.net.http';
import { formItem } from '../model/interface/loginInterface';
import { formItem2, userInfoImage } from '../model/interface/api/LoginApiInterface';
import { request } from '../utils/Http'

export const login = <T>(extraData: formItem) => {
  return request<T, formItem>({
    url: '/userauth/api/app/login',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 获取用户头像用户名
export const getUserInfo = <T>(extraData: formItem2) => {
  return request<T, formItem2>({
    url: '/userauth/user/selectUser',
    method: http.RequestMethod.POST,
    extraData
  })
}

// 获取图片
export const getUserInfoImage = <T>(extraData: userInfoImage) => {
  return request<T, userInfoImage>({
    url: '/userauth/api/file/downloadFile',
    method: http.RequestMethod.GET,
    extraData
  })
}
