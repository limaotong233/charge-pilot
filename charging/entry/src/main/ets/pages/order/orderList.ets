import { getOrderList } from '../../api/OrderApi';
import { HeadComponent } from '../../components/headComponent'
import { Tmp } from '../../model/class';
import { OrderListItem, OrderListReturning, OrderListVO } from '../../model/interface/api/OrderApiInterface';
import { ListColumn } from '../../utils/ListColumn';
import { OrderItemCard } from './components/orderItemCard';
import { resStr } from '../../utils/i18n';

@Entry
@Component
export struct OrderList {
  @State fontColor: string = 'rgba(0,0,0,0.6)'
  @State selectedFontColor: Resource = $r('app.color.btn_blue')
  @State currentIndex: number = 0
  @State selectIndex: number = 0;
  @State lazyLoading: boolean = false
  @State allLoaded: boolean = false
  private controller: TabsController = new TabsController();
  @State orderList: OrderListItem[] = []
  @State currentPage: number = 1
  @State pageSize: number = 5
  @State orderStatus: number | null = null
  private context: Context = getContext(this)

  // 获取订单列表 性能让优化 反例设置每页加载1000条 正例按需加载
  async getOrderList() {
    if (this.lazyLoading || this.allLoaded) {
      return
    }
    this.lazyLoading = true
    let t: OrderListVO = {
      currentPage: this.currentPage,
      pageSize: this.pageSize, // 1000
      orderStatus: this.orderStatus
    }
    let res = await getOrderList<OrderListReturning>(t)

    console.info('接口 订单列表', JSON.stringify(res))
    if (res) {
      if (res.list.length === 0) {
        this.allLoaded = true
      } else {
        this.orderList = [...this.orderList, ...res.list]
        this.currentPage++
      }
    }
    this.lazyLoading = false
  }

  aboutToAppear(): void {
    this.getOrderList()
  }

  @Builder
  blockOrder() {
    Column() {
      Row() {
        Image($r('app.media.charging_pile_block'))
          .width('120lpx')
          .height('120lpx')
          .margin({ top: '40lpx' })
      }.justifyContent(FlexAlign.Center)

      Text(resStr(getContext(this), 'order_list_empty'))
        .fontSize('14lpx')
        .margin({ bottom: '8lpx' })
        .fontColor($r('app.color.999999'))
        .fontWeight('bold')
    }
    .height('100%')
    .width('100%')
  }

  @Builder
  tabBuilder(index: number, name: string) {
    Column() {
      Text(name)
        .fontColor(this.selectIndex === index ? this.selectedFontColor : this.fontColor)
        .fontSize(this.selectIndex === index ? '16lpx' : '14lpx')
        .fontWeight('400')
        .padding({ top: '18.5lpx', bottom: '18.5lpx' })
        .margin({ left: '18.5lpx', right: '18.5lpx' })
      Divider()
        .strokeWidth('4lpx')
        .color(this.selectedFontColor)
        .opacity(this.selectIndex === index ? 1 : 0)
    }
    .width('100%')
  }

  @Builder
  OrderList() {
    ListColumn({
      listMain: this.siteMain,
      num: { list: this.orderList },
      list: this.orderList,
      allLoaded: this.allLoaded,
      lazyLoading: this.lazyLoading,
      paddingLeft: '0lpx',
      paddingRight: '0lpx',
      paddingTop: '16lpx',
      paddingBottom: '80lpx',
      onEvent: () => {
        this.getOrderList()
      },
      getCollectList: () => {
        this.currentPage = 1
        this.lazyLoading = false
        this.allLoaded = false
        this.orderList = []
        this.getOrderList()
      }
    })
  }

  @Builder
  siteMain(num: Tmp) {
    ForEach(num.list, (item: OrderListItem, index: number) => {
      ListItem() {
        OrderItemCard({
          orderDetail: item
        })
          .margin({ bottom: index === num.list.length - 1 ? '0lpx' : '16lpx' })
      }
    }, (index: OrderListItem) => index.orderId)
  }

  build() {
    Column() {
      HeadComponent({
        headName: resStr(getContext(this), 'order_list_head_name'),
        isHaveBtn: false,
        backUrl: 'pages/Index',
        tabs: 1,
        receive: () => {
        }
      })
      Tabs({
        barPosition: BarPosition.Start,
        index: this.currentIndex,
        controller: this.controller
      }) {
        TabContent() {
          if (this.orderList.length === 0) {
            this.blockOrder()
          } else {
            this.OrderList()
          }
        }.tabBar(this.tabBuilder(0, resStr(getContext(this), 'order_list_tab_all')))

        TabContent() {
          if (this.orderList.length === 0) {
            this.blockOrder()
          } else {
            this.OrderList()
          }
        }.tabBar(this.tabBuilder(1, resStr(getContext(this), 'order_list_tab_pending')))

        TabContent() {
          if (this.orderList.length === 0) {
            this.blockOrder()
          } else {
            this.OrderList()
          }
        }.tabBar(this.tabBuilder(2, resStr(getContext(this), 'order_list_tab_completed')))
      }
      .vertical(false)
      .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        // currentIndex 控制页签
        this.currentPage = 1
        this.orderList = []
        this.lazyLoading = false
        this.allLoaded = false
        this.orderStatus = index === 0 ? null : index
        this.getOrderList()
        this.currentIndex = index;
        this.selectIndex = index;
      })
      .width('100%')
      .padding({ bottom: '16lpx', left: '16lpx', right: '16lpx' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.card_background'))
  }
}