import http from '@ohos.net.http';
import { RegisterFormItem } from '../model/interface/registerInterface';
import { request } from '../utils/Http'

export const register = <T>(extraData: RegisterFormItem) => {
  return request<T, RegisterFormItem>({
    url: '/userauth/api/app/register',
    method: http.RequestMethod.POST,
    extraData
  })
}
