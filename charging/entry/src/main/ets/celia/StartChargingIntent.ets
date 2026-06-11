import { insightIntent, InsightIntentEntry, InsightIntentEntryExecutor } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { router } from '@kit.ArkUI'
import { LocalPreferences } from '../service/LocalPreferences'

const LOG_TAG = 'CeliaStartCharging'

@InsightIntentEntry({
  intentName: 'StartCharging',
  domain: 'TransportationDomain',
  intentVersion: '1.0.0',
  displayName: '开始充电',
  displayDescription: '启动电动汽车充电',
  icon: $r('app.media.logo'),
  llmDescription: '帮助用户开始充电。如果用户已在充电站内，直接进入充电流程；否则打开地图让用户选择充电站',
  keywords: ['开始充电', '我要充电', '启动充电', '充电', '开始充'],
  abilityName: 'EntryAbility',
  executeMode: [insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND]
})
export default class StartChargingIntent extends InsightIntentEntryExecutor<string> {
  stationId: string = ''

  onExecute(): Promise<insightIntent.IntentResult<string>> {
    hilog.info(0x0000, LOG_TAG, '执行开始充电意图, stationId: %{public}s', this.stationId)

    // 检查用户是否已有进行中的订单
    const hasOrder = LocalPreferences.get('MyChargingOrder')
    if (hasOrder) {
      // 已有订单，跳转充电页
      if (this.executeMode === insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND) {
        this.windowStage?.loadContent('pages/charging/inCharging')
      }
      const result: insightIntent.IntentResult<string> = { code: 0, result: '正在跳转到充电页面' }
      return Promise.resolve(result)
    }

    // 没有进行中的订单，打开首页让用户选择充电站
    if (this.executeMode === insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND) {
      this.windowStage?.loadContent('pages/Index')
    }
    const result: insightIntent.IntentResult<string> = { code: 0, result: '请先选择充电站和充电桩' }
    return Promise.resolve(result)
  }
}
