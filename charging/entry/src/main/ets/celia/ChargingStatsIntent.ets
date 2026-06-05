import { insightIntent, InsightIntentEntry, InsightIntentEntryExecutor } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const LOG_TAG = 'CeliaChargingStats'

@InsightIntentEntry({
  intentName: 'ChargingStats',
  domain: 'TransportationDomain',
  intentVersion: '1.0.0',
  displayName: '充电统计',
  displayDescription: '查看充电数据分析和统计',
  icon: $r('app.media.logo'),
  llmDescription: '帮助用户查看充电数据统计，包括总充电量、消费金额、充电次数、碳减排量、常去充电站等数据分析',
  keywords: ['充电统计', '充电数据', '充了多少电', '充电分析', '消费统计', '碳减排'],
  abilityName: 'EntryAbility',
  executeMode: [insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND],
  parameters: {
    'schema': 'http://json-schema.org/draft-07/schema#',
    'type': 'object',
    'title': 'ChargingStatsParams',
    'description': '充电统计参数',
    'properties': {}
  }
})
export default class ChargingStatsIntent extends InsightIntentEntryExecutor<string> {
  onExecute(): Promise<insightIntent.IntentResult<string>> {
    hilog.info(0x0000, LOG_TAG, '执行充电统计意图')
    if (this.executeMode === insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND) {
      this.windowStage?.loadContent('pages/analytics/index')
    }
    return Promise.resolve({ code: 0, result: '已打开充电统计' })
  }
}
