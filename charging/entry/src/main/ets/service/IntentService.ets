import { LocalPreferences } from './LocalPreferences'

export interface IntentResult {
  page: string
  response: string
  keyword?: string
}

interface IntentRule {
  keywords: string[]
  page: string
  response: string
  keyword?: string
  conditionPage?: string // 有条件跳转时的备选页面
  conditionResponse?: string
  conditionCheck?: () => boolean
}

class IntentService {
  private static __instance: IntentService

  static getInstance(): IntentService {
    if (!IntentService.__instance) {
      IntentService.__instance = new IntentService()
    }
    return IntentService.__instance
  }

  private rules: IntentRule[] = [
    {
      keywords: ['搜索充电站', '找充电桩', '附近充电站', '充电站', '搜索充电桩', '附近充电桩', '找充电'],
      page: 'pages/home/siteSearch',
      response: '正在为您搜索附近充电站',
      keyword: '充电站'
    },
    {
      keywords: ['开始充电', '我要充电', '启动充电', '开始充'],
      page: 'pages/home/homeSearch',
      response: '请先选择充电站和充电桩',
      conditionPage: 'pages/charging/inCharging',
      conditionResponse: '正在跳转到充电页面',
      conditionCheck: () => !!LocalPreferences.get('MyChargingOrder')
    },
    {
      keywords: ['停止充电', '结束充电', '关闭充电', '停止充', '结束充', '不充了'],
      page: 'pages/charging/inCharging',
      response: '已跳转到充电页面，请点击结束充电'
    },
    {
      keywords: ['查看订单', '充电记录', '我的订单', '订单列表', '充电历史', '消费记录'],
      page: 'pages/order/orderList',
      response: '正在为您打开订单列表'
    },
    {
      keywords: ['导航去充电站', '规划路线', '去充电站', '导航充电', '路线规划', '开车去充电'],
      page: 'pages/routePlanning/index',
      response: '正在为您打开路线规划'
    },
    {
      keywords: ['充电统计', '充电数据', '充了多少电', '充电分析', '消费统计', '碳减排'],
      page: 'pages/analytics/index',
      response: '正在为您打开充电统计'
    }
  ]

  matchIntent(text: string): IntentResult | null {
    if (!text || text.length === 0) return null

    for (let i = 0; i < this.rules.length; i++) {
      const rule = this.rules[i]
      for (let j = 0; j < rule.keywords.length; j++) {
        if (text.includes(rule.keywords[j])) {
          // 检查是否有条件跳转
          if (rule.conditionCheck && rule.conditionCheck()) {
            return {
              page: rule.conditionPage!,
              response: rule.conditionResponse!,
              keyword: rule.keyword
            }
          }
          return {
            page: rule.page,
            response: rule.response,
            keyword: rule.keyword
          }
        }
      }
    }

    return null
  }
}

export const intentService = IntentService.getInstance()
