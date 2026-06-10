import { HeadComponent } from '../../components/headComponent'
import { LongBtnComponent } from '../../components/longBtnComponent'
import { routePlanningCarInfoItem, routePlanningParamsInfo } from '../../model/interface/routePlanningInterface'
import { promptAction, router } from '@kit.ArkUI'
import { LocalPreferences } from '../../service/LocalPreferences'
import { useToastHook } from '../../service'
import { bundleManager, abilityAccessCtrl, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { map, mapCommon } from '@kit.MapKit'
import { geoLocationManager } from '@kit.LocationKit'
import { resStr } from '../../utils/i18n'

@Entry
@Component
export struct RoutePlanning {
  private TAG = 'HuaweiMapDemo';
  private mapController?: map.MapComponentController;
  @State startDestination: string = AppStorage.get('startSpot') || ''
  @State destination: string = AppStorage.get('endSpot') || ''
  @State isSwitch: boolean | undefined = AppStorage.get('switch') || undefined
  @State carInfo: routePlanningCarInfoItem = {
    mileageNumber: 500,
    capacity: 60,
    startSOCValue: LocalPreferences.get('startSOCValue') as number || 60,
    endSOCValue: LocalPreferences.get('endSOCValue') as number || 50
  }
  @State params: routePlanningParamsInfo = router.getParams() as routePlanningParamsInfo
  @State handlePopup: boolean = false

  // 校验应用是否被授予定位权限，可以通过调用checkAccessToken()方法来校验当前是否已经授权。
  async checkPermissions(): Promise<boolean> {
    const permissions: Array<Permissions> = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'];
    for (let permission of permissions) {
      let grantStatus: abilityAccessCtrl.GrantStatus = await this.checkAccessToken(permission);
      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        this.setMap();
        console.info(this.TAG, `checkPermissions success`);
        return true;
      }
    }
    return false;
  }

  // 如果没有被授予定位权限，动态向用户申请授权
  requestPermissions(): void {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(getContext() as common.UIAbilityContext,
      ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'])
      .then((data: PermissionRequestResult) => {
        this.setMap();

        console.info(this.TAG, `requestPermissions success`);
      })
      .catch((err: BusinessError) => {
        console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
      })
  }

  async setMap() {
    // 启用我的位置图层
    this.mapController?.show();
    this.mapController?.setMyLocationEnabled(true);
    // 启用我的位置按钮
    this.mapController?.setMyLocationControlsEnabled(true);

    let location = await geoLocationManager.getCurrentLocation();
    // 获取我的位置经纬度
    let startTarget: mapCommon.LatLng = {
      latitude: location.latitude,
      longitude: location.longitude
    };
    LocalPreferences.put('continueStartTarget', startTarget)
    LocalPreferences.flush()
    AppStorage.setOrCreate('continueStartTarget', startTarget)

    let reverseGeoCodeRequest: geoLocationManager.ReverseGeoCodeRequest =
      { 'latitude': location.latitude, 'longitude': location.longitude, maxItems: 1 }
    try {
      geoLocationManager.getAddressesFromLocation(reverseGeoCodeRequest, (err, data) => {
        if (err) {

        } else {
          console.info('接口 地理位置信息', JSON.stringify(data))
        }
      })
    } catch (err) {

    }

    console.info(this.TAG, `setMap myLocationButtonClick location ${JSON.stringify(location)}`);
  }

  async checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

    // 获取应用程序的accessTokenID
    let tokenId: number = 0;
    let bundleInfo: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    console.info(this.TAG, `Succeeded in getting Bundle.`);
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    tokenId = appInfo.accessTokenId;

    // 校验应用是否被授予权限
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
    console.info(this.TAG, `Succeeded in checking access token.`);
    return grantStatus;
  }

  async aboutToAppear() {
    if (!this.startDestination) {
      this.startDestination = resStr(getContext(this), 'route_start_location')
    }
    if (!this.destination) {
      this.destination = resStr(getContext(this), 'route_placeholder_destination')
    }
    let location = await geoLocationManager.getCurrentLocation();
    // 获取我的位置经纬度
    let startTarget: mapCommon.LatLng = {
      latitude: location.latitude,
      longitude: location.longitude
    };
    AppStorage.setOrCreate('continueStartTarget', startTarget)
  }

  // 页面每次显示时触发一次，包括路由过程、应用进入前台等场景，仅@Entry装饰的自定义组件生效
  onPageShow(): void {
    // 将地图切换到前台
    if (this.mapController) {
      this.checkPermissions().then(result => {
        if (!result) {
          this.requestPermissions()
        }
      })

    }
  }

  build() {
    Stack() {
      Column() {
        HeadComponent({
          headName: resStr(getContext(this), 'route_head_name'),
          isHaveBtn: false,
          backUrl: 'pages/Index',
          tabs: 1,
          receive: () => {
          }
        })
        Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
          Column() {
            Row() {
              Image($r('app.media.routePlanning_start'))
                .width('35lpx')
                .height('40lpx')
                .padding({ top: '8lpx' })
              if (this.isSwitch) {
                Row() {
                  Text(this.startDestination)
                    .margin({ left: '4lpx', right: '8lpx' })
                  Image($r('app.media.userAccount_RightIcon'))
                    .width('16lpx')
                    .height('16lpx')
                }
                .width('100%')
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/routePlanning/routeSearch',
                    params: {
                      startOrEnd: 'start',
                    }
                  })
                })
              } else {
                Text(this.destination)
                  .width('100%')
                  .fontColor(this.destination === resStr(getContext(this), 'route_placeholder_destination') ? $r('app.color.aeaeae') :
                  $r('app.color.historyList_font_color'))
                  .margin({ left: '4lpx', right: '8lpx' })
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/routePlanning/routeSearch',
                      params: {
                        startOrEnd: 'end',
                      }
                    })
                  })
              }
            }
            .width('100%')
            .padding({ top: '12lpx', bottom: '12lpx' })
            .borderWidth({ bottom: '1lpx' })
            .borderColor($r('app.color.EEEEEE'))

            Row() {
              Image($r('app.media.routePlanning_end'))
                .width('35lpx')
                .height('40lpx')
                .padding({ top: '8lpx' })
              if (!this.isSwitch) {
                Row() {
                  Text(this.startDestination)
                    .margin({ left: '4lpx', right: '8lpx' })
                  Image($r('app.media.userAccount_RightIcon'))
                    .width('16lpx')
                    .height('16lpx')
                }
                .width('100%')
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/routePlanning/routeSearch',
                    params: {
                      // isSwitch: this.isSwitch,
                      startOrEnd: 'start',
                    }
                  })
                })
              } else {
                Text(this.destination)
                  .width('100%')
                  .fontColor(this.destination === resStr(getContext(this), 'route_placeholder_destination') ? $r('app.color.aeaeae') :
                  $r('app.color.historyList_font_color'))
                  .margin({ left: '4lpx', right: '8lpx' })
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/routePlanning/routeSearch',
                      params: {
                        startOrEnd: 'end',
                      }
                    })
                  })
              }
            }
            .width('100%')
            .padding({ top: '12lpx', bottom: '12lpx' })
          }
          .width('98%')

          Image($r('app.media.routePlanning_switch'))
            .width('26lpx')
            .height('25lpx')
            .rotate({
              x: this.isSwitch ? 0 : 1,
              y: 0,
              z: 0,
              angle: 180
            })
            .onClick(() => {
              if (this.isSwitch) {
                this.isSwitch = false
                AppStorage.setOrCreate('switch', false)
              } else {
                this.isSwitch = true
                AppStorage.setOrCreate('switch', true)
              }
            })
        }
        .borderRadius('16lpx')
        .backgroundColor($r('app.color.background_color_over'))
        .padding({ left: '16lpx', right: '16lpx' })
        .margin({
          left: '16lpx',
          right: '16lpx',
          top: '16lpx',
          bottom: '24lpx'
        })

        Row() {
          Text($r('app.string.route_label_trip_preference'))
            .margin({ left: '16lpx' })
            .fontSize('16lpx')
        }
        .margin({ bottom: '16lpx' })
        .width('100%')

        Column() {
          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Text($r('app.string.route_label_mileage'))
              .width('120lpx')
              .fontSize('14lpx')
              .fontColor($r('app.color.charging_font_color'))
            Row() {
              Text(`${this.carInfo.mileageNumber}`)
                .fontColor($r('app.color.clear_font_color'))
                .margin({ right: '8lpx' })
              Text($r('app.string.route_label_unit_km'))
                .fontSize('12lpx')
                .fontColor($r('app.color.999999'))
            }
          }
          .padding({ top: '16lpx', bottom: '16lpx' })
          .borderWidth({ bottom: '1lpx' })
          .borderColor({ bottom: $r('app.color.EEEEEE') })

          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Text($r('app.string.route_label_start_soc'))
              .fontSize('14lpx')
              .fontColor($r('app.color.charging_font_color'))
              .width('120lpx')
            Text(`${this.carInfo.startSOCValue.toFixed(0)}%`)
              .fontSize('16lpx')
              .fontColor($r('app.color.btn_blue'))
          }
          .padding({ top: '16lpx', bottom: '6lpx' })

          Row() {
            Slider({
              value: this.carInfo.startSOCValue,
              min: 20,
              max: 100,
              step: 5,
              style: SliderStyle.OutSet
            })
              .showSteps(false)
              .selectedColor($r('app.color.longBtn_blue'))
              .onChange((value: number, mode: SliderChangeMode) => {
                // if (value < 20) return
                this.carInfo.startSOCValue = value
                LocalPreferences.put('startSOCValue', value)
                LocalPreferences.flush()

              })
          }
          .width('100%')
          .borderWidth({ bottom: '1lpx' })
          .borderColor({ bottom: $r('app.color.EEEEEE') })

          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Row() {
              Text($r('app.string.route_label_low_battery'))
                .fontSize('14lpx')
                .fontColor($r('app.color.charging_font_color'))

              // Image($r('app.media.questionMark'))
              Image(this.handlePopup ? $r('app.media.siteCollection_questionMarketActive') :
              $r('app.media.siteCollection_questionMarket'))
                .margin({ left: '8lpx' })
                .width('16lpx')
                .height('16lpx')
            }
            .width('120lpx')
            .onClick(() => {
              this.handlePopup = !this.handlePopup
            })
            .bindPopup(this.handlePopup, {
              message: resStr(getContext(this), 'route_popup_low_battery_msg'),
              onStateChange: (e) => {
                this.handlePopup = e.isVisible
              }
            })

            Text(`${this.carInfo.endSOCValue.toFixed(0)}%`)
              .fontSize('16lpx')
              .fontColor($r('app.color.btn_blue'))
          }
          .padding({ top: '16lpx', bottom: '6lpx' })

          Row() {
            Slider({
              value: this.carInfo.endSOCValue,
              min: 20,
              max: 50,
              step: 5,
              style: SliderStyle.OutSet
            })
              .showSteps(false)// .showTips(true)
              .selectedColor($r('app.color.longBtn_blue'))
              .onChange((value: number, mode: SliderChangeMode) => {
                this.carInfo.endSOCValue = value
                LocalPreferences.put('endSOCValue', value)
                LocalPreferences.flush()

              })
          }
          .width('100%')
        }
        .padding({ left: '16lpx', right: '16lpx' })
        .margin({ left: '16lpx', right: '16lpx', bottom: '40lpx' })
        .borderRadius('16lpx')
        .backgroundColor($r('app.color.background_color_over'))
      }
      .width('100%')
      .height('100%')

      LongBtnComponent({
        btnColor: this.destination === resStr(getContext(this), 'route_placeholder_destination') ? $r('app.color.longBtn_blue_opacity') :
        $r('app.color.longBtn_blue'),
        btnFontColor: $r('app.color.background_color_over'),
        btnBorderColor: this.destination === resStr(getContext(this), 'route_placeholder_destination') ? $r('app.color.longBtn_blue_opacity') :
        $r('app.color.longBtn_blue'),
        btnName: resStr(getContext(this), 'route_btn_start_planning'),
        onEvent: (data: string) => {
          if (this.destination === resStr(getContext(this), 'route_placeholder_destination')) {
            promptAction.showToast({
              message: resStr(getContext(this), 'route_toast_input_dest')
            })
            return
          }
          if (this.startDestination === this.destination) {
            useToastHook(resStr(getContext(this), 'route_toast_same_address'), '40lpx')
            return
          }
          console.info('接口 -开始规划 ', JSON.stringify(this.carInfo))
          router.pushUrl({
            url: 'pages/routePlanning/planningLineMap',
            params: {
              mileageNumber: this.carInfo.mileageNumber,
              startSOCValue: this.carInfo.startSOCValue,
              endSOCValue: this.carInfo.endSOCValue,
            }
          })
        }
      })
        .position({ bottom: '16lpx' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.card_background'))
  }
}