import { router } from '@kit.ArkUI'
import { StationListItemReturning, StationPortListReturning } from '../model/interface/api/HomeApiInterface'
import { getStationPortList } from '../api/HomeApi'
import { LongBtnComponent } from './longBtnComponent'
import { resStr } from '../utils/i18n'

@Component
export struct StationDashboard {
  @Prop siteItem: StationListItemReturning = {} as StationListItemReturning
  @State portList: StationPortListReturning[] = []
  @State selectedPort: StationPortListReturning | null = null
  @State loading: boolean = true

  aboutToAppear() {
    this.loadPorts()
  }

  async loadPorts() {
    this.loading = true
    try {
      const res = await getStationPortList<StationPortListReturning[]>({ stationId: this.siteItem.stationId })
      if (res) {
        this.portList = res
      }
    } catch (e) {
      console.error('加载桩口列表失败', JSON.stringify(e))
    } finally {
      this.loading = false
    }
  }

  // 桩口状态文本
  private getStatusText(status: number): string {
    if (status === 0) return resStr(getContext(this), 'common_status_free')
    if (status === 1) return resStr(getContext(this), 'common_status_reserved')
    return resStr(getContext(this), 'common_status_charging')
  }

  // 桩口状态颜色
  private getStatusColor(status: number): string {
    if (status === 0) return '#4CAF50'
    if (status === 1) return '#FF9800'
    return '#F44336'
  }

  build() {
    Column() {
      // 顶部：站点名称
      Row() {
        Column() {
          Text(this.siteItem.stationName)
            .fontSize('16lpx')
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row() {
            Text(this.siteItem.chargeType === 1 ? $r('app.string.common_label_fast_charge') : $r('app.string.common_label_slow_charge'))
              .fontSize('11lpx')
              .fontColor('#FFFFFF')
              .backgroundColor(this.siteItem.chargeType === 1 ? '#4CAF50' : '#FF9800')
              .borderRadius('4lpx')
              .padding({ left: '6lpx', right: '6lpx', top: '2lpx', bottom: '2lpx' })
            Text(`¥${this.siteItem.chargeFee}` + resStr(getContext(this), 'common_price_per_kwh'))
              .fontSize('11lpx')
              .fontColor('#999999')
              .margin({ left: '6lpx' })
          }
          .margin({ top: '4lpx' })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      // 根据是否已选择桩口显示不同内容
      if (this.selectedPort === null) {
        // ====== 阶段1：选择充电桩 ======
        Text($r('app.string.dashboard_label_select_port'))
          .fontSize('14lpx')
          .fontColor('#666666')
          .margin({ top: '12lpx' })

        if (this.loading) {
          Column() {
            LoadingProgress().width('32lpx').height('32lpx')
          }
          .width('100%')
          .padding({ top: '24lpx', bottom: '24lpx' })
        } else {
          // 桩口列表
          Column() {
            ForEach(this.portList, (port: StationPortListReturning) => {
              Row() {
                // 桩口名称
                Column() {
                  Text(port.portName)
                    .fontSize('15lpx')
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                  Text(`${port.chargePower}` + resStr(getContext(this), 'dashboard_label_power') + ` · ¥${port.chargeFee}` + resStr(getContext(this), 'dashboard_label_price'))
                    .fontSize('12lpx')
                    .fontColor('#999999')
                    .margin({ top: '2lpx' })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                // 状态标签
                Text(this.getStatusText(port.portStatus))
                  .fontSize('12lpx')
                  .fontColor(this.getStatusColor(port.portStatus))
                  .padding({ left: '8lpx', right: '8lpx', top: '4lpx', bottom: '4lpx' })
                  .borderRadius('12lpx')
                  .backgroundColor(port.portStatus === 0 ? 'rgba(76, 175, 80, 0.1)' : 'rgba(153, 153, 153, 0.1)')
              }
              .width('100%')
              .padding({ top: '12lpx', bottom: '12lpx' })
              .onClick(() => {
                if (port.portStatus === 0) {
                  this.selectedPort = port
                }
              })
            }, (port: StationPortListReturning) => port.portId)
          }
          .width('100%')
          .margin({ top: '8lpx' })

          // 分隔线
          Row() {
            Divider().layoutWeight(1).color('#EEEEEE')
            Text($r('app.string.dashboard_label_or')).fontSize('12lpx').fontColor('#999999').margin({ left: '8lpx', right: '8lpx' })
            Divider().layoutWeight(1).color('#EEEEEE')
          }
          .width('100%')
          .margin({ top: '12lpx' })

          // 扫码选择按钮
          Row() {
            Text($r('app.string.dashboard_btn_scan_port'))
              .fontSize('14lpx')
              .fontColor('#2196F3')
              .padding({ left: '24lpx', right: '24lpx', top: '10lpx', bottom: '10lpx' })
              .borderRadius('20lpx')
              .border({ width: '1lpx', color: '#2196F3' })
              .backgroundColor('rgba(33, 150, 243, 0.06)')
          }
          .justifyContent(FlexAlign.Center)
          .margin({ top: '12lpx' })
        }
      } else {
        // ====== 阶段2：已选桩口 → 充电仪表盘 ======
        // 选中的桩口信息
        Row() {
          Text(this.selectedPort.portName)
            .fontSize('14lpx')
            .fontColor('#2196F3')
            .fontWeight(FontWeight.Medium)
          Text(' · ')
            .fontSize('14lpx')
            .fontColor('#CCCCCC')
          Text(`${this.selectedPort.chargePower}kW`)
            .fontSize('14lpx')
            .fontColor('#666666')
          // 切换桩口
          Text($r('app.string.dashboard_label_switch'))
            .fontSize('12lpx')
            .fontColor('#2196F3')
            .margin({ left: 'auto' })
            .onClick(() => {
              this.selectedPort = null
            })
        }
        .width('100%')
        .margin({ top: '12lpx' })

        // 仪表盘数据（3列）
        Row() {
          Column() {
            Text(`${this.selectedPort.chargePower}`)
              .fontSize('22lpx')
              .fontWeight(FontWeight.Bold)
              .fontColor('#2196F3')
            Text(`${this.selectedPort.chargePower}` + resStr(getContext(this), 'dashboard_label_power'))
              .fontSize('11lpx')
              .fontColor('#999999')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Divider().vertical(true).height('36lpx').color('#EEEEEE')

          Column() {
            Text(`¥${this.selectedPort.chargeFee}`)
              .fontSize('22lpx')
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
            Text($r('app.string.dashboard_label_price'))
              .fontSize('11lpx')
              .fontColor('#999999')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Divider().vertical(true).height('36lpx').color('#EEEEEE')

          Column() {
            Text($r('app.string.dashboard_label_ready'))
              .fontSize('22lpx')
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
            Text($r('app.string.dashboard_label_charge_status'))
              .fontSize('11lpx')
              .fontColor('#999999')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ top: '12lpx', bottom: '12lpx' })
        .margin({ top: '8lpx' })
        .borderRadius('8lpx')
        .backgroundColor('#F8F8F8')

        // 启动充电按钮
        LongBtnComponent({
          btnColor: $r('app.color.longBtn_blue'),
          btnFontColor: $r('app.color.background_color_over'),
          btnBorderColor: $r('app.color.longBtn_blue'),
          btnName: resStr(getContext(this), 'dashboard_btn_start_charge'),
          onEvent: () => {
            router.pushUrl({
              url: 'pages/charging/inCharging',
              params: {
                stationId: this.siteItem.stationId,
                stationName: this.siteItem.stationName,
                portId: this.selectedPort!.portId,
                portName: this.selectedPort!.portName
              }
            })
          }
        })
      }
    }
    .width('100%')
    .padding({ left: '16lpx', right: '16lpx', top: '12lpx', bottom: '12lpx' })
    .backgroundColor('#FFFFFF')
    .borderRadius('16lpx 16lpx 0 0')
    .shadow({
      radius: 12,
      color: 'rgba(0,0,0,0.08)',
      offsetY: -2
    })
  }
}
