import { insightIntent, InsightIntentEntry, InsightIntentEntryExecutor } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const LOG_TAG = 'CeliaSearchStation'

@InsightIntentEntry({
  intentName: 'SearchStation',
  domain: 'TransportationDomain',
  intentVersion: '1.0.0',
  displayName: '搜索充电站',
  displayDescription: '搜索附近的电动汽车充电站',
  icon: $r('app.media.logo'),
  llmDescription: '帮助用户搜索附近的电动汽车充电站，打开地图页面展示充电站列表',
  keywords: ['搜索充电站', '找充电桩', '附近充电站', '充电站', '找充电', '搜索充电桩', '附近充电桩'],
  abilityName: 'EntryAbility',
  executeMode: [insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND]
})
export default class SearchStationIntent extends InsightIntentEntryExecutor<string> {
  keyword: string = ''

  onExecute(): Promise<insightIntent.IntentResult<string>> {
    hilog.info(0x0000, LOG_TAG, '执行搜索充电站意图, keyword: %{public}s', this.keyword)
    // 打开首页地图，系统会自动展示充电站列表
    if (this.executeMode === insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND) {
      this.windowStage?.loadContent('pages/Index')
    }
    const result: insightIntent.IntentResult<string> = { code: 0, result: '已打开充电站搜索' }
    return Promise.resolve(result)
  }
}
