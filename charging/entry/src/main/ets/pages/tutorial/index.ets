import { HeadComponent } from '../../components/headComponent'


@Entry
@Component
struct Index {
  scroller: Scroller = new Scroller()

  build() {
    Column() {
      HeadComponent({
        headName: '',
        isHaveBtn: false,
        receive: () => {
        }
      })
      Scroll(this.scroller) {
        Column() {
          Column() {
            Text('充电教程')
              .fontSize('36lpx')
              .fontWeight('600')
          }
          .width('100%')
          .padding({
            top: '30lpx',
            left: '16lpx'
          })
          .alignItems(HorizontalAlign.Start)

          Column() {
            Text('请参照以下步骤：')
              .fontSize('14lpx')
              .fontWeight('400')
              .fontColor('#696969')
          }
          .width('100%')
          .padding({
            top: '8lpx',
            left: '16lpx',
            bottom: '24lpx'
          })
          .alignItems(HorizontalAlign.Start)

          // 步骤1
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {
              Row() {
                Text('点击启动图标，打开APP')
                  .fontSize('12lpx')
              }

              Row() {
                Text('01')
                  .fontSize('36lpx')
                  .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
              }
              .linearGradient({
                direction: GradientDirection.Top,
                colors: [[0xe1ebf5, 0.0], [0xe1eaf4, 1.0]]
              })
              .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
            }
            .padding({
              left: '24lpx',
              top: '12lpx',
              right: '16lpx'
            })

            Column() {
              Image($r('app.media.tutorial5'))
                .width('48lpx')
                .height('48lpx')
              Text('鸿蒙智能充电')
                .fontSize('10lpx')
                .padding({
                  top: '4lpx',
                  left: '4lpx',
                })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding({
              left: '24lpx',
              bottom: '16lpx'
            })
          }
          .border({
            width: '2lpx',
            color: '#fff'
          })
          .borderRadius('16lpx')
          .backgroundColor('#F6F7F9')
          .width('328lpx')
          .margin({
            left: '16lpx',
            right: '16lpx',
            bottom: '16lpx'
          })

          // 步骤2
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {
              Row() {
                Text('用指定账号，登录APP')
                  .fontSize('12lpx')
              }

              Row() {
                Text('02')
                  .fontSize('36lpx')
                  .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
              }
              .linearGradient({
                direction: GradientDirection.Top,
                colors: [[0xe1ebf5, 0.0], [0xe1eaf4, 1.0]]
              })
              .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
            }
            .padding({
              left: '24lpx',
              top: '12lpx',
              right: '16lpx'
            })

            Column() {
              Image($r('app.media.tutorial'))
                .width('161lpx')
                .height('113lpx')
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding({
              left: '24lpx',
              // top:'12lpx',
              bottom: '16lpx'
            })
          }
          .border({
            width: '2lpx',
            color: '#fff'
          })
          .borderRadius('16lpx')
          .backgroundColor('#F6F7F9')
          .width('328lpx')
          .margin({
            left: '16lpx',
            right: '16lpx',
            bottom: '16lpx'
          })

          // 步骤3
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {
              Row() {
                Text('选择目标充电站，点击"进入充电站"按钮')
                  .fontSize('12lpx')
              }

              Row() {
                Text('03')
                  .fontSize('36lpx')
                  .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
              }
              .linearGradient({
                direction: GradientDirection.Top,
                colors: [[0xe1ebf5, 0.0], [0xe1eaf4, 1.0]]
              })
              .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
            }
            .padding({
              left: '24lpx',
              top: '12lpx',
              right: '16lpx'
            })

            Column() {
              Row() {
                Image($r('app.media.tutorial2'))
                  .width('136lpx')
                  .height('89lpx')
                  .zIndex(1)
                Image($r('app.media.tutorial3'))
                  .width('136lpx')
                  .height('89lpx')
                  .margin({
                    top: '24lpx'
                  })
                  .offset({
                    left: '-20lpx'
                  })
                  .zIndex(0)
              }
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding({
              left: '24lpx',
              // top:'12lpx',
              bottom: '16lpx'
            })
          }
          .border({
            width: '2lpx',
            color: '#fff'
          })
          .borderRadius('16lpx')
          .backgroundColor('#F6F7F9')
          .width('328lpx')
          .margin({
            left: '16lpx',
            right: '16lpx',
            bottom: '16lpx'
          })

          // 步骤4
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {
              Row() {
                Text('扫描充电桩二维码，点击"启动充电"')
                  .fontSize('12lpx')
              }

              Row() {
                Text('04')
                  .fontSize('36lpx')
                  .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
              }
              .linearGradient({
                direction: GradientDirection.Top,
                colors: [[0xe1ebf5, 0.0], [0xe1eaf4, 1.0]]
              })
              .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
            }
            .padding({
              left: '24lpx',
              top: '12lpx',
              right: '16lpx'
            })

            Column() {
              Row() {
                Image($r('app.media.tutorial7'))
                  .width('111lpx')
                  .height('138lpx')
                Image($r('app.media.tutorial6'))
                  .width('111lpx')
                  .height('138lpx')
                  .margin({
                    left: '10lpx'
                  })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding({
              left: '24lpx',
              // top:'12lpx',
              bottom: '16lpx'
            })
          }
          .border({
            width: '2lpx',
            color: '#fff'
          })
          .borderRadius('16lpx')
          .backgroundColor('#F6F7F9')
          .width('328lpx')
          .margin({
            left: '16lpx',
            right: '16lpx',
            bottom: '16lpx'
          })

          // 步骤5
          Column() {
            Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {
              Row() {
                Text('点击"停止充电"弹出支付窗口，完成支付')
                  .fontSize('12lpx')
              }

              Row() {
                Text('05')
                  .fontSize('36lpx')
                  .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
              }
              .linearGradient({
                direction: GradientDirection.Top,
                colors: [[0xe1ebf5, 0.0], [0xe1eaf4, 1.0]]
              })
              .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
            }
            .padding({
              left: '24lpx',
              top: '12lpx',
              right: '16lpx'
            })

            Column() {
              Row() {
                Image($r('app.media.tutorial6'))
                  .width('111lpx')
                  .height('138lpx')
                Image($r('app.media.tutorial4'))
                  .width('111lpx')
                  .height('138lpx')
                  .margin({
                    left: '10lpx'
                  })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding({
              left: '24lpx',
              // top:'12lpx',
              bottom: '16lpx'
            })
          }
          .border({
            width: '2lpx',
            color: '#fff'
          })
          .borderRadius('16lpx')
          .backgroundColor('#F6F7F9')
          .width('328lpx')
          .margin({
            left: '16lpx',
            right: '16lpx',
            bottom: '16lpx'
          })

          Column() {
            Text('~到底了~')
              .fontSize('12lpx')
              .fontColor('#696969')
          }
          .margin({
            top: '4lpx'
          })
        }
        .padding({
          bottom: '50lpx'
        })
      }
      .scrollable(ScrollDirection.Vertical)
    }
    .width('100%')
    .backgroundImage($r('app.media.tutorialBg'))
    .backgroundImageSize(ImageSize.Contain)
  }
}
