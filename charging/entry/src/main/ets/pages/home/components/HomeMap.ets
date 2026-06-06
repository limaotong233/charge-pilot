import { mapCommon, MapComponent, map, navi } from '@kit.MapKit';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl,
  AbilityConstant,
  bundleManager, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import fs from '@ohos.file.fs'
import { promptAction, router } from '@kit.ArkUI';
import { enterAdd, enterDetail, enterLeave, getStationDetail, getStationList } from '../../../api/HomeApi';
import {
  StationListVO,
  StationListReturning,
  StationListItemReturning,
  EnterDetailItem
} from '../../../model/interface/api/HomeApiInterface'
import { JSON } from '@kit.ArkTS';
import { DataBaseService } from '../../../service/DataBaseService';
import { getDistance } from '../../../utils/tools';
import { LocalPreferences } from '../../../service/LocalPreferences';
import { useToastHook } from '../../../service';
import { StationDashboard } from '../../../components/StationDashboard';

let dataBase = DataBaseService.getInstance()


// @Entry
@Component
export struct HomeMap {
  private context = getContext(this) as common.UIAbilityContext
  private TAG = 'HuaweiMapDemo';
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;
  private marker?: map.Marker;
  private file?: fs.File;
  private points?: mapCommon.LatLng[];
  private startTarget?: mapCommon.LatLng =
    LocalPreferences.get('continueStartTarget') as mapCommon.LatLng || AppStorage.get('continueStartTarget') ||
      undefined
  private endTarget?: mapCommon.LatLng = AppStorage.get('continueEndTarget') || undefined
  @State params: StationListItemReturning = AppStorage.get('routerParamsSiteInfo') as StationListItemReturning//router.getParams() as StationListItemReturning
  @Link @Watch('onCarStatus') carStatus: string
  @Link @Watch('onChangeCurrentIndex') currentIndex: number
  @Link isShowSheet: boolean
  @State mapBtnIsEnterSpot: string = AppStorage.get('continueMapBtnIsEnterSpot') || '进入仿真充电站'
  @State siteLoading: boolean = false
  @State siteList: StationListItemReturning[] = []
  @State currentPage: number = 1
  @Link @Watch('onChangeChargeType') chargeType: string
  @Link siteItem: StationListItemReturning
  @Link distance: number
  @Link areaValue: string

  // 加载地图
  async onChangeChargeType() {
    this.clearMap()
    this.mapOptions = {
      position: {
        target: {
          latitude: this.endTarget ? this.endTarget?.latitude as number :
            this.startTarget?.latitude as number, //30.1787526,
          longitude: this.endTarget ? this.endTarget?.longitude as number :
            this.startTarget?.longitude as number//120.160369
        },
        zoom: 14
      },
      myLocationControlsEnabled: true,
      scaleControlsEnabled: true
    };

    // 地图初始化的回调
    this.callback = async (err, mapController) => {
      if (!err) {
        // 获取地图的控制器类，用来操作地图
        this.mapController = mapController;
        this.mapEventManager = this.mapController.getEventManager();
        let callback = () => {
          console.info(this.TAG, `on-mapLoad`);
        }
        // 地图打点
        console.info('接口 siteList', JSON.stringify(this.siteList))
        this.getStationListPort()

        // 监听标记点击事件
        let markerClickCallback = async (marker: map.Marker) => {
          this.onChangeCurrentIndex()

          if (this.carStatus === '已到达' || this.carStatus == '正在前往') {
            return
          }
          console.info('markerClick', marker.getTitle())
          let stationId = marker.getTitle().split('&')[4]

          this.siteList.forEach((item) => {
            if (item.stationId === stationId) {
              AppStorage.setOrCreate('siteItemInfo', item)
              this.siteItem = item
            }
          })
          if (this.carStatus === '已到达' || this.carStatus === '已离场') {
            this.carStatus = '点击前往'
            AppStorage.setOrCreate('continueCarStatus', '点击前往')
          }
          // 获取 我的位置 到 点击的站点的 距离
          let tempList = await getDistance([marker.getPosition()])
          if (tempList) {
            this.distance = Number(((tempList[0].cells[0].distance as number) / 1000)?.toFixed(2))
          }

          if (marker.isInfoWindowVisible()) {
            this.endTarget = {
              latitude: 0,
              longitude: 0
            }
            this.isShowSheet = false
            marker?.setInfoWindowVisible(false)
            AppStorage.setOrCreate('continueIsShowSheet', false)
            AppStorage.setOrCreate('siteItemInfo', null)
          } else {
            // 获取终点经纬度
            if (this.siteItem.stationId === undefined) return
            this.getCardInfo(this.siteItem.stationId)
            this.isShowSheet = true
            marker?.setInfoWindowVisible(true)
            AppStorage.setOrCreate('continueIsShowSheet', true)
          }
        }
        // 监听地图点击事件  && this.carStatus !== '正在前往'
        let mapClickCallback = () => {
          this.onChangeCurrentIndex()
          if (this.carStatus === '已离场' || this.carStatus === '点击前往') {
            this.isShowSheet = false
            this.carStatus = '点击前往'
            this.siteItem = {} as StationListItemReturning
            AppStorage.setOrCreate('siteItemInfo', undefined)
            AppStorage.setOrCreate('continueCarStatus', '点击前往')
          }
        }
        await this.mapEventManager?.on('markerClick', markerClickCallback)
        await this.mapEventManager?.on('mapClick', mapClickCallback)

        // 我的位置
        this.checkPermissions().then(result => {
          if (!result) {
            this.requestPermissions()
          }
        })
        // 跳转过来的数据
        this.isHaveParamChange();
      }
    };

  }

  //跳转过来param
  isHaveParamChange() {
    console.info('接口 params', JSON.stringify((this.params)))
    if (this.params && this.params.stationId) {

      this.isShowSheet = true

      if (this.startTarget && this.endTarget) {
        this.setSpotS(this.startTarget, $r('app.media.routePlanning_start'))
        this.setSpotS(this.endTarget, $r('app.media.routePlanning_end'))
        this.testDrivingRoutes(this.startTarget, this.endTarget, this.carStatus === '已到达' ? 0 : 10000, this.carStatus === '已到达' ? 0xff696969 : 0xff0a59f7)
      }
    }
  }

  // 更新卡片信息
  getCardInfo(stationId: string) {
    getStationDetail<StationListItemReturning>({ stationId }).then(async (res2) => {
      if (res2) {
        // 计算距离
        let tempList = await getDistance([{ latitude: res2.latitude, longitude: res2.longitude }])

        if (tempList) {
          res2.distance = Number(((tempList[0].cells[0].distance as number) / 1000)?.toFixed(2))
          this.siteItem = res2 as StationListItemReturning
          this.isShowSheet = true

          this.endTarget = {
            latitude: res2.latitude,
            longitude: res2.longitude
          }
          AppStorage.setOrCreate('continueEndTarget', this.endTarget)
          AppStorage.setOrCreate('siteItemInfo', res2)
        }
      }
    })
  }

  //点击标记点 初始化车辆到站信息 //
  async onChangeCurrentIndex() {

    // 查询当前是否已经进入站点
    let res = await enterDetail<EnterDetailItem>({ stationId: '1' })
    console.info('接口 进站信息', JSON.stringify(res))
    if (res) {
      this.carStatus = '已到达'
      this.mapBtnIsEnterSpot = '退出仿真充电站'
      if (res.stationId) {
        getStationDetail<StationListItemReturning>({ stationId: res.stationId }).then(async (res2) => {
          if (res2) {
            // 计算距离
            let tempList = await getDistance([{ latitude: res2.latitude, longitude: res2.longitude }])

            if (tempList) {
              res2.distance = Number(((tempList[0].cells[0].distance as number) / 1000)?.toFixed(2))
              this.siteItem = res2 as StationListItemReturning
              this.isShowSheet = true

              this.endTarget = {
                latitude: res2.latitude,
                longitude: res2.longitude
              }
              AppStorage.setOrCreate('continueEndTarget', this.endTarget)
              this.setSpotS(this.startTarget as mapCommon.LatLng, $r('app.media.routePlanning_start'))
              this.setSpotS(this.endTarget as mapCommon.LatLng, $r('app.media.routePlanning_end'))
              this.testDrivingRoutes(this.startTarget as mapCommon.LatLng, this.endTarget as mapCommon.LatLng, 0,
                0xff696969)
            }
          }
        })
      }
    } else {
      if (this.mapBtnIsEnterSpot === '退出仿真充电站') {
        this.initMapDate()
      }
    }
  }

  onCarStatus() {
    console.log('enterDetail onCarStatus',this.carStatus)
    let endTarget:mapCommon.LatLng | undefined = AppStorage.get('continueEndTarget')
    if (this.carStatus === '点击前往') {
      this.clearMap()
    } else if (this.carStatus === '正在前往') {
      console.log('enterDetail this.startTarget',JSON.stringify(this.startTarget))
      console.log('enterDetail endTarget',JSON.stringify(endTarget))
      if (this.startTarget && endTarget) {
        this.setSpotS(this.startTarget, $r('app.media.routePlanning_start'))
        this.setSpotS(endTarget, $r('app.media.routePlanning_end'))
        this.testDrivingRoutes(this.startTarget, endTarget, 5000, 0xff0a59f7)
      }else {
        useToastHook('站点准备中，请稍等','40lpx')
        this.carStatus = '点击前往'
      }
    } else if (this.carStatus === '已到达' || this.carStatus === '已离场') {
      if (this.startTarget && endTarget) {
        this.setSpotS(this.startTarget, $r('app.media.routePlanning_start'))
        this.setSpotS(endTarget, $r('app.media.routePlanning_end'))
        this.testDrivingRoutes(this.startTarget, endTarget, 0, 0xff696969)
      }else {
        useToastHook('站点准备中，请稍等','40lpx')
        this.carStatus = '点击前往'
      }
    }
  }

  // 获取充电站列表
  async getStationListPort() {
    let t: StationListVO = {
      currentPage: this.currentPage,
      pageSize: this.params ? 1000 : 250,
      stationName: '',
      chargeType: this.chargeType === '慢充' ? 0 : this.chargeType === '快充' ? 1 : null,
      sortBy: null,
      latitude: null,
      longitude: null
    }
    this.siteLoading = true
    let res = await getStationList<StationListReturning>(t)

    if (res) {

      this.siteLoading = false
      this.siteList = [...this.siteList, ...res.list]
      console.info('siteList 接口', JSON.stringify(res))
      console.info('siteList 接口 this.siteList length', this.siteList.length)

      if(this.currentPage === 1){
        for (let i = 0; i < this.siteList.length; i++) {
          this.setSpotList(this.siteList[i],
            this.siteList[i].chargeType === 1 ? $r('app.media.homeMap_siteIcon') : $r('app.media.slowPile'))
        }
      }

      const siteLength = this.siteList.length
      if (siteLength < res.total && siteLength <1000) {
        this.currentPage++
        this.getStationListPort()
      } else {
        if(this.currentPage !== 1){
          this.clearMap()
        }
        this.currentPage = 1
      }
    }
  }

  async aboutToAppear() {
    this.currentPage = 1
    await this.onChangeChargeType()
    // 查询当前是否已经进入站点
    await this.onChangeCurrentIndex()

    console.info('接口--map初始化', JSON.stringify(this.carStatus), JSON.stringify(this.startTarget),
      JSON.stringify(this.endTarget), JSON.stringify(this.isShowSheet), JSON.stringify(AppStorage.get('siteItemInfo')))
  }

  // 充电站 打点
  async setSpotList(siteInfo: StationListItemReturning, spotIcon: Resource) {
    let markerOptions: mapCommon.MarkerOptions = {

      position: {
        latitude: siteInfo.latitude,
        longitude: siteInfo.longitude
      },
      clickable: true,
      // infoWindowAnchorV: 1,
      visible: true,
      // 信息窗口标题
      title: `${siteInfo.chargeType === 1 ? '快充' :
        '慢充'}&${siteInfo.chargeFee}&${siteInfo.portCount}&${siteInfo.chargeType === 1 ? 'active' :
        'noActive'}&${siteInfo.stationId}`,
      icon: spotIcon
    }
    this.marker = await this.mapController?.addMarker(markerOptions)
  }

  // 起点终点 打点
  async setSpotS(siteInfo: mapCommon.LatLng, spotIcon: Resource) {
    let markerOptions: mapCommon.MarkerOptions = {
      position: {
        latitude: siteInfo.latitude,
        longitude: siteInfo.longitude
      },
      clickable: true,
      // infoWindowAnchorV: 1,
      visible: true,
      // 信息窗口标题
      icon: spotIcon
    }
    this.marker = await this.mapController?.addMarker(markerOptions)
  }

  // 进站接口
  enterAdd(id: string) {
    enterAdd<string>({ stationId: id }).then((res) => {
      console.info('接口 进站', JSON.stringify(res))
      this.mapBtnIsEnterSpot = '退出仿真充电站'
      this.carStatus = '已到达'
      AppStorage.setOrCreate('continueMapBtnIsEnterSpot', '退出仿真充电站')
      AppStorage.setOrCreate('continueCarStatus', '已到达')

      // 获取进站记录 ID，用于退出时自动调用
      enterDetail<EnterDetailItem>({ stationId: id }).then((detail) => {
        if (detail) {
          AppStorage.setOrCreate('stationAccessRecordId', detail.id)
        }
      })

      promptAction.showToast({
        message: '已到达',
        duration: 2000
      })
      this.onChangeCurrentIndex()

    }).catch((err: Error) => {
      this.isShowSheet = false
      this.carStatus = '点击前往'
      AppStorage.setOrCreate('continueCarStatus', '点击前往')
    })
  }

  // 地图数据初始化
  initMapDate() {
    this.clearMap()
    this.currentPage = 1
    this.siteList = []
    this.getStationListPort()

    this.carStatus = '点击前往'
    this.mapBtnIsEnterSpot = '进入仿真充电站'
    this.isShowSheet = false
    this.siteItem = {} as StationListItemReturning
    this.endTarget = {} as mapCommon.LatLng
    AppStorage.setOrCreate('continueCarStatus', '点击前往')
    AppStorage.setOrCreate('continueMapBtnIsEnterSpot', '进入仿真充电站')
    AppStorage.setOrCreate('endTarget', null)
    AppStorage.setOrCreate('siteItemInfo', null)
    AppStorage.setOrCreate('continueIsShowSheet', false)
    AppStorage.setOrCreate('stationAccessRecordId', '')

    AppStorage.setOrCreate('routerParamsSiteInfo', undefined)
  }

  // 出站
  enterLeave(id: string) {
    enterLeave<EnterDetailItem>({ id }).then((res) => {

      this.siteList.forEach((item) => {
        if (item.stationId === this.siteItem.stationId) {
          dataBase.put('oftenGoListItem', JSON.stringify(item))
        }
      })
      this.initMapDate()

      promptAction.showToast({
        message: '已离场',
        duration: 2000
      })
    })
  }

  // 查询用户进站信息
  enterDetail() {
    enterDetail<EnterDetailItem>({ stationId: '1' }).then((res) => {
      console.info('接口 进站信息', JSON.stringify(res))
      if (res) {
        this.enterLeave(res.id)
      } else {
        this.initMapDate()
      }
    })
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

  // 页面每次隐藏时触发一次，包括路由过程、应用进入后台等场景，仅@Entry装饰的自定义组件生效
  onPageHide(): void {
    // 将地图切换到后台
    if (this.mapController) {
      this.mapController.hide();
    }
  }

  build() {
    Stack() {
      // 调用MapComponent组件初始化地图
      if (this.mapOptions) {

        MapComponent({
          mapOptions: this.mapOptions,
          mapCallback: this.callback,
          customInfoWindow: this.customInfoWindow,
        }).width('100%').height('100%').padding({ bottom: '20lpx' })
      }
      // 进站后显示充电仪表盘
      if (this.mapBtnIsEnterSpot === '退出仿真充电站' && this.isShowSheet) {
        Column() {
          StationDashboard({
            siteItem: this.siteItem
          })
          // 退出充电站按钮（独立于仪表盘，避免点击冲突）
          Text('退出充电站')
            .fontSize('13lpx')
            .fontColor('#999999')
            .padding({ top: '4lpx', bottom: '12lpx' })
            .onClick(() => {
              this.enterDetail()
            })
        }
        .width('100%')
        .position({ bottom: 0 })
      }
      // 到达站点后显示"进入仿真充电站"按钮
      else if (this.carStatus === '已到达' && this.isShowSheet) {
        Row() {
          Text(this.mapBtnIsEnterSpot)
            .borderRadius('18lpx')
            .padding({
              left: '16lpx',
              right: '16lpx',
              top: '7lpx',
              bottom: '7lpx'
            })
            .backgroundColor($r('app.color.595959'))
            .fontSize('14lpx')
            .fontColor($r('app.color.background_color_over'))
            .onClick(() => {
              if (this.mapBtnIsEnterSpot === '进入仿真充电站') {
                let siteItemInfo: StationListItemReturning | undefined = AppStorage.get('siteItemInfo')
                if (siteItemInfo) {
                  this.enterAdd(siteItemInfo.stationId)
                }
              }
            })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
      }
    }.width('100%').height('100%')
  }

  //自定义信息窗口
  @BuilderParam customInfoWindow: ($$: map.MarkerDelegate) => void = this.customInfoWindowBuilder

  // 自定义信息窗口
  @Builder
  customInfoWindowBuilder($$: map.MarkerDelegate) {
    if ($$.marker) {
      Column() {
        Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
          Image($$.marker.getTitle().split('&')[3] === 'active' ? $r('app.media.homeMap_siteIcon') :
          $r('app.media.slowPile'))
            .width('28lpx')
            .height('28lpx')
            .margin({ right: '4lpx' })
          Column() {
            Text(`￥${$$.marker.getTitle().split('&')[1]}`)
              .width('auto')
              .alignSelf(ItemAlign.Start)
              .fontColor($r('app.color.historyList_font_color'))
              .fontSize('12lpx')
            Text(`${$$.marker.getTitle().split('&')[0]}：${$$.marker.getTitle().split('&')[2]}`)// .width('100%')
              .fontColor($r('app.color.bottom_nav_fontcolor'))
              .fontSize('10lpx')
          }
        }
        .margin('8lpx')
      }
      .width('90lpx')
      .height('54lpx')
      .backgroundImage($r('app.media.homeMap_bubbleBg2'))
      .backgroundImageSize({ width: '100%', height: '100%' })
      .onClick(() => {
        console.info('点击窗口', $$.marker?.getTitle())
      })
    }
  }

  // 动态路线轨迹
  async carSimulatedPath(startPoint: mapCommon.LatLng, pointPath: Array<mapCommon.LatLng>,
    animationDurationNumber: number) {
    // marker1的参数
    let markerOptions1: mapCommon.MarkerOptions = {
      position: startPoint,
      anchorU: 0.5,
      anchorV: 1,
      visible: true,
      icon: $r('app.media.homeMap_carIcon')
    };

    let markerBoy1 = await this.mapController?.addMarker(markerOptions1);

    // 动态轨迹的入参
    let traceOptions: mapCommon.TraceOverlayParams = {
      // 轨迹点
      points: pointPath,
      // 轨迹的动画时长
      animationDuration: animationDurationNumber,
      // 相机是否跟随动画移动
      isMapMoving: true,
      // 轨迹的颜色
      color: 0xAAFFAA00,
      // 轨迹的宽度
      width: 20,
      // 轨迹的动画回调（回调轨迹点的index）
      animationCallback: (pointIndex) => {
        console.info('pointIndex', pointIndex, pointPath.length)
        if (pointIndex === pointPath.length - 1) {
          this.carStatus = '已到达'
          AppStorage.setOrCreate('continueCarStatus', '已到达')
        }
      }
    }

    let markers: Array<map.Marker> = new Array();
    if (markerBoy1) {
      markers.push(markerBoy1);
      let traceOverlay = await this.mapController?.addTraceOverlay(traceOptions, markers);
    }
  }

  // 清空地图重新 充电站 打点
  clearMap() {
    this.mapController?.clear()
    // 地图打点
    for (let i = 0; i < this.siteList.length; i++) {
      this.setSpotList(this.siteList[i],
        this.siteList[i].chargeType === 1 ? $r('app.media.homeMap_siteIcon') : $r('app.media.slowPile'))
    }
  }

  //路线规划
  async testDrivingRoutes(startLatLon: mapCommon.LatLng, endLatLon: mapCommon.LatLng, animationNumber: number,
    lineColor: number) {
    console.log('enterDetail testDrivingRoutes')
    this.clearMap()

    let params: navi.DrivingRouteParams = {
      // 起点的经纬度 origins
      origins: [
        {
          'latitude': startLatLon.latitude,
          'longitude': startLatLon.longitude
        }
      ],
      // 终点的经纬度
      destination: {
        'latitude': endLatLon.latitude,
        'longitude': endLatLon.longitude
      },
      language: 'zh_CN'
    };
    navi.getDrivingRoutes(params).then((result) => {
      console.info(this.TAG, `enterDetail testDrivingRoutes success ${JSON.stringify(result)}`);
      let points = result.routes[0]?.overviewPolyline;
      if (points && points.length > 0) {
        this.points = points;
        this.drawLine(points, lineColor)
        if (animationNumber > 0) {
          this.carSimulatedPath(this.points[0], this.points, animationNumber);
        } else {
          // this.carStatus = '已到达'
        }
      }

    }).catch((err: BusinessError) => {
      useToastHook('地图服务端错误，请重试','40lpx')
      this.carStatus = '点击前往'
      console.log(this.TAG, `enterDetail testDrivingRoutes error ${JSON.stringify(err)}`)
    });

  }

  drawLine(points: Array<mapCommon.LatLng>, lineColor: number) {
    let polylineOption: mapCommon.MapPolylineOptions = {
      points,
      clickable: true,
      startCap: mapCommon.CapStyle.BUTT,
      endCap: mapCommon.CapStyle.BUTT,
      geodesic: false,
      jointType: mapCommon.JointType.BEVEL,
      visible: true,
      width: 10,
      zIndex: 10,
      gradient: false,
      color: lineColor
    }
    this.mapController?.addPolyline(polylineOption)
  }

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
    this.startTarget = {
      latitude: location.latitude,
      longitude: location.longitude
    };
    LocalPreferences.put('continueStartTarget', this.startTarget)
    LocalPreferences.flush()
    AppStorage.setOrCreate('continueStartTarget', this.startTarget)

    let reverseGeoCodeRequest: geoLocationManager.ReverseGeoCodeRequest =
      { 'latitude': location.latitude, 'longitude': location.longitude, maxItems: 1 }
    try {
      geoLocationManager.getAddressesFromLocation(reverseGeoCodeRequest, (err, data) => {
        if (err) {

        } else {
          AppStorage.setOrCreate('continueAreaValue', data[0].locality)
          this.areaValue = data[0].locality as string
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
}