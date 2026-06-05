import { RouteSearchHeadComponent } from '../home/components/routeSearchHeadComponent'
import { router } from '@kit.ArkUI'
import { addressComponent, location, routePlanningParamsInfo } from '../../model/interface/routePlanningInterface'
import { site } from '@kit.MapKit'
import { geoLocationManager } from '@kit.LocationKit'
import { useToastHook } from '../../service'

interface siteListItem {
  name: string,
  addressComponent: addressComponent,
  location: location
}

// 关键词匹配 字符串转数组
export const filterFuction = (data: string, key: string) => {
  const t: Array<string> = []
  if (key === '') {
    return [data]
  } //处理空关键词情况

  let lastIndex = 0;
  let index = data.indexOf(key);

  while (index !== -1) {
    // 添加关键词前的非关键词部分
    if (index > lastIndex) {
      t.push(data.substring(lastIndex, index));
    }
    //添加关键词
    t.push(key);

    //更新查找位置
    lastIndex = index + key.length;
    index = data.indexOf(key, lastIndex);
  }
  //添加剩余部分
  if (lastIndex < data.length) {
    t.push(data.substring(lastIndex))
  }

  return t
}

@Entry
@Component
export struct RouteSearch {
  scroller: Scroller = new Scroller()
  @State @Watch('onChangeKeyWord') keyWord: string = '华为'
  @State siteList: Array<siteListItem> = []
  @State params: routePlanningParamsInfo = router.getParams() as routePlanningParamsInfo

  //
  onChangeKeyWord() {
    this.getMapSiteList()
  }

  // 获取关键词查询的地点列表
  async getMapSiteList() {
    // 当前位置坐标
    let location = await geoLocationManager.getCurrentLocation();
    let params: site.SearchByTextParams = {
      // 自定义关键词
      query: (this.keyWord === '我的位置' || this.keyWord === '输入目的地') ? '' : this.keyWord,
      // 经纬度
      location: {
        latitude: location.latitude,
        longitude: location.longitude
      },
      // 指定地理位置的范围半径
      radius: 10000,
      // 搜索结果的语言
      language: 'zh-CN'
    }
    this.siteList = []
    // 返回关键字搜索结果
    try {
      const result = await site.searchByText(params)
      console.info('接口 搜索结果', JSON.stringify(result));
      if (result.sites && result.sites?.length > 0) {
        this.siteList = result.sites.splice(0, 20) as siteListItem[] //.splice(0, 20)
      }
    } catch (error) {
      console.info('接口 搜索', JSON.stringify(error))
      if (params.query !== '') {
        useToastHook('地图服务异常请重试', '40lpx')
      }
    }
  }

  async aboutToAppear() {
    if (this.params.startOrEnd === 'start') {
      this.keyWord = AppStorage.get('startSpot') === '我的位置' || AppStorage.get('startSpot') === '输入目的地' ? '' :
        AppStorage.get('startSpot') as string
    } else if (this.params.startOrEnd === 'end') {
      this.keyWord = AppStorage.get('endSpot') === '我的位置' || AppStorage.get('endSpot') === '输入目的地' ? '' :
        AppStorage.get('endSpot') as string //AppStorage.get('endSpot') || ''
    }
  }

  build() {
    Column() {
      RouteSearchHeadComponent({
        keyWord: this.keyWord,
        startOrEnd: this.params.startOrEnd,
        receive: (data: string) => {
          console.info(data)
        }
      })
      Column() {
        Row() {
          Image($r('app.media.routeSearch_siteIcon'))
            .width('16lpx')
            .height('16lpx')
            .margin({ right: '8lpx' })
          Row() {
            Text(`我的位置`)
              .maxLines(1)
              .fontColor($r('app.color.historyList_font_color'))
              .wordBreak(WordBreak.BREAK_ALL)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')
        .padding({ left: '16lpx' })
        .margin({
          left: '16lpx',
          right: '16lpx',
          top: '16lpx',
          bottom: '16lpx'
        })
        .backgroundColor($r('app.color.background_color_over'))
        .borderRadius('16lpx')
      }
      .margin({
        left: '16lpx',
        right: '16lpx',
        top: '16lpx',
        bottom: '0lpx'
      })
      .backgroundColor($r('app.color.background_color_over'))
      .borderRadius('16lpx')
      .onClick(async () => {
        let location = await geoLocationManager.getCurrentLocation();

        if (this.params.startOrEnd === 'start') {
          AppStorage.setOrCreate('startSpot', '我的位置')
          AppStorage.setOrCreate('startSpotLocation', location)
        } else if (this.params.startOrEnd === 'end') {
          AppStorage.setOrCreate('endSpot', '我的位置')
          AppStorage.setOrCreate('endSpotLocation', location)
        }
        router.pushUrl({
          url: 'pages/routePlanning/index',
          params: {
            isSwitch: this.params.isSwitch,
          }
        })
      })

      if (this.siteList.length > 0) {
        Scroll(this.scroller) {
          Column() {
            ForEach(this.siteList, (item: siteListItem, index: number) => {
              Column() {
                Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                  Row() {
                    Image($r('app.media.routeSearch_siteIcon'))
                      .width('16lpx')
                      .height('16lpx')
                      .margin({ right: '8lpx' })
                    Row() {
                      ForEach(filterFuction(item.name, this.keyWord), (element: string) => {
                        Text(`${element}`)
                          .maxLines(1)
                          .fontColor(element === this.keyWord ? $r('app.color.longBtn_blue') :
                          $r('app.color.historyList_font_color'))
                          .wordBreak(WordBreak.BREAK_ALL)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }, (index2: string) => index2)
                    }
                    .width('170lpx')
                  }

                  Row() {
                    Image($r('app.media.userAccount_RightIcon'))
                      .width('16lpx')
                      .height('16lpx')
                  }
                }
                .margin({ top: '16lpx', bottom: item.addressComponent.adminLevel3 ? '0lpx' : '16lpx' })

                Row() {
                  if (item.addressComponent.adminLevel3) {
                    Text(`${item.addressComponent.adminLevel3 ? item.addressComponent.adminLevel3 : ''}${item.addressComponent.adminLevel4 ? item.addressComponent.adminLevel4 : ''}`)
                      .fontSize('12lpx')
                      .fontColor($r('app.color.999999'))
                      .padding({ bottom: '8lpx', top: '6lpx' })
                      .borderWidth({ bottom: index === this.siteList.length - 1 ? '0lpx' : '1lpx' })
                      .borderColor({ bottom: $r('app.color.EEEEEE') })
                      .width('100%')
                  } else {
                    Text()
                      .borderWidth({ bottom: index === this.siteList.length - 1 ? '0lpx' : '1lpx' })
                      .borderColor({ bottom: $r('app.color.EEEEEE') })
                      .width('100%')
                  }
                }
                .margin({ left: '24lpx', right: '0lpx' })

              }
              .margin({ left: '16lpx', right: '16lpx' })
              .onClick(() => {
                if (this.params.startOrEnd === 'start') {
                  AppStorage.setOrCreate('startSpot', item.name)
                  AppStorage.setOrCreate('startSpotLocation', item.location)
                } else if (this.params.startOrEnd === 'end') {
                  AppStorage.setOrCreate('endSpot', item.name)
                  AppStorage.setOrCreate('endSpotLocation', item.location)
                }
                router.pushUrl({
                  url: 'pages/routePlanning/index',
                  params: {
                    isSwitch: this.params.isSwitch,
                  }
                })
              })
            }, (index: string) => index)
          }
          .margin({
            left: '16lpx',
            right: '16lpx',
            top: '16lpx',
            bottom: '40lpx'
          })
          .backgroundColor($r('app.color.background_color_over'))
          .borderRadius('16lpx')
        }
        .scrollable(ScrollDirection.Vertical) //纵向滚动
        .scrollBar(BarState.Off)
      } else {
        Column() {
          Image($r('app.media.siteSearch_blockIcon'))
            .margin({ top: '48lpx' })
            .width('120lpx')
            .height('120lpx')
          Text('没有找到相关地址')
            .fontSize('12lpx')
            .fontColor($r('app.color.999999'))
        }
        .width('100%')
      }
    }
    .padding({ bottom: '16lpx' })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.card_background'))
  }
}