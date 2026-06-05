import { router } from '@kit.ArkUI';
import { homeParams } from '../model/interface/homeInterface';
import { useToastHook } from '../service';

@Component
export struct SearchComponent {
  @Builder
  DefaultEle() {
  }

  @Builder
  DefaultCancel() {
  }

  @Builder
  DefaultKeys() {
  }

  @BuilderParam areaSelect: () => void = this.DefaultEle;
  @BuilderParam cancelBtn: () => void = this.DefaultCancel;
  @BuilderParam keywordList: () => void = this.DefaultKeys;
  @Link @Watch('onChangeKeyWord') keyWord: string
  @StorageProp('currentBreakpoint') curBp: string = 'sm'
  @Prop isHaveArea: boolean;
  @Prop needContinue: boolean;
  @State searchValue: string = AppStorage.get('continueKeyWord') || '';
  @State params: homeParams = router.getParams() as homeParams
  @Link historyList: Array<string>

  // 监听
  onChangeKeyWord() {
    console.info('this.keyWord-watch', this.keyWord)
    this.searchValue = this.keyWord
  }

  async aboutToAppear() {
    console.log('SearchComponent this.params', JSON.stringify(this.params))

    if (this.params) {
      this.searchValue = this.params.keyWord
    }
  }

  aboutToDisappear(): void {
  }

  build() {
    Column() {
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        if (this.isHaveArea) {
          Column() {
            // 插槽内容 城市地点选择
            this.areaSelect();
          }
          .margin({ right: '8lpx' })
          .width('110lpx')
        }

        Column() {
          // 搜索框输入
          Search({ value: this.searchValue, placeholder: '请输入充电站', })
            .maxLength(60)
            .height('40lpx')

            .onSubmit((value) => {
              // .onSubmit((value) => {
              //键值型数据存储
              console.info('SearchComponent onSubmit value', value)
              console.info('SearchComponent onSubmit isHaveArea', this.isHaveArea)
              if (value === '') {
                return
              }
              if (this.historyList.indexOf(value) === -1) {
                if (this.historyList.length >= 4) {
                  this.historyList.pop()
                  this.historyList.unshift(value)
                } else {
                  this.historyList.unshift(value)
                }
              }
              if (this.isHaveArea) {
                router.clear()
                router.pushUrl({
                  url: 'pages/home/homeSearch',
                  params: {
                    isShowArea: false,
                    keyWord: this.searchValue
                  }
                })
              }
            })
            .onChange(async (value: string) => {
              if (value.length > 60) {
                useToastHook('限制输入长度60', '40lpx')
              }
              this.keyWord = value
              this.searchValue = this.keyWord
              AppStorage.setOrCreate('continueKeyWord', value)
            })
            .onFocus(() => {
              console.info('searchFocus',)
            })
        }
        .width('100%')

        Column() {
          // 插槽 按钮
          this.cancelBtn()
        }
      }
      .width('100%')
      .padding({
        left: '8lpx',
        right: '16lpx',
      })
      .borderRadius({
        topLeft: this.curBp === 'sm' ? '0lpx' : '16lpx',
        topRight: this.curBp === 'sm' ? '0lpx' : '16lpx',
        bottomLeft: this.historyList.length === 0 ? '16lpx' : '0lpx',
        bottomRight: this.historyList.length === 0 ? '16lpx' : '0lpx'
      })
      .backgroundColor($r('app.color.background_color_over'))

      this.keywordList()
    }
    .backgroundColor($r('app.color.background_color_over'))
    .borderRadius(this.curBp === 'sm' ? '0lpx' : '16lpx')
  }
}
