import http from '@ohos.net.http';
import { useToastHook } from '../service';
import router from '@ohos.router'
import { LocalPreferences } from '../service/LocalPreferences';
import { rcp } from '@kit.RemoteCommunicationKit'
import { LoginResult } from '../model/interface/api/LoginApiInterface'

const TAG = 'httpRequest'

export interface ResultVO<T> {
  status: number
  msg: string
  data: T,
  code: string,
}

interface RequestParams<K> {
  url: string
  method?: http.RequestMethod
  extraData?: K
}

function buildUrl<K>(url: string, baseUrl: string, params?: K): string {
  const fullUrl = baseUrl + url;
  if (!params) {
    return fullUrl;
  }
  const query = Object.keys(params)
    .map(key => `${encodeURIComponent(key)}=${encodeURIComponent((JSON.parse(JSON.stringify(params))[key]).toString())}`)
    .join('&');
  return fullUrl + (fullUrl.includes('?') ? '&' : '?') + query;
}

export const request = async<T, K>(params: RequestParams<K>): Promise<T> => {
  console.log(TAG, 'params.extraData start')
  const requestConfig: rcp.Configuration = {
    security: {
      remoteValidation: 'skip'
    }
  }
  const rpcSession = rcp.createSession({ requestConfiguration: requestConfig })

  const serverIp = LocalPreferences.get('serverIp') as string || '192.168.1.121'
  const baseUrl: string = `http://${serverIp}:3000`
  let url = baseUrl + params.url;

  if (params.method === http.RequestMethod.GET) {
    if (params.extraData) {
      url = buildUrl<K>(params.url, baseUrl, params.extraData)
    }
  }

  let headers: rcp.RequestHeaders = {
    'Content-Type': 'application/json',
  }
  // JWT 认证：使用 Authorization: Bearer 代替 Cookie + CSRF Token
  const accessToken = LocalPreferences.get('accessToken') as string
  if (accessToken) {
    headers['Authorization'] = `Bearer ${accessToken}`
  }

  let method = params.method || http.RequestMethod.GET
  let rcpReq = new rcp.Request(url, method, headers, (params.extraData as rcp.RawDataContent))

  console.log(TAG, 'params.extraData', JSON.stringify(params.extraData))

  return new Promise(async (resolve, reject) => {

    rpcSession.fetch(rcpReq).then((data) => {
      console.log(TAG, url, '接口 data-- headers', JSON.stringify(data.headers))
      console.log(TAG, url, '接口 data-- request', JSON.stringify(data.request))
      console.log(TAG, url, '接口 data-- body', JSON.stringify(data.body))
      console.log(TAG, url, '接口 data--', data.toString())


      if (url.indexOf('downloadFile') !== -1) {
        resolve(data.body as T)
      }

      const res = data.toJSON() as ResultVO<T>;
      if (res) {
        if (url.indexOf('app/login') !== -1 || url.indexOf('app/register') !== -1) {
          // 登录/注册响应：提取 JWT tokens
          if (res.code === 'EDU00000') {
            const loginData: LoginResult = res.data as LoginResult
            LocalPreferences.put('accessToken', loginData.accessToken)
            LocalPreferences.put('refreshToken', loginData.refreshToken)
            LocalPreferences.flush()
            if (url.indexOf('app/login') !== -1) {
              useToastHook('登录成功', '32lpx')
            }
            resolve(res.data)
          } else {
            reject(res)
          }
        } else {
          if (res && res.code === 'EDU00000') {
            resolve(res.data)
          } else if (res && (res.code === 'EDU99999' || res.code === 'EDU30021')) {
            // 会话过期：清理 JWT tokens 和用户信息
            LocalPreferences.delete('accessToken')
            LocalPreferences.delete('refreshToken')
            LocalPreferences.delete('account')
            LocalPreferences.delete('accountPassword')
            LocalPreferences.delete('accountImage')
            LocalPreferences.delete('accountNumber')
            LocalPreferences.delete('accountImageUrl')
            LocalPreferences.flush()
            useToastHook(res.msg, '32lpx')
            // 登录失效
            router.pushUrl({
              url: 'pages/login/index'
            })
            reject(res)
          } else if (res && res.code === 'EDU53025') {
            reject(res)
          } else {
            if (res) {
              useToastHook(res.msg, '32lpx')
            } else {
              useToastHook('服务异常', '32lpx')
            }
            reject(res)
          }
        }
      }
      console.log(TAG, url, '接口 data-- 结束')
      rpcSession.close();
    }).catch((err: Error) => {
      console.error(TAG, url, '网络请求失败', JSON.stringify(err))
      useToastHook('网络请求失败', '32lpx')
      reject(err)
      rpcSession.close();
    })

  })
}
