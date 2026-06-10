import { HeadComponent } from '../../components/headComponent'
import { getAnalyticsOverview } from '../../api/AnalyticsApi'
import { AnalyticsOverview, MonthlyTrendItem, TopStationItem } from '../../model/interface/api/AnalyticsApiInterface'
import { router } from '@kit.ArkUI'
import { useToastHook } from '../../service'
import { ResultVO } from '../../utils/Http'
import { resStr } from '../../utils/i18n'

@Entry
@Component
struct Analytics {
  @State data: AnalyticsOverview = {
    totalOrders: 0,
    totalCapacity: 0,
    totalAmount: 0,
    avgCapacity: 0,
    avgAmount: 0,
    co2Reduction: 0,
    topStations: [],
    monthlyTrend: []
  }
  @State loading: boolean = true
  private context: Context = getContext(this)

  aboutToAppear() {
    this.loadData()
  }

  async loadData() {
    this.loading = true
    try {
      const res = await getAnalyticsOverview<AnalyticsOverview>()
      if (res) {
        this.data = res
      }
    } catch (e) {
      useToastHook(resStr(this.context, 'analytics_toast_load_fail'), '40lpx')
    } finally {
      this.loading = false
    }
  }

  // 格式化数字：保留2位小数
  private formatNum(val: number, decimals: number = 2): string {
    return val.toFixed(decimals)
  }

  // 计算柱状图最大高度对应的值
  private getMaxCapacity(): number {
    if (!this.data || this.data.monthlyTrend.length === 0) return 1
    let max = 0
    for (const item of this.data.monthlyTrend) {
      if (item.capacity > max) {
        max = item.capacity
      }
    }
    return max > 0 ? max : 1
  }

  build() {
    Column() {
      // 顶部导航栏
      HeadComponent({
        headName: resStr(this.context, 'analytics_head_name'),
        backUrl: 'pages/Index',
        tabs: 1
      })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width('40lpx')
            .height('40lpx')
            .margin({ top: '120lpx' })
          Text(resStr(this.context, 'common_loading'))
            .fontSize('14lpx')
            .fontColor($r('app.color.999999'))
            .margin({ top: '12lpx' })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      } else if (this.data) {
        Scroll() {
          Column() {
            // ============ 顶部数据卡片 ============
            Grid() {
              GridItem() {
                this.StatCard(resStr(this.context, 'analytics_card_total_capacity'), `${this.formatNum(this.data.totalCapacity)} kWh`, '#4CAF50')
              }
              GridItem() {
                this.StatCard(resStr(this.context, 'analytics_card_total_amount'), `¥${this.formatNum(this.data.totalAmount)}`, '#FF9800')
              }
              GridItem() {
                this.StatCard(resStr(this.context, 'analytics_card_total_orders'), `${this.data.totalOrders} ${resStr(this.context, 'analytics_unit_times')}`, '#2196F3')
              }
              GridItem() {
                this.StatCard(resStr(this.context, 'analytics_card_co2_reduction'), `${this.formatNum(this.data.co2Reduction)} ${resStr(this.context, 'analytics_unit_kg')}`, '#9C27B0')
              }
            }
            .columnsTemplate('1fr 1fr')
            .rowsTemplate('1fr 1fr')
            .columnsGap('8lpx')
            .rowsGap('8lpx')
            .height('180lpx')
            .margin({ left: '16lpx', right: '16lpx', top: '12lpx' })

            // ============ 平均数据 ============
            Row() {
              this.AvgItem(resStr(this.context, 'analytics_label_avg_capacity'), `${this.formatNum(this.data.avgCapacity)} kWh`)
              Divider().vertical(true).height('32lpx').color($r('app.color.EEEEEE')).margin({ left: '16lpx', right: '16lpx' })
              this.AvgItem(resStr(this.context, 'analytics_label_avg_amount'), `¥${this.formatNum(this.data.avgAmount)}`)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: '16lpx', bottom: '16lpx' })
            .margin({ left: '16lpx', right: '16lpx', top: '8lpx' })
            .borderRadius('12lpx')
            .backgroundColor($r('app.color.background_color_over'))

            // ============ 近6个月充电趋势（柱状图） ============
            Column() {
              Text(resStr(this.context, 'analytics_section_trend'))
                .fontSize('16lpx')
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: '12lpx' })

              if (this.data.monthlyTrend.length === 0) {
                Text(resStr(this.context, 'analytics_empty_no_records'))
                  .fontSize('14lpx')
                  .fontColor($r('app.color.999999'))
                  .margin({ top: '24lpx', bottom: '24lpx' })
              } else {
                // 柱状图
                Row() {
                  ForEach(this.data.monthlyTrend, (item: MonthlyTrendItem) => {
                    Column() {
                      // 电量柱
                      Column() {
                        Text(`${this.formatNum(item.capacity, 0)}`)
                          .fontSize('10lpx')
                          .fontColor('#4CAF50')
                          .margin({ bottom: '2lpx' })
                      }
                      .width('24lpx')
                      .height(`${Math.max(8, item.capacity / this.getMaxCapacity() * 100)}lpx`)
                      .backgroundColor('#4CAF50')
                      .borderRadius('4lpx 4lpx 0 0')
                      .justifyContent(FlexAlign.End)
                      .alignItems(HorizontalAlign.Center)

                      // 月份标签
                      Text(item.month.substring(5))
                        .fontSize('10lpx')
                        .fontColor($r('app.color.999999'))
                        .margin({ top: '4lpx' })
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Center)
                  }, (item: MonthlyTrendItem) => item.month)
                }
                .width('100%')
                .height('140lpx')
                .alignItems(VerticalAlign.Bottom)

                // 图例
                Row() {
                  Row() {
                    Rect().width('8lpx').height('8lpx').fill('#4CAF50')
                    Text(resStr(this.context, 'analytics_legend_capacity')).fontSize('10lpx').fontColor($r('app.color.999999')).margin({ left: '4lpx' })
                  }

                  Row() {
                    Rect().width('8lpx').height('8lpx').fill('#FF9800')
                    Text(resStr(this.context, 'analytics_legend_expense')).fontSize('10lpx').fontColor($r('app.color.999999')).margin({ left: '4lpx' })
                  }
                  .margin({ left: '24lpx' })
                }
                .justifyContent(FlexAlign.Center)
                .margin({ top: '8lpx' })
              }
            }
            .width('100%')
            .padding('16lpx')
            .margin({ left: '16lpx', right: '16lpx', top: '8lpx' })
            .borderRadius('12lpx')
            .backgroundColor($r('app.color.background_color_over'))

            // ============ 常去充电站 TOP5 ============
            Column() {
              Text(resStr(this.context, 'analytics_section_top_stations'))
                .fontSize('16lpx')
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: '12lpx' })

              if (this.data.topStations.length === 0) {
                Text(resStr(this.context, 'analytics_empty_no_records'))
                  .fontSize('14lpx')
                  .fontColor($r('app.color.999999'))
                  .margin({ top: '12lpx', bottom: '12lpx' })
              } else {
                ForEach(this.data.topStations, (item: TopStationItem, index: number) => {
                  Row() {
                    // 排名
                    Text(`${index + 1}`)
                      .fontSize('14lpx')
                      .fontColor(index < 3 ? '#FF9800' : $r('app.color.999999'))
                      .fontWeight(index < 3 ? FontWeight.Bold : FontWeight.Normal)
                      .width('24lpx')

                    // 站点名
                    Text(item.stationName)
                      .fontSize('14lpx')
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    // 次数
                    Text(`${item.count}${resStr(this.context, 'analytics_unit_times')}`)
                      .fontSize('13lpx')
                      .fontColor($r('app.color.999999'))
                  }
                  .width('100%')
                  .padding({ top: '10lpx', bottom: '10lpx' })
                  .borderWidth({ bottom: index === this.data.topStations.length - 1 ? 0 : '1lpx' })
                  .borderColor({ bottom: $r('app.color.EEEEEE') })
                }, (item: TopStationItem, index: number) => `${index}`)
              }
            }
            .width('100%')
            .padding('16lpx')
            .margin({ left: '16lpx', right: '16lpx', top: '8lpx', bottom: '24lpx' })
            .borderRadius('12lpx')
            .backgroundColor($r('app.color.background_color_over'))
          }
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.card_background'))
  }

  @Builder
  StatCard(label: string, value: string, color: string) {
    Column() {
      Text(value)
        .fontSize('18lpx')
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
        .margin({ bottom: '4lpx' })
      Text(label)
        .fontSize('12lpx')
        .fontColor($r('app.color.999999'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius('12lpx')
    .backgroundColor($r('app.color.background_color_over'))
  }

  @Builder
  AvgItem(label: string, value: string) {
    Column() {
      Text(value)
        .fontSize('16lpx')
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: '4lpx' })
      Text(label)
        .fontSize('12lpx')
        .fontColor($r('app.color.999999'))
    }
    .alignItems(HorizontalAlign.Center)
  }
}
