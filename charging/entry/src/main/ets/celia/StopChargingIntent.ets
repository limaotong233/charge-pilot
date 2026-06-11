import { insightIntent, InsightIntentEntry, InsightIntentEntryExecutor } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { LocalPreferences } from '../service/LocalPreferences'

const LOG_TAG = 'CeliaStopCharging'

@InsightIntentEntry({
  intentName: 'StopCharging',
  domain: 'TransportationDomain',
  intentVersion: '1.0.0',
  displayName: '停止充电',
  displayDescription: '结束当前充电并结算',
  icon: $r('app.media.logo'),
  llmDescription: '帮助用户停止当前正在进行的充电，结束充电并跳转到支付页面',
  keywords: ['停止充电', '结束充电', '关闭充电', '停止充', '结束充', '不充了'],
  abilityName: 'EntryAbility',
  executeMode: [insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND]
})
export default class StopChargingIntent extends InsightIntentEntryExecutor<string> {
  onExecute(): Promise<insightIntent.IntentResult<string>> {
    hilog.info(0x0000, LOG_TAG, '执行停止充电意图')

    // 检查是否有进行中的充电
    const chargingOrder = LocalPreferences.get('MyChargingOrder')
    if (!chargingOrder) {
      const failResult: insightIntent.IntentResult<string> = { code: 1, result: '当前没有正在进行的充电' }
      return Promise.resolve(failResult)
    }

    // 跳转到充电页面（页面内有结束充电按钮）
    if (this.executeMode === insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND) {
      this.windowStage?.loadContent('pages/charging/inCharging')
    }
    const result: insightIntent.IntentResult<string> = { code: 0, result: '已跳转到充电页面，请点击结束充电' }
    return Promise.resolve(result)
  }
}
