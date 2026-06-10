import { resourceManager } from '@kit.LocalizationKit'

// 获取资源字符串值（用于需要 string 类型的场景，如变量赋值、字符串拼接）
// 用法：resStr(this, 'login_btn_submit')
export function resStr(ctx: Context, key: string): string {
  try {
    return ctx.resourceManager.getStringByNameSync(key)
  } catch (e) {
    return key
  }
}
