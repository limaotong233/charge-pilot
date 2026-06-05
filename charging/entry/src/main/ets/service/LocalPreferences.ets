import { preferences } from '@kit.ArkData'

const TAG = 'LocalPreferences'

export class LocalPreferences {
  private static __preferences: preferences.Preferences | null = null

  static init(context: Context, option: preferences.Options) {
    if (!LocalPreferences.__preferences) {
      LocalPreferences.__preferences = preferences.getPreferencesSync(context, option)
    }
  }

  static put(key: string, value: preferences.ValueType) {
    if (!LocalPreferences.__preferences) {
      console.error(`${TAG} please init preferences`)
      return
    }
    LocalPreferences.__preferences.putSync(key, value)
  }

  static get(key: string) {
    if (!LocalPreferences.__preferences) {
      console.error(`${TAG} please init preferences`)
      return
    }
    return LocalPreferences.__preferences.getSync(key, '')
  }

  static delete(key: string) {
    if (!LocalPreferences.__preferences) {
      console.error(`${TAG} please init preferences`)
      return
    }
    LocalPreferences.__preferences.delete(key)
  }

  static async flush() {
    if (!LocalPreferences.__preferences) {
      console.error(`${TAG} please init preferences`)
      return
    }
    await LocalPreferences.__preferences.flush()
  }
}