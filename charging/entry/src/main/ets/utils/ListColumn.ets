import { Tmp } from '../model/class'
import { CollectionListItem } from '../model/interface/api/CollectionApiInterface'
import { StationListItemReturning } from '../model/interface/api/HomeApiInterface'
import { OrderListItem } from '../model/interface/api/OrderApiInterface'


@Component
export struct ListColumn {
  @Prop num: Tmp

  @Builder
  DefaultEle(num: Tmp) {
  }

  @BuilderParam listMain: (num: Tmp) => void = this.DefaultEle;
  @Prop list: StationListItemReturning[] | CollectionListItem[] | OrderListItem[]
  @Prop carStatus: string
  @Link lazyLoading: boolean
  @Link allLoaded: boolean
  @Prop historyList: Array<string>
  @Prop paddingLeft: string
  @Prop paddingRight: string
  @Prop paddingTop: string
  @Prop paddingBottom: string
  onEvent: Function = () => {
  };
  getCollectList: Function = () => {
  }
  getStationListPort: Function = () => {
  }

  build() {
    Column() {
      List() {
        if (this.list.length > 0) {
          this.listMain({ list: this.num.list })
        }
        // 加载指示器
        if (this.lazyLoading) {
          ListItem() {
            Row() {
              LoadingProgress()
                .width('30lpx')
                .height('30lpx')
              Text('加载中')
                .margin({ left: '10lpx' })
            }.justifyContent(FlexAlign.Center)
            .padding('15lpx')
          }
        }
      }
      .onReachEnd(() => {
        // 核心懒加载触发点
        this.onEvent()
        console.info('接口 收藏列表 this.list', JSON.stringify(this.list))
        // this.getStationListPort()
      })
      .scrollBarWidth(0)

      // 底部提示
      Text(this.allLoaded ? '已加载全部数据' : `已加载${this.list.length}条数据`)
        .padding({ top: '5lpx' })
        .fontSize('10lpx')
        .fontColor($r('app.color.999999'))
    }
    .width('100%')
    .height('100%')
    .margin({ bottom: '56lpx' })
    .padding({
      left: this.paddingLeft,
      top: this.paddingTop,
      right: this.paddingRight,
      bottom: this.paddingBottom
    })
  }
}