import { router } from '@kit.ArkUI'
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { useToastHook } from '../service';
import { enterDetail } from '../api/HomeApi';
import { EnterDetailItem } from '../model/interface/api/HomeApiInterface';
import { resStr } from '../utils/i18n'

const TAG = 'HuaweiKitDemo'

@Component
export struct BottomNav {
  @Prop currentIndex: number
  @Link activeName: string;
  onEvent: Function = (data: string, index: number) => {
  };

  // 查询用户进站信息
  enterDetail(result: scanBarcode.ScanResult) {
    enterDetail<EnterDetailItem>({ stationId: '1' }).then((res) => {
      console.info('接口 进站信息', JSON.stringify(res))
      if (res) {
        if (result.originalValue.indexOf('@&%') !== -1 && result.originalValue.split('@&%')[1] === res.portName) {
          router.pushUrl({
            url: 'pages/charging/inCharging',
            params: res
          })
        } else {
          useToastHook(resStr(getContext(this), 'nav_scan_error'), '40lpx')
        }
      } else {
        useToastHook(resStr(getContext(this), 'nav_not_entered'), '40lpx')
      }
    })
  }

  build() {
    Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
      Column() {
        Image(this.activeName === '首页' ? $r('app.media.home_homeActive') : $r('app.media.home_home'))
          .width('20lpx')
          .height('20lpx')
          .margin({ top: '10lpx', bottom: '4lpx' })
        Text($r('app.string.nav_home'))
          .fontSize('10lpx')
          .fontColor(this.activeName === '首页' ? $r('app.color.bottom_nav_fontcolor_active') :
          $r('app.color.bottom_nav_fontcolor'))
      }
      .width('33%')
      .onClick(() => {
        this.activeName = '首页'
        this.onEvent('首页', 0)
      })

      Column() {
        Image(this.activeName === '扫一扫' ? $r('app.media.scanActive') : $r('app.media.scan'))
          .width('32lpx')
          .height('32lpx')
          .margin({ top: '0lpx', bottom: '4lpx' })
        Text($r('app.string.nav_scan'))
          .fontSize('10lpx')
          .fontColor(this.activeName === '扫一扫' ? $r('app.color.bottom_nav_fontcolor_active') :
          $r('app.color.bottom_nav_fontcolor'))

      }
      .width('33%')
      .onClick(() => {
        this.activeName = '扫一扫'
        // 定义扫码参数options
        let options: scanBarcode.ScanOptions = {
          scanTypes: [scanCore.ScanType.ALL],
          enableMultiMode: true,
          enableAlbum: true
        };
        try {
          // 可调用getContext接口获取当前页面关联的UIAbilityContext
          scanBarcode.startScanForResult(getContext(this), options).then((result: scanBarcode.ScanResult) => {
            // 解析码值结果跳转应用服务页
            this.enterDetail(result)

            console.log(TAG, '[Scan CPSample]',
              `Succeeded in getting ScanResult by promise with options, result is ${JSON.stringify(result)}`);
          }).catch((error: BusinessError) => {
            this.activeName = this.currentIndex === 1 ? '我的' : '首页'
            console.error(TAG, '[Scan CPSample]',
              `Failed to get ScanResult by promise with options. Code:${error.code}, message: ${error.message}`);
          });
        } catch (error) {
          console.error(TAG, '[Scan CPSample]',
            `Failed to start the scanning service. Code:${error.code}, message: ${error.message}`);
        }
      })

      Column() {
        Image(this.activeName === '我的' ? $r('app.media.home_userActive') : $r('app.media.home_user'))
          .width('20lpx')
          .height('20lpx')
          .margin({ top: '10lpx', bottom: '4lpx' })
        Text($r('app.string.nav_mine'))
          .fontSize('10lpx')
          .fontColor(this.activeName === '我的' ? $r('app.color.bottom_nav_fontcolor_active') :
          $r('app.color.bottom_nav_fontcolor'))
      }
      .width('33%')
      .onClick(() => {
        this.activeName = '我的'
        this.onEvent('我的', 1)
      })
    }
    .width('100%')
    .height('69.5lpx')
    .padding({ left: '16lpx', right: '16lpx' })
    // .backgroundColor("#ffffff")
    .backgroundImage($r('app.media.home_bottom_bgTabs'))
    .backgroundImageSize({ width: '100%', height: '100%' })

  }
}