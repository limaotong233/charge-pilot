import { insightIntent, InsightIntentEntry, InsightIntentEntryExecutor } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const LOG_TAG = 'CeliaNavigateStation'

@InsightIntentEntry({
  intentName: 'NavigateStation',
  domain: 'TransportationDomain',
  intentVersion: '1.0.0',
  displayName: '导航去充电站',
  displayDescription: '打开地图规划前往充电站的路线',
  icon: $r('app.media.logo'),
  llmDescription: '帮助用户导航前往充电站，打开地图页面并规划路线，支持指定充电站名称',
  keywords: ['导航去充电站', '规划路线', '去充电站', '导航充电', '路线规划', '开车去充电'],
  abilityName: 'EntryAbility',
  executeMode: [insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND]
})
export default class NavigateStationIntent extends InsightIntentEntryExecutor<string> {
  stationName: string = ''

  onExecute(): Promise<insightIntent.IntentResult<string>> {
    hilog.info(0x0000, LOG_TAG, '执行导航意图, stationName: %{public}s', this.stationName)
    if (this.executeMode === insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND) {
      // 打开路线规划页面
      this.windowStage?.loadContent('pages/routePlanning/index')
    }
    const result: insightIntent.IntentResult<string> = { code: 0, result: '已打开路线规划' }
    return Promise.resolve(result)
  }
}
