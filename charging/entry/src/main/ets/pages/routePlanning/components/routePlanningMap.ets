import { mapCommon, MapComponent, map, navi } from '@kit.MapKit';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl, bundleManager, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import fs from '@ohos.file.fs'
import {
  StationListItemReturning,
  StationListReturning,
  StationListVO
} from '../../../model/interface/api/HomeApiInterface';
import { getStationList } from '../../../api/HomeApi';

interface NaviResult {
  routes: navi.Route,
  step: navi.RouteStep,
  distance: number | undefined,
  overviewPolyline: mapCommon.LatLng[] | undefined
}

// @Entry
@Component
export struct RoutePlanningMap {
  private TAG = 'HuaweiMapDemo';
  private mapOptions?: mapCommon.MapOptions;
  private callback?: AsyncCallback<map.MapComponentController>;
  private mapController?: map.MapComponentController;
  private mapEventManager?: map.MapEventManager;
  private marker?: map.Marker;
  private file?: fs.File;
  private points?: mapCommon.LatLng[];
  @Prop startTarget?: mapCommon.LatLng
  @Prop endTarget?: mapCommon.LatLng
  @Prop endLatLon?: mapCommon.LatLng
  @Prop mileageNumber: number
  @Prop startSOCValue: number
  @Prop endSOCValue: number
  @Link isShowSheet: boolean
  @State mapBtnIsEnterSpot: string = '进入仿真充电站'
  @Link siteList: StationListItemReturning[] //= []
  @Link planningList: StationListItemReturning[] | undefined
  @State siteResultList: StationListItemReturning[] = []

  // 获取充电站列表
  async getStationListPort() {
    let data: StationListVO = {
      currentPage: 1,
      pageSize: 1000,
      stationName: '',
      chargeType: null,
      sortBy: null,
      latitude: null,
      longitude: null
    }
    let res = await getStationList<StationListReturning>(data)

    if (res) {
      this.siteList = res.list
      console.info('接口', JSON.stringify(res))
      if (this.startTarget && this.endTarget) {
        this.setSpotS(this.startTarget, $r('app.media.routePlanning_start'))
        this.setSpotS(this.endTarget, $r('app.media.routePlanning_end'))
        this.testDrivingRoutes(this.startTarget, this.endTarget)
      }
    }
  }

  aboutToAppear() {
    console.info(this.TAG, `aboutToAppear RoutePlanningMap`);
    // 地图初始化参数，设置地图中心点坐标及层级
    this.mapOptions = {
      position: {
        target: {
          latitude: this.startTarget?.latitude as number, // 30.1787526,
          longitude: this.startTarget?.longitude as number//120.160369
        },
        zoom: 14
      },
      compassControlsEnabled:false,
      myLocationControlsEnabled: true
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
        // 地图打点 获取充电站列表

        // 起点终点路径
        if (this.startTarget && this.endTarget) {
          this.getStationListPort()
        }
      }
    };
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
      visible: true,
      icon: spotIcon
    }
    this.marker = await this.mapController?.addMarker(markerOptions)
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
      MapComponent({
        mapOptions: this.mapOptions,
        mapCallback: this.callback,
      }).width('100%').height('100%')
    }.width('100%').height('100%')
  }

  // 清空地图重新 充电站 打点
  clearMap() {
    this.mapController?.clear()
  }

  //路线规划
  async testDrivingRoutes(startLatLon: mapCommon.LatLng, endLatLon: mapCommon.LatLng) {
    this.clearMap()

    let params: navi.DrivingRouteParams = {
      // 起点的经纬度 origins
      origins: [
        {
          'latitude': startLatLon.latitude, //27.98121103,//温州
          'longitude': startLatLon.longitude//120.6846665
        }
      ],
      // 终点的经纬度
      destination: {
        'latitude': endLatLon.latitude, //31.2112517,//上海
        'longitude': endLatLon.longitude//121.296759256
      },
      // // 路径的途经点
      language: 'zh_CN'
    };
    navi.getDrivingRoutes(params).then((result) => {
      console.info(this.TAG, `testDrivingRoutes success ${JSON.stringify(result)}`);
      let navResult = this.routesResultProcess(result);
      console.info(this.TAG, `routesResultProcess step success ${JSON.stringify(navResult.step)}`);
      console.info(this.TAG, `routesResultProcess distance success ${JSON.stringify(navResult.distance)}`);
      console.info(this.TAG,
        `routesResultProcess viaWaypoints success ${JSON.stringify(navResult.overviewPolyline?.length)}`);
      console.info(this.TAG, `routesResultProcess endLatLon success ${JSON.stringify(this.endLatLon)}`);
      if (navResult.distance && navResult.overviewPolyline) {
        let result = [];
        let siteResult = this.siteValid(startLatLon, endLatLon, this.siteList)
        this.getSiteResultList(navResult.distance,
          params.destination,
          navResult.overviewPolyline,
          siteResult,
          this.startSOCValue / 100,
          this.endSOCValue / 100,
          this.mileageNumber,
          0,
          30,
          result
        ).then(result => {
          console.info(this.TAG, `getSiteResultList result success ${JSON.stringify(result)}`);
          let panList: StationListItemReturning[] = (result as StationListItemReturning[])
          if (this.planningList !== undefined) {
            this.planningList = result

          }
          this.planningList = panList
          for (let i = 0; i < this.planningList.length; i++) {
            this.setSpotList(this.planningList[i],
              // this.planningList[i].chargeType === 1 ? $r('app.media.routerPlanning_site') : $r('app.media.slowPile'))
              this.planningList[i].chargeType === 1 ? $r('app.media.homeMap_siteIcon') : $r('app.media.slowPile'))
          }
        });
      }
      let points = result.routes[0]?.overviewPolyline;
      if (points && points.length > 0) {
        this.points = points;
        this.drawLine(points)
      }

    }).catch((err: BusinessError) => {
      console.log(this.TAG, `testDrivingRoutes error ${JSON.stringify(err)}`)
    });

  }

  siteValid(startLatLon: mapCommon.LatLng, endLatLon: mapCommon.LatLng, siteList: StationListItemReturning[]) {
    const DIFF = 2.72
    let maxLat: number,
      minLat: number,
      maxLng: number,
      minLng: number;
    let siteResult: StationListItemReturning[] = [];

    if (startLatLon.latitude >= endLatLon.latitude) {
      maxLat = startLatLon.latitude + DIFF;
      minLat = endLatLon.latitude - DIFF;
    } else {
      maxLat = endLatLon.latitude + DIFF;
      minLat = startLatLon.latitude - DIFF;
    }

    if (startLatLon.longitude >= endLatLon.longitude) {
      maxLng = startLatLon.longitude + DIFF;
      minLng = endLatLon.longitude - DIFF;
    } else {
      maxLng = endLatLon.longitude + DIFF;
      minLng = startLatLon.longitude - DIFF;
    }

    for (let i = 0; i < siteList.length; i++) {
      let site = siteList[i]
      if (site.latitude <= maxLat && site.latitude >= minLat && site.longitude <= maxLng && site.longitude >= minLng) {
        siteResult.push(site)
      }
    }

    return siteResult

  }

  async getDistance(origins: mapCommon.LatLng[], destinations: mapCommon.LatLng[]) {
    let params: navi.DrivingMatrixParams = {
      'origins': origins,
      'destinations': destinations,
      'language': 'zh_CN'
    }

    return await navi.getDrivingMatrix(params).then((result) => {
      console.log(this.TAG, 'getDrivingMatrix success', JSON.stringify(result))
      return result.rows
    }).catch((err: BusinessError) => {
      console.log(this.TAG, 'getDrivingMatrix error', JSON.stringify(err))
    })
  }

  routesResultProcess(result: navi.RouteResult) {
    let routes = result.routes[0]
    let step = routes?.steps[0]
    let distance: number | undefined;
    let overviewPolyline: mapCommon.LatLng[] | undefined = [];
    if (routes) {
      overviewPolyline = routes.overviewPolyline
    }
    if (step) {
      distance = step.distance
    }
    let resultObj: NaviResult = {
      routes,
      step,
      distance,
      overviewPolyline
    }
    return resultObj
  }

  async getSiteResultList(
    distance: number, // 距离
    endLatLon: mapCommon.LatLng,
    overviewPolyline: mapCommon.LatLng[], // 过程点
    siteList: StationListItemReturning[], //站点列表
    startSoc: number, // 开始的电量
    targetSoc: number, // 多少soc开始进行寻站
    mileageNumber: number, // 默认行驶里程
    recCount: number, // 递归次数 (防止数据异常无限递归)
    maxRecCount: number, // 最大递归次数
    localSiteResultList: StationListItemReturning[], //
  ): Promise<StationListItemReturning[] | undefined> {

    let drivingRange = startSoc * mileageNumber * 1000;

    console.info(this.TAG, `getSiteResultList drivingRange ${drivingRange}`);
    console.info(this.TAG, `getSiteResultList distance  ${distance}`);
    console.info(this.TAG, `getSiteResultList startSoc  ${startSoc}`);
    console.info(this.TAG, `getSiteResultList targetSoc  ${targetSoc}`);
    console.info(this.TAG, `getSiteResultList recCount  ${recCount}`);

    if (distance < drivingRange || recCount >= maxRecCount) {
      return localSiteResultList;
    }

    let startSearchPoint: undefined | mapCommon.LatLng

    if (startSoc > targetSoc) {
      let noFindRange = (startSoc - targetSoc) * mileageNumber * 1000;
      let noFindPercent = noFindRange / distance;
      let startSearchIndex = Math.ceil(overviewPolyline.length * noFindPercent) - 1;
      console.info(this.TAG, `getSiteResultList noFindRange  ${noFindRange}`);
      console.info(this.TAG, `getSiteResultList startSearchIndex  ${startSearchIndex}`);
      startSearchPoint = overviewPolyline[startSearchIndex]
    } else {
      startSearchPoint = overviewPolyline[0]
    }
    console.info(this.TAG, `getSiteResultList startSearchPoint  ${JSON.stringify(startSearchPoint)}`);

    let remainingPowerRange = targetSoc * mileageNumber;
    let searchRadius = remainingPowerRange;

    console.info(this.TAG, `getSiteResultList siteList  ${JSON.stringify(siteList)}`);
    let siteListLength = siteList.length;
    let index = 0;
    let count = 0;
    let desList: mapCommon.LatLng [] = []
    let resultList: navi.MatrixCell [] = []

    while (index < siteListLength) {

      desList.push({
        latitude: siteList[index].latitude,
        longitude: siteList[index].longitude
      })
      index++
      count++
      if (count >= 100) {
        count = 0
        let tempList = await this.getDistance([startSearchPoint], desList)
        desList = []
        if (tempList) {
          resultList.push(...tempList[0].cells)
        }
      }

    }

    if (desList.length > 0) {
      let tempList = await this.getDistance([startSearchPoint], desList)
      if (tempList) {
        resultList.push(...tempList[0].cells)
      }
    }

    console.log(this.TAG, 'getSiteResultList', JSON.stringify(resultList))
    console.log(this.TAG, 'getSiteResultList cells length', resultList.length)
    console.log(this.TAG, 'siteList length', siteList.length)

    let minValueIndex: number | undefined;
    let minDistanceValue: number | undefined;

    for (let i = 0; i < resultList.length; i++) {
      if (resultList[i].distance) {
        console.log(this.TAG, 'resultList[i].distance', resultList[i].distance)
        if ((resultList[i].distance as number) < (searchRadius * 1000)) {
          if (!minDistanceValue) {
            minDistanceValue = resultList[i].distance
            minValueIndex = i
          } else {
            if ((resultList[i].distance as number) < minDistanceValue) {
              minDistanceValue = resultList[i].distance
              minValueIndex = i
            }
          }

        }
      }
    }

    console.log(this.TAG, 'searchRadius', searchRadius)
    console.log(this.TAG, 'minValueIndex', minValueIndex)
    console.log(this.TAG, 'minDistanceValue', minDistanceValue)

    if (minValueIndex === undefined) {
      return undefined
    } else {
      console.log(this.TAG, 'result', JSON.stringify(siteList[minValueIndex]))
      localSiteResultList.push(siteList[minValueIndex])

      let params: navi.DrivingRouteParams = {
        // 起点的经纬度 origins
        origins: [
          startSearchPoint
        ],
        // 终点的经纬度
        destination: {
          'latitude': endLatLon.latitude,
          'longitude': endLatLon.longitude
        },
        language: 'zh_CN'
      }

      let tempNavResult = await navi.getDrivingRoutes(params).then((result) => {
        let navResult = this.routesResultProcess(result);
        return navResult
      })

      let localStartSoc = 1 - (minDistanceValue as number) / (mileageNumber * 1000)

      if (tempNavResult.distance && tempNavResult.overviewPolyline) {
        recCount++;
        return await this.getSiteResultList(
          tempNavResult.distance,
          endLatLon,
          tempNavResult.overviewPolyline,
          siteList,
          localStartSoc,
          targetSoc,
          mileageNumber,
          recCount,
          maxRecCount,
          localSiteResultList)
      } else {
        return undefined
      }

    }

  }

  drawLine(points: Array<mapCommon.LatLng>) {
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
      color: 0xff0a59f7
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

    console.info(this.TAG, `setMap myLocationButtonClick location ${JSON.stringify(location)}}`);
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