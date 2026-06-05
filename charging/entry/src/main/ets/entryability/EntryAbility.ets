import { AbilityConstant, UIAbility, Want, wantConstant } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { distributedDataObject, distributedKVStore } from '@kit.ArkData';
import { display, window, router } from '@kit.ArkUI';
import { formInfo } from '@kit.FormKit';

import { BusinessError } from '@kit.BasicServicesKit';
import { JSON } from '@kit.ArkTS';
import { mapCommon } from '@kit.MapKit';

import { DataBaseService } from '../service/DataBaseService';
import { LocalPreferences } from '../service/LocalPreferences'
import { CardService } from '../service/Card';
import { StationListItemReturning } from '../model/interface/api/HomeApiInterface';
import { enterLeave } from '../api/HomeApi';

const BUNDLE_NAME = 'com.zjhw.charging';
const STORE_ID = '1234343534'

// 应用续接： 首页导航数据定义

const TAG = 'entry_test'

// 首页导航数据定义


/**
 * 首页导航数据定义,需要续接的业务数据
 */
class HomeMapIndexObject {
  isShowSheet: boolean | undefined //是否开启首页中站点详情卡片
  areaValue: string | undefined //用户当前所在城市
  areaIndex: number | undefined //用户当前所在城市ID
  keyWord: string | undefined //用户输入的搜索框关键字
  carStatus: string | undefined //当前车辆的状态（点击前往、正在前往、已到达、已离场）
  startTarget: mapCommon.LatLng | undefined //当前设备所在位置经纬度
  endTarget: mapCommon.LatLng | undefined //终点位置经纬度
  mapBtnIsEnterSpot: string | undefined //进入仿真站点/退出仿真站点的按钮状态名称
  siteItemInfo: StationListItemReturning | undefined //站点的详细信息

  constructor(isShowSheet: boolean | undefined, areaValue: string | undefined, areaIndex: number | undefined,
    keyWord: string | undefined, carStatus: string | undefined, startTarget: mapCommon.LatLng | undefined,
    endTarget: mapCommon.LatLng | undefined, mapBtnIsEnterSpot: string | undefined,
    siteItemInfo: StationListItemReturning | undefined) {
    this.isShowSheet = isShowSheet
    this.areaValue = areaValue
    this.areaIndex = areaIndex
    this.keyWord = keyWord
    this.carStatus = carStatus
    this.startTarget = startTarget
    this.endTarget = endTarget
    this.mapBtnIsEnterSpot = mapBtnIsEnterSpot
    this.siteItemInfo = siteItemInfo
  }
}

export default class EntryAbility extends UIAbility {
  storage: LocalStorage = new LocalStorage()
  o_object?: distributedDataObject.DataObject;
  // 一次开发多端部署： 断点设置
  private windowObj?: window.Window
  private curBp: string = ''
  private route: string = ''

  // 根据当前窗口尺寸更新断点
  private updateBreakpoint(windowWidth: number): void {
    // 将长度的单位由px换算为vp
    let windowWidthVp = windowWidth / display.getDefaultDisplaySync().densityPixels;
    let newBp: string = '';
    if (windowWidthVp < 360) {
      newBp = 'sm';
    } else if (windowWidthVp < 850) {
      newBp = 'sm'
    } else if (windowWidthVp < 1280) {
      newBp = 'md'
    } else {
      newBp = 'md'
    }
    if (this.curBp !== newBp) {
      this.curBp = newBp
      // 使用状态变量记录当前断点值
      AppStorage.setOrCreate('currentBreakpoint', this.curBp)
    }
  }

  // 应用续接，源端接口
  async onContinue(wantParam: Record<string, Object>) {
    //表示在跨端迁移过程中自动迁移页面栈信息
    wantParam[wantConstant.Params.SUPPORT_CONTINUE_PAGE_STACK_KEY] = true

    //开始构建迁移数据
    let homeMapIndexSource: HomeMapIndexObject = new HomeMapIndexObject(
      AppStorage.get('continueIsShowSheet'),
      AppStorage.get('continueAreaValue'),
      AppStorage.get('continueAreaIndex'),
      AppStorage.get('continueKeyWord'),
      AppStorage.get('continueCarStatus'),
      AppStorage.get('continueStartTarget'),
      AppStorage.get('continueEndTarget'),
      AppStorage.get('continueMapBtnIsEnterSpot'),
      AppStorage.get('siteItemInfo'),
    )
    // 创建分布式数据对象
    this.o_object = distributedDataObject.create(this.context, homeMapIndexSource)

    // 生成数据对象组网id,激活分布式数据对象
    let dataSessionId: string = distributedDataObject.genSessionId();
    this.o_object.setSessionId(dataSessionId);

    //将组网id存在want中传递到对端
    wantParam['dataSessionId'] = dataSessionId;

    // 数据对象持久化，确保迁移后及时应用退出，对端依然能够恢复数据对象
    // 从wantParam.targetDevice中获取对端设备的networkId作为入参
    await this.o_object.save(wantParam.targetDevice as string)
      .then((result: distributedDataObject.SaveSuccessResponse) => {
      })
      .catch((err: BusinessError) => {
      })

    return AbilityConstant.OnContinueResult.AGREE
  }

  //应用接续，对端接口（冷启动）
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppStorage.setOrCreate('IsContinue', false)
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      this.handleDistributedData(want)
    }

    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    // 键值型数据库
    let context = this.context;
    DataBaseService.createInstance({
      bundleName: BUNDLE_NAME,
      context
    })
    DataBaseService.getInstance().createStore(STORE_ID, {
      createIfMissing: true, // 当数据库文件不存在时是否创建数据库，默认创建
      encrypt: false, // 设置数据库文件是否加密，默认不加密
      backup: false, // 设置数据库文件是否备份，默认备份
      autoSync: true, // 设置数据库文件是否自动同步。默认为false，即手动同步；设置为true时，表示自动同步
      kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION, // 设置要创建的数据库类型，默认为多设备协同数据库
      securityLevel: distributedKVStore.SecurityLevel.S2 // 设置数据库安全级别
    }).then((kvStore: distributedKVStore.SingleKVStore) => {
      console.log('create kvStore success', kvStore)
    }).catch((err: Error) => {
      console.error('create kvStore fail', err)
    })

    console.log(TAG + ' onCreate want.parameters', JSON.stringify(want.parameters))

    LocalPreferences.init(this.context, {
      name: 'myStore'
    })
    this.handleFormRouterEvent(want);
    let route = want.parameters?.route;
    this.route = (route as string);

  }

  // 应用接续，对端接口（单实例应用热启动）
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppStorage.setOrCreate('IsContinue', false)
    // 1、已配置快速拉起功能，应用立即启动时触发应用生命周期回调
    if (launchParam.launchReason === AbilityConstant.LaunchReason.PREPARE_CONTINUATION) {

      // 若应用迁移数据较大，可在此处添加加载页面loading
      // 可处理应用自定义跳转，时序等问题
    }
    // 应用续接 2.迁移数据恢复时触发应用生命周期回调
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      // 调用封装好的分布式数据对象处理函数
      if (want.parameters !== undefined) {

        this.handleDistributedData(want)
      }
    }

    console.log(TAG + ' onCreate onNewWant want.parameters', want.parameters)
    let route = want.parameters?.route;
    console.log(TAG + ' onCreate onNewWant route', route)
    let routerState = router.getState();
    this.handleFormRouterEvent(want);
    CardService.setCardStatus('')
    if (route === 'noAppointment' || route === 'appointment') {
      if (routerState?.path != 'pages/advanceCharging/') {
        console.log(TAG + ' onCreate onNewWant routerState?.path', JSON.stringify(routerState))
        router.pushUrl({
          url: 'pages/advanceCharging/index'
        })
      }
      CardService.setCardStatus(route as string)
    }


    console.log(TAG + ' onCreate want.parameters', JSON.stringify(want.parameters))

    LocalPreferences.init(this.context, {
      name: 'myStore'
    })
    this.handleFormRouterEvent(want);
    this.route = (route as string);
  }

  //分布式数据对象处理函数
  handleDistributedData(want: Want) {
    //数据对象定义与上同
    let remoteSource: HomeMapIndexObject = new HomeMapIndexObject(
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      // undefined,
    )
    this.o_object = distributedDataObject.create(this.context, remoteSource)

    // 读取分布式数据对象组网id
    let dataSessionId = '';
    if (want.parameters !== undefined) {
      dataSessionId = want.parameters.dataSessionId as string
      console.info('EntryAbility] dataSessionId 有')
      AppStorage.setOrCreate('IsContinue', true)
    } else {
      console.info('EntryAbility] dataSessionId 无')

    }

    // 添加数据变更监听
    this.o_object.on('status', (sessionId: string, networkId: string, status: 'online' | 'offline' | 'restored') => {
      hilog.info(0xff00, '[EntryAbility]', 'status change' + sessionId + '' + status + ' ' + networkId)
      if (status === 'restored') {
        if (this.o_object) {
          // 收到迁移恢复的状态时，可以从分布式数据对象中读数据
          hilog.info(0xff00, '[EntryAbility]', 'restored name:' + JSON.stringify(this.o_object['keyWord']))
          hilog.info(0xff00, '[EntryAbility]', 'restored endTarget:' + JSON.stringify(this.o_object['endTarget']))
          hilog.info(0xff00, '[EntryAbility]', 'restored carStatus:' + JSON.stringify(this.o_object['carStatus']))
          hilog.info(0xff00, '[EntryAbility]', 'restored siteItemInfo:' + JSON.stringify(this.o_object['siteItemInfo']))
          AppStorage.setOrCreate('continueKeyWord', this.o_object['keyWord'])
          AppStorage.setOrCreate('continueIsShowSheet', this.o_object['isShowSheet'])
          // AppStorage.setOrCreate('continueAreaValue', this.o_object['areaValue'])
          // AppStorage.setOrCreate('continueAreaIndex', this.o_object['areaIndex'])
          AppStorage.setOrCreate('continueCarStatus', this.o_object['carStatus'])
          // AppStorage.setOrCreate('continueStartTarget', this.o_object['startTarget'])
          AppStorage.setOrCreate('continueEndTarget', this.o_object['endTarget'])
          AppStorage.setOrCreate('continueMapBtnIsEnterSpot', this.o_object['mapBtnIsEnterSpot'])
          AppStorage.setOrCreate('siteItemInfo', this.o_object['siteItemInfo'])

        }
      }
    })
    // 激活分布式数据对象
    this.o_object.setSessionId(dataSessionId)
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');

    // 退出应用时自动退出充电站
    const recordId = AppStorage.get('stationAccessRecordId') as string
    if (recordId && recordId !== '') {
      enterLeave<string>({ id: recordId }).then(() => {
        hilog.info(0x0000, 'testTag', '自动出站成功')
        AppStorage.setOrCreate('stationAccessRecordId', '')
        AppStorage.setOrCreate('continueMapBtnIsEnterSpot', '进入仿真充电站')
        AppStorage.setOrCreate('continueCarStatus', '点击前往')
      }).catch(() => {
        hilog.info(0x0000, 'testTag', '自动出站失败')
      })
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.getMainWindow().then((windowObj) => {

      this.windowObj = windowObj;
      //获取应用启动时的窗口尺寸
      this.updateBreakpoint(windowObj.getWindowProperties().windowRect.width);
      // 注册回调函数，监听窗口尺寸变化
      windowObj.on('windowSizeChange', (windowSize) => {
        this.updateBreakpoint(windowSize.width)
      })
    })
    // Main window is created, set main page for this ability
    hilog.info(0x0000, TAG + ' onWindowStageCreate', '%{public}s', 'Ability onWindowStageCreate');
    let jumpUrl = 'pages/login/index'
    CardService.setCardStatus('')
    if (this.route === 'noAppointment' || this.route === 'appointment') {
      jumpUrl = 'pages/advanceCharging/index'
      CardService.setCardStatus(this.route)
    }

    windowStage.loadContent(jumpUrl, (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }

  handleFormRouterEvent(want: Want): void {
    console.log(TAG, `handleFormRouterEvent, Want: ${JSON.stringify(want)}`);
    if (want.parameters && want.parameters[formInfo.FormParam.IDENTITY_KEY] !== undefined) {
      let curFormId = want.parameters[formInfo.FormParam.IDENTITY_KEY].toString();
      // want.parameters.params 对应 postCardAction() 中 params 内容
      // let message: string = (JSON.parse(want.parameters?.params as string))?.routerDetail;
      LocalPreferences.put('formId', curFormId)
      LocalPreferences.flush()
      console.log(TAG, `UpdateForm formId: ${curFormId}`);
    }
  }
}
