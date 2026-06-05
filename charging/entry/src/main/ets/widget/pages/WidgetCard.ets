let storageUpdateByMsg = new LocalStorage();

@Entry(storageUpdateByMsg)
@Component
struct WidgetCard {
  @LocalStorageProp('name') name: ResourceStr = '';
  @LocalStorageProp('pileNum') pileNum: ResourceStr = '';
  @LocalStorageProp('status') status: ResourceStr = '';
  @LocalStorageProp('beginTime') beginTime: ResourceStr = '';
  @LocalStorageProp('endTime') endTime: ResourceStr = '';
  readonly ACTION_TYPE = 'router'
  readonly ABILITY_NAME: string = 'EntryAbility';

  build() {
    Column() {
      Row() {
        Text('充电预约卡片')
          .fontSize('40lpx')
          .fontWeight(600)
      }
      .width('100%')
      .padding({
        top: '32lpx',
        left: '32lpx',
        right: '32lpx'
      })

      if (this.name) {
        Row() {
          Flex({ justifyContent: FlexAlign.SpaceBetween }) {
            Column() {
              Row() {
                Text(this.name)
                  .fontSize('28lpx')
                  .fontWeight(600)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }

              Row() {
                Text(this.pileNum)
                  .fontSize('48lpx')
                  .fontWeight(600)
                Text('号充电桩')
                  .fontSize('24lpx')
                  .padding({
                    top: '16lpx'
                  })
              }
              .margin({
                top: '16lpx'
              })
            }
            .alignItems(HorizontalAlign.Start)

            Column() {
              Text(this.status)
                .fontColor('#ffffff')
                .fontSize('28lpx')
                .fontWeight(600)
            }
            .width('64lpx')
            .height('64lpx')
            .borderRadius('8lpx')
            .backgroundColor(this.status === '闲' ? '#64bb5c' : '#ED6F21')
            .justifyContent(FlexAlign.Center)
            .margin({
              top: '24lpx'
            })
          }
        }
        .width('100%')
        .padding({
          top: '32lpx',
          left: '32lpx',
          right: '32lpx'
        })

        Row() {
          Flex({ justifyContent: FlexAlign.SpaceBetween }) {
            Row() {
              Text('预约时间：')
                .fontSize('24lpx')
            }

            Row() {
              Text(this.beginTime)
                .fontSize('24lpx')
              Text('至')
                .fontSize('24lpx')
                .padding({
                  left: '16lpx',
                  right: '16lpx'
                })
              Text(this.endTime)
                .fontSize('24lpx')
            }
          }

        }
        .padding({
          top: '32lpx',
          left: '32lpx',
          right: '32lpx'
        })
      } else {
        Row() {
          Column() {
            Image($r('app.media.charging_pile_block'))
              .width('142lpx')
              .height('142lpx')
            Text('暂无预约')
              .fontSize('28lpx')
              .fontColor('#999999')
          }
        }
      }


    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      if (this.name) {
        postCardAction(this, {
          action: this.ACTION_TYPE,
          abilityName: this.ABILITY_NAME,
          params: {
            route: 'appointment'
          }
        });
      } else {
        postCardAction(this, {
          action: this.ACTION_TYPE,
          abilityName: this.ABILITY_NAME,
          params: {
            route: 'noAppointment'
          }
        });
      }

    })
  }
}