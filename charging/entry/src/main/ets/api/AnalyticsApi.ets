import http from '@ohos.net.http';
import { request } from '../utils/Http'

export const getAnalyticsOverview = <T>() => {
  return request<T, object>({
    url: '/chargelab/app/analytics/overview',
    method: http.RequestMethod.POST,
  })
}
