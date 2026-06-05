import promptAction from '@ohos.promptAction';

// 获取全局 deviceId
export const useGetDeviceId = (): string => {
  return AppStorage.get('deviceId') || ''
}

export const useToastHook = (message: string, bottom: string) => {
  promptAction.showToast({
    message: message || '',
    duration: 2000,
    bottom: bottom || ''
  })
}
