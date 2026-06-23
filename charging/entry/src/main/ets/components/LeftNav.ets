import { router } from '@kit.ArkUI'
import { scanBarcode, scanCore } from '@kit.ScanKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { useToastHook } from '../service'
import { enterDetail } from '../api/HomeApi'
import { EnterDetailItem } from '../model/interface/api/HomeApiInterface'
import { resStr } from '../utils/i18n'

@Component
export struct LeftNav {
  @Prop activeName: string
  @Prop currentIndex: number
  onEvent: Function = (data: string, index: number) => {}

  // 扫码进入充电
  enterDetail(result: scanBarcode.ScanResult) {
    enterDetail<EnterDetailItem>({ stationId: '1' }).then((res) => {
      if (res) {
        if (result.originalValue.indexOf('@&%') !== -1 && result.originalValue.split('@&%')[1] === res.portName) {
          router.pushUrl({ url: 'pages/charging/inCharging', params: res })
        } else {
          useToastHook(resStr(getContext(this), 'nav_scan_error'), '40lpx')
        }
      } else {
        useToastHook(resStr(getContext(this), 'nav_not_entered'), '40lpx')
      }
    })
  }

  build() {
    Column() {
      // Logo
      Text('⚡')
        .fontSize('28lpx')
        .margin({ top: '32lpx', bottom: '40lpx' })

      // 首页
      Column() {
        Image(this.activeName === '首页' ? $r('app.media.home_homeActive') : $r('app.media.home_home'))
          .width('28lpx')
          .height('28lpx')
          .margin({ bottom: '4lpx' })
        Text('首页')
          .fontSize('11lpx')
          .fontColor(this.activeName === '首页' ? $r('app.color.bottom_nav_fontcolor_active') :
          $r('app.color.bottom_nav_fontcolor'))
      }
      .padding({ top: '8lpx', bottom: '8lpx' })
      .onClick(() => {
        this.onEvent('首页', 0)
      })

      // 扫一扫
      Column() {
        Image(this.activeName === '扫一扫' ? $r('app.media.scanActive') : $r('app.media.scan'))
          .width('28lpx')
          .height('28lpx')
          .margin({ bottom: '4lpx' })
        Text('扫一扫')
          .fontSize('11lpx')
          .fontColor(this.activeName === '扫一扫' ? $r('app.color.bottom_nav_fontcolor_active') :
          $r('app.color.bottom_nav_fontcolor'))
      }
      .padding({ top: '8lpx', bottom: '8lpx' })
      .onClick(() => {
        this.onEvent('扫一扫', -1)
        let options: scanBarcode.ScanOptions = {
          scanTypes: [scanCore.ScanType.ALL],
          enableMultiMode: true,
          enableAlbum: true
        }
        try {
          scanBarcode.startScanForResult(getContext(this), options).then((result: scanBarcode.ScanResult) => {
            this.enterDetail(result)
          }).catch(() => {})
        } catch (e) {}
      })

      // 我的
      Column() {
        Image(this.activeName === '我的' ? $r('app.media.home_userActive') : $r('app.media.home_user'))
          .width('28lpx')
          .height('28lpx')
          .margin({ bottom: '4lpx' })
        Text('我的')
          .fontSize('11lpx')
          .fontColor(this.activeName === '我的' ? $r('app.color.bottom_nav_fontcolor_active') :
          $r('app.color.bottom_nav_fontcolor'))
      }
      .padding({ top: '8lpx', bottom: '8lpx' })
      .onClick(() => {
        this.onEvent('我的', 1)
      })
    }
    .width('108lpx')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: '24lpx' })
    .backgroundColor('#ffffff')
  }
}