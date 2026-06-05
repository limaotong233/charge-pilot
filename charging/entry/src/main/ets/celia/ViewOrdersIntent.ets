import { insightIntent, InsightIntentEntry, InsightIntentEntryExecutor } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const LOG_TAG = 'CeliaViewOrders'

@InsightIntentEntry({
  intentName: 'ViewOrders',
  domain: 'TransportationDomain',
  intentVersion: '1.0.0',
  displayName: '查看充电订单',
  displayDescription: '查看充电订单记录',
  icon: $r('app.media.logo'),
  llmDescription: '帮助用户查看充电订单记录，包括进行中、待支付、已完成的订单',
  keywords: ['查看订单', '充电记录', '我的订单', '订单列表', '充电历史', '消费记录'],
  abilityName: 'EntryAbility',
  executeMode: [insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND],
  parameters: {
    'schema': 'http://json-schema.org/draft-07/schema#',
    'type': 'object',
    'title': 'ViewOrdersParams',
    'description': '查看订单参数',
    'properties': {
      'status': {
        'type': 'string',
        'description': '订单状态筛选：all=全部, pending=待支付, completed=已完成',
        'enum': ['all', 'pending', 'completed']
      }
    }
  }
})
export default class ViewOrdersIntent extends InsightIntentEntryExecutor<string> {
  status: string = 'all'

  onExecute(): Promise<insightIntent.IntentResult<string>> {
    hilog.info(0x0000, LOG_TAG, '执行查看订单意图, status: %{public}s', this.status)
    if (this.executeMode === insightIntent.ExecuteMode.UI_ABILITY_FOREGROUND) {
      this.windowStage?.loadContent('pages/order/orderList')
    }
    return Promise.resolve({ code: 0, result: '已打开订单列表' })
  }
}
