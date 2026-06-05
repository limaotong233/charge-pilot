import { BottomNav } from '../components/bottomNavigation';
import { homeParams } from '../model/interface/homeInterface';
import { Home } from './home';
import { User } from './user';
import { mediaquery, router } from '@kit.ArkUI';
import { LeftNav } from '../components/LeftNav';
import { common, AbilityConstant } from '@kit.AbilityKit';
import { LoadingCustomDialog } from '../components/loadingCustomDialog';
import { LocalPreferences } from '../service/LocalPreferences';
import { getUserInfo, getUserInfoImage } from '../api/LoginApi';
import { buffer } from '@kit.ArkTS';
import { userInfoReturning } from '../model/interface/api/LoginApiInterface';
import { useToastHook } from '../service';
import { ResultVO } from '../utils/Http';

@Entry
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  @StorageProp('currentBreakpoint') curBp: string = 'sm'
  @State activeName: string = '首页'
  @State currentIndex: number = 0
  private tasController: TabsController = new TabsController();
  @State selectIndex: number = 0;
  @State params: homeParams = router.getParams() as homeParams
  @State private currentBreakpoint: string = 'unknown'
  listener: mediaquery.MediaQueryListener = this.getUIContext().getMediaQuery().matchMediaSync('orientation: landscape')
  @State continueLoading: boolean = false
  @State chargingBtnName: string = '地图加载中'
  @State closeDialog: boolean = true
  @State accountImage: string = ''

  aboutToAppear(): void {
    if (this.params) {
      this.currentIndex = this.params.tabs
      this.activeName = this.params.tabs === 1 ? '我的' : '首页'
    }
  }

  onPageShow() {
    this.continueLoading = this.currentIndex === 1 ? false : true
    setTimeout(() => { // 进入该页面时，将应用设置为可迁移状态
      console.info('EntryAbility] dataSessionId index ', JSON.stringify(AppStorage.get('IsContinue')))
      this.continueLoading = AppStorage.get('IsContinue') as boolean
      this.context.setMissionContinueState(AbilityConstant.ContinueState.ACTIVE, (result) => {
        this.continueLoading = false
        console.info(`EntryAbility] 首页导航setMiss${JSON.stringify(result)}`)
      })
    }, 2000)
    // 获取用户信息 名称 头像
    getUserInfo<userInfoReturning>({ v: '' }).then((resUserInfo) => {
      if (resUserInfo) {
        LocalPreferences.put('account', resUserInfo.userName ? resUserInfo.userName : resUserInfo.account)
        LocalPreferences.put('accountImage', resUserInfo.avatar ? resUserInfo.avatar.fileAccessUrl : '')
        LocalPreferences.flush()

        if (resUserInfo.avatar) {
          getUserInfoImage<ArrayBuffer>({ fileCode: resUserInfo.avatar.fileAccessUrl.split('=')[1]}).then((res) => {
            const base64 = buffer.from(res).toString('base64')
            // console.info('接口 图片res', `data:image/png;base64,${base64}`)
            LocalPreferences.put('accountImageUrl', `data:image/png;base64,${base64}`)
            LocalPreferences.flush()
            this.accountImage = `data:image/png;base64,${base64}`
          })
        } else {
          LocalPreferences.put('accountImageUrl', '')
          LocalPreferences.flush()
          this.accountImage = ''
        }
      }
    }).catch((err: ResultVO<string>) => {
      LocalPreferences.put('accountImageUrl', '')
      LocalPreferences.flush()
      this.accountImage = ''
      useToastHook(err.msg, '40lpx')
    })
  }

  onPageHide(): void {
    AppStorage.setOrCreate('IsContinue', false)
  }

  build() {
    if (this.curBp === 'sm') {
      Column() {
        Tabs({ barPosition: BarPosition.End, index: this.currentIndex, controller: this.tasController }) {
          TabContent() {
            Column() {
              if (!this.continueLoading) {
                Home({
                  currentIndex: this.currentIndex,
                })
              }
              if (this.continueLoading) {
                LoadingCustomDialog({
                  dialogTitle: this.chargingBtnName,
                  autoCancel: true,
                  closeDialog: this.closeDialog
                })
              }
            }
          }

          TabContent() {
            User({
              accountImage: this.accountImage
            })
          }
        }
        .scrollable(false)
        .barOverlap(true)
        .barHeight('0lpx')

        BottomNav({
          activeName: this.activeName,
          currentIndex: this.currentIndex,
          onEvent: (data: string, index: number) => {
            console.info('navdata', data)
            console.info('navindex', index)
            this.activeName = data
            this.currentIndex = index
            this.tasController.changeIndex(index)
          }
        })
          .position({ bottom: 0 })
      }
      .height('100%')
      .width('100%')

    } else {
      Row() {
        LeftNav({
          activeName: this.activeName,
          onEvent: (data: string, index: number) => {
            console.info('navdata', data)
            console.info('navindex', index)
          }
        })
          .zIndex(1)
          .position({ top: '0lpx', left: '0lpx' })
        Tabs({ barPosition: BarPosition.End, index: this.currentIndex, controller: this.tasController }) {
          TabContent() {
            Column() {
              if (!this.continueLoading) {
                Home({
                  currentIndex: this.currentIndex,
                })
              }
              if (this.continueLoading) {
                LoadingCustomDialog({
                  dialogTitle: this.chargingBtnName,
                  autoCancel: true,
                  closeDialog: this.closeDialog
                })
              }
            }
          }

          TabContent() {
            User({
              accountImage: this.accountImage
            })
          }
        }
        // .position({top: '0lpx', left:'108lpx'})
        .scrollable(false)
        .barOverlap(true)
        .barHeight('0lpx')

      }
      .width('100%')
    }
  }
}