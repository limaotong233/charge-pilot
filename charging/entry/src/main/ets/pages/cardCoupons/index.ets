import { getVoucherAdd, getVoucherCount, getVoucherList } from '../../api/CardCouponsApi';
import { BottomDialog } from '../../components/bottomDialog'
import { CustomShowToast } from '../../components/customShowToast'
import { HeadComponent } from '../../components/headComponent'
import {
  VoucherCountReturning,
  VoucherListReturning,
  VoucherListVO
} from '../../model/interface/api/CardCouponsApiInterface';
import { useToastHook } from '../../service';
import { JSON } from '@kit.ArkTS';

@Observed
class cardItems {
  price: number;
  count: number;
  voucherId: string

  constructor(price: number, count: number, voucherId: string) {
    this.price = price
    this.count = count
    this.voucherId = voucherId
  }
}

// 弹框内卡券
@Component
struct CarMainContentItem {
  @ObjectLink mainContentItem: cardItems
  @Link userCardList: cardItems[]
  @Link cusSText: string
  @Link cardList: cardItems[]

  // 领取卡券
  async addVoucher(id: string) {
    let res = await getVoucherAdd<string>({ voucherId: id })
    await this.getVoucherList()
    await this.getVoucherCount()
    console.info('接口 领取卡券', JSON.stringify(res))
    useToastHook('领取成功', '32lpx')
  }

  // 我的卡券数量
  async getVoucherCount() {
    let res = await getVoucherCount<VoucherCountReturning>({ voucherId: '1' })
    console.info('卡券数量receive getVoucherCount res', Number(res))
    if (this.userCardList[0].count > 0) {
      this.userCardList[0].count = Number(res)
      console.info('卡券数量receive getVoucherCount 1',this.userCardList[0].count)
    } else {
      console.info('卡券数量receive getVoucherCount 1.5', JSON.stringify(this.userCardList))
      let carItem = this.userCardList[0]
      this.userCardList.shift()
      this.userCardList.unshift(new cardItems(carItem.price, Number(res), carItem.voucherId))
    }
    console.info('卡券数量receive getVoucherCount 4', this.userCardList[0].count)
  }

  // 获取卡券列表
  async getVoucherList() {
    let voucherListVO: VoucherListVO = {
      currentPage: 1,
      pageSize: 5,
    }
    let res = await getVoucherList<VoucherListReturning>(voucherListVO)
    if (res && res.list?.length > 0) {
      console.info('卡券数量receive', JSON.stringify(res))
      res.list.forEach((item) => {
        this.mainContentItem.count = item.totalNum - item.usedNum
        this.cardList.push(
          new cardItems(item.voucherValue, (item.totalNum - item.usedNum), item.voucherId)
        )
      })
    } else {
      this.cardList = []
    }
  }

  build() {
    Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
      Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
        Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Baseline }) {
          Text(`${this.mainContentItem.price}`)
            .fontSize('36lpx')
            .fontColor($r('app.color.chargingPrice_color'))
            .fontWeight('bold')
          Text('元')
            .fontSize('12lpx')
            .fontColor($r('app.color.chargingPrice_color'))
        }
        .width('auto')

        Column() {
          Row() {
            Text('充电缴费代金券')
              .fontSize('16lpx')
          }.margin({ bottom: '10lpx' })

          Row() {
            Text(`无门槛使用`)
              .fontSize('12lpx')
              .fontColor($r('app.color.charging_font_color'))
          }
          .width('100%')
        }
        .width('112lpx')
        .margin({ left: '16lpx' })
      }

      Column() {
        Button({ type: ButtonType.Capsule, stateEffect: true }) {
          Row() {
            Text('领取').fontSize('12lpx').fontColor($r('app.color.background_color_over')).height('20lpx')
          }.alignItems(VerticalAlign.Center).height('20lpx').margin({ left: '12lpx', right: '12lpx' })
        }.backgroundColor($r('app.color.longBtn_blue')).height('24lpx').width('100%')
        .onClick(async () => {
          console.info(`接口领取 我卡券${JSON.stringify(this.userCardList)}`)
          console.info(`接口领取 卡券item${JSON.stringify(this.mainContentItem)}`)
          let res = await getVoucherCount<VoucherCountReturning>({ voucherId: '1' })
          console.info('接口 我的卡券数量', JSON.stringify(res))
          if (Number(res) < 10) {
            await this.addVoucher(this.mainContentItem.voucherId)
          } else if (Number(res) === 10) {
            this.cusSText = `您领取的${this.mainContentItem.price}代金券已满${10}张`
          }
          console.info(`卡券数量receive 卡券${JSON.stringify(this.userCardList)}`)
        })
      }.width('72lpx').margin({ top: '28lpx' })
    }
    .borderRadius('16lpx')
    .backgroundColor($r('app.color.background_color_over'))
    .padding('16lpx')
    .margin({ left: '16lpx', right: '16lpx', bottom: '16lpx' })
  }
}

// 主页面卡券
@Component
struct MainContentTwo {
  @ObjectLink mainContentItems: cardItems

  build() {
    if (this.mainContentItems.count > 0) {
      Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
        Column() {
          Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Baseline }) {
            Text(`${this.mainContentItems.price}`)
              .fontSize('36lpx')
              .fontColor($r('app.color.chargingPrice_color'))
              .fontWeight('bold')
            Text('元')
              .fontSize('12lpx')
              .fontColor($r('app.color.chargingPrice_color'))
          }
          .width('auto')

          Row() {
            Text('代金券')
              .fontSize('12lpx')
              .fontColor($r('app.color.chargingPrice_color'))
          }
          .margin({ top: '8.00lpx' })
          .width('auto')
        }
        .width('120lpx')
        .alignSelf(ItemAlign.Center)
        //right: '65lpx',
        .margin({ top: '24lpx', bottom: '24lpx' })

        Column() {
          Text('充电缴费代金券')
          Row() {
            Column() {
            }
            .width('4lpx')
            .height('4lpx')
            .borderRadius('4lpx')
            .margin({ right: '4lpx' })
            .backgroundColor($r('app.color.charging_font_color'))

            Text('无门槛使用')
              .width('100%')
              .fontSize('12lpx')
              .fontColor($r('app.color.charging_font_color'))
          }
          .margin({ top: '12lpx', bottom: '8lpx' })

          Row() {
            Column() {
            }
            .width('4lpx')
            .height('4lpx')
            .borderRadius('4lpx')
            .margin({ right: '4lpx' })
            .backgroundColor($r('app.color.charging_font_color'))

            Text(`数量：${this.mainContentItems.count}`)
              .width('100%')
              .fontSize('12lpx')
              .fontColor($r('app.color.charging_font_color'))
          }
        }
        .width('112lpx')
        .margin({ left: '32lpx', top: '30lpx', bottom: '26lpx' })
      }
      .padding({ right: '33lpx' })
      .margin({ top: '16lpx', left: '16lpx', right: '16lpx' })
      .borderRadius('16lpx')
      .backgroundImage($r('app.media.cardCoupons_di'))
      .backgroundImageSize({ width: '100%', height: '100%' })
    }
  }
}

@Entry
@Component
export struct CardCoupons {
  @State @Watch('onChangeIsShowMarkLayer') isShowMarkLayer: boolean = false
  @State haveCard: boolean = false
  @State userCardList: cardItems[] = []
  @State cardList: cardItems[] = []
  @State @Watch('onCustomShowToast') cusSText: string = ''

  onCustomShowToast() {
    if (this.cusSText !== '') {
      setTimeout(() => {
        this.cusSText = ''
      }, 2000)
    }
  }

  // 监听领取弹窗 弹出
  async onChangeIsShowMarkLayer() {
    if (this.isShowMarkLayer) {
      await this.getVoucherList()
    } else {
    }
  }

  // 我的卡券数量
  async getVoucherCount() {
    let res = await getVoucherCount<VoucherCountReturning>({ voucherId: '1' })
    console.info('接口 我的卡券数量', JSON.stringify(res))
    this.userCardList[0].count = Number(res)
  }

  // 获取卡券列表
  async getVoucherList() {
    let t: VoucherListVO = {
      currentPage: 1,
      pageSize: 5,
    }
    let res = await getVoucherList<VoucherListReturning>(t)
    if (res && res.list?.length > 0) {
      console.info('接口 卡券', JSON.stringify(res))
      res.list.forEach((item) => {
        this.cardList.push(
          new cardItems(item.voucherValue, (item.totalNum - item.usedNum), item.voucherId)
        )
      })
    } else {
      this.cardList = [
        new cardItems(100, 0, '1')
      ]
    }
  }

  async aboutToAppear() {
    await this.getVoucherList()
    let res = await getVoucherCount<VoucherCountReturning>({ voucherId: '1' })
    console.info('接口 我的卡券数量', JSON.stringify(res))
    console.info('接口 我的卡券数量', JSON.stringify(this.cardList))
    this.cardList.forEach((item) => {
      this.userCardList.push(new cardItems(item.price, Number(res), item.voucherId))
    })
  }

  // 领取 弹框内容
  @Builder
  mainContent() {
    Column() {
      if (this.cardList.length > 0) {
        if (this.cardList[0].count > 0) {
          List() {
            ForEach(this.cardList, (item: cardItems) => {
              ListItem() {
                CarMainContentItem({
                  mainContentItem: item,
                  userCardList: this.userCardList,
                  cusSText: this.cusSText,
                  cardList: this.cardList
                })
              }

            }, (item: cardItems) => ('cardMain' + item.price))
          }
        } else {
          Column() {
            Row() {
              Image($r('app.media.charging_pile_block'))
                .width('120lpx')
                .height('120lpx')
                .margin({ top: '0lpx' })
            }.justifyContent(FlexAlign.Center)
          }
          .width('100%')
        }
      } else {
        Column() {
          Row() {
            Image($r('app.media.charging_pile_block'))
              .width('120lpx')
              .height('120lpx')
              .margin({ top: '0lpx' })
          }.justifyContent(FlexAlign.Center)
        }
        .width('100%')
      }
    }
  }

  // 领取数量限制提示
  @Builder
  customToast() {
    if (this.cusSText !== '') {
      CustomShowToast({
        cusSTBorderRadius: '8lpx',
        cusSTBackgroundColor: 'rgba(252, 227, 223, 1)',
        cusSTText: this.cusSText,
        cusSTImage: $r('app.media.customShowToast_error'),
        cusSTFontColor: $r('app.color.longBtn_red')
      })
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column() {
        HeadComponent({
          headName: '我的卡券',
          isHaveBtn: true,
          receive: () => {
            this.isShowMarkLayer = true
            console.info('卡券数量receive this.userCardList', JSON.stringify(this.userCardList))
          }
        })
        if (this.userCardList.length === 0) {
          Column() {
            Row() {
              Image($r('app.media.charging_pile_block'))
                .width('120lpx')
                .height('120lpx')
                .margin({ top: '40lpx' })
            }.justifyContent(FlexAlign.Center)

            Text('暂无卡券')
              .fontSize('14lpx')
              .margin({ bottom: '8lpx' })
              .fontColor($r('app.color.999999'))
              .fontWeight('bold')

            Text('点击右上方“领取”按钮去领取卡券')
              .fontSize('12lpx')
              .fontColor($r('app.color.999999'))
          }
          .width('100%')
        } else {
          Column() {
            if (this.userCardList[0].count > 0) {
              List() {
                ForEach(this.userCardList, (item: cardItems) => {
                  ListItem() {
                    MainContentTwo({
                      mainContentItems: item
                    })
                  }
                }, (item: cardItems) => ('card' + item.price))
              }
            } else {
              Column() {
                Row() {
                  Image($r('app.media.charging_pile_block'))
                    .width('120lpx')
                    .height('120lpx')
                    .margin({ top: '40lpx' })
                }.justifyContent(FlexAlign.Center)

                Text('暂无卡券')
                  .fontSize('14lpx')
                  .margin({ bottom: '8lpx' })
                  .fontColor($r('app.color.999999'))
                  .fontWeight('bold')

                Text('点击右上方“领取”按钮去领取卡券')
                  .fontSize('12lpx')
                  .fontColor($r('app.color.999999'))
              }
              .width('100%')
            }
          }
          .width('100%')
        }

      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.card_background'))

      if (this.isShowMarkLayer) {

        BottomDialog({
          bdBackgroundColor: $r('app.color.F3F3F3'),
          bdName: '卡券领取',
          isHaveLongBtn: false,
          CustomShowToast: (): void => {
            this.customToast()
          },
          MainContent: (): void => {
            this.mainContent()
          },
          cancelOnclick: async () => {
            this.isShowMarkLayer = false
          },
        })
      }
    }
  }
}