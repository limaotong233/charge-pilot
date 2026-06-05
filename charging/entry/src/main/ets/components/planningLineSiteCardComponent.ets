import { downLoadFile } from "../api/CollectionApi"
import { buffer } from "@kit.ArkTS"
import { StationListItemReturning } from "../model/interface/api/HomeApiInterface"

@Component
export struct PlanningLineSiteCardComponent {
  @Prop siteItemInfo: StationListItemReturning
  @Prop siteName: string
  @Prop tagList: Array<string> // = ['最快500kw', '对外开放', '互联互通']
  @State rating: number = 0;
  @Prop isShowCollect: boolean
  @Prop priceCount: number
  @Prop distanceKm: number
  @State imageUrl: string = ''

  aboutToAppear(): void {
    if (this.siteItemInfo.fileCode) {
      downLoadFile<ArrayBuffer>({ fileCode: this.siteItemInfo.fileCode }).then(async (res) => {
        const base64 = buffer.from(res).toString('base64') //buffer.from(res).toString('base64')
        console.info('接口 图片res', `data:image/png;base64,${base64}`)
        this.imageUrl = `data:image/png;base64,${base64}`
      }).catch((err: Error) => {
      })
    }
  }

  build() {
    Column() {
      Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
        Image(this.imageUrl ? this.imageUrl : $r('app.media.homeSearch_siteImage'))
          .margin({ right: '12lpx' })
          .borderRadius('10lpx')
          .width('58lpx')
          .height('48lpx')

        Column() {
          Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
            Text(this.siteName)
              .fontSize('16lpx')
          }
          .margin({ bottom: '8lpx' })

          Row() {
            ForEach(this.tagList, (item: string) => {
              Column() {
                Text(item)
                  .fontSize('12lpx')
                  .fontColor($r('app.color.bottom_nav_fontcolor'))
              }
              .borderRadius('10lpx')
              .margin({ right: '4lpx' })
              .padding({
                left: '8lpx',
                right: '8lpx',
                top: '1lpx',
                bottom: '1lpx'
              })
              .backgroundColor($r('app.color.tag_background'))
            }, (item: string) => item)
          }.alignSelf(ItemAlign.Start)
        }
      }
      .margin({ bottom: '24lpx' })

      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Flex({ justifyContent: FlexAlign.Start, alignItems: ItemAlign.Baseline }) {
          Text(`￥${this.priceCount}`)
            .fontSize('20lpx')
            .fontColor($r('app.color.chargingPrice_color'))
          Text('/度起')
            .fontSize('12lpx')
            .fontColor($r('app.color.charging_font_color'))
        }
        .width('50%')
      }
      .margin({ bottom: '4lpx' })
    }
    .backgroundColor($r('app.color.background_color_over'))
    .padding('12lpx')
    .borderRadius('6lpx')
  }
}