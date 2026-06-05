/* 格式化日期及unix时间戳的转换工具包 */
import { intl } from "@kit.LocalizationKit";

export const customDataFormat = function (time: Date): string {
  let customDataFormat = new intl.DateTimeFormat('zh-CN', {
    dateStyle: 'medium',
    timeStyle: 'medium',
    hourCycle: 'h24'
  })
  return customDataFormat.format(time)
}

export const customDataFormat2 = function (time: Date): string {
  let customDataFormat = new intl.DateTimeFormat('zh-CN', {
    dateStyle: 'short',
    timeStyle: 'medium',
    hourCycle: 'h24'
  })
  return customDataFormat.format(time)
}

export function formatDate(timeStamp: Date): string {
  const date = new Date(timeStamp);

  // 获取年月日 时分秒
  const year = date.getFullYear();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  const hours = date.getHours().toString().padStart(2, '0');
  const minutes = date.getMinutes().toString().padStart(2, '0')
  const seconds = date.getSeconds().toString().padStart(2, '0')

  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
}