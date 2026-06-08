import { preferences } from '@kit.ArkData'

const TAG = 'LocalPreferences'

/**
 * 本地偏好设置工具类
 * 提供对应用本地偏好设置的增删改查操作
 */
export class LocalPreferences {
  private static __preferences: preferences.Preferences | null = null

  /**
   * 初始化偏好设置实例
   * @param context - 应用上下文
   * @param option - 偏好设置配置选项
   */
  static init(context: Context, option: preferences.Options) {
    if (!LocalPreferences.__preferences) {
      LocalPreferences.__preferences = preferences.getPreferencesSync(context, option)
    }
  }

  /**
   * 存储偏好设置数据
   * @param key - 数据的键名
   * @param value - 要存储的值，支持字符串、数字、布尔值等类型
   */
  static put(key: string, value: preferences.ValueType) {
    if (!LocalPreferences.__preferences) {
      console.error(`${TAG} please init preferences`)
      return
    }
    LocalPreferences.__preferences.putSync(key, value)
  }

  /**
   * 获取偏好设置数据
   * @param key - 要查询的键名
   * @returns 返回对应的值，如果不存在则返回空字符串
   */
  static get(key: string) {
    if (!LocalPreferences.__preferences) {
      console.error(`${TAG} please init preferences`)
      return
    }
    return LocalPreferences.__preferences.getSync(key, '')
  }

  /**
   * 删除指定的偏好设置数据
   * @param key - 要删除的键名
   */
  static delete(key: string) {
    if (!LocalPreferences.__preferences) {
      console.error(`${TAG} please init preferences`)
      return
    }
    LocalPreferences.__preferences.delete(key)
  }

  /**
   * 将内存中的偏好设置数据持久化到磁盘
   * 异步操作，确保数据已保存完成
   */
  static async flush() {
    if (!LocalPreferences.__preferences) {
      console.error(`${TAG} please init preferences`)
      return
    }
    await LocalPreferences.__preferences.flush()
  }
}