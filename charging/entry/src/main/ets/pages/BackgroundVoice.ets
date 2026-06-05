import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { wantAgent, WantAgent } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';

// ai部分

import { textToSpeech } from '@kit.CoreSpeechKit';


const TAG = 'huaweiBackgorund'

@Entry
@Component
struct Index {
  @State message: string = 'ContinuousTask';
  // 通过getContext方法，来获取page所在的UIAbility上下文。
  private context: Context = getContext(this);
  private ttsEngine?: textToSpeech.TextToSpeechEngine;
  private requestId: number = 1;
  private internalTime?: number

  OnContinuousTaskCancel() {

  }

  OffContinuousTaskCancel() {

  }

  initAISpeech() {
    // 设置创建引擎参数
    let extraParam: Record<string, Object> = { 'style': 'interaction-broadcast', 'locate': 'CN', 'name': 'EngineName' };
    let initParamsInfo: textToSpeech.CreateEngineParams = {
      language: 'zh-CN',
      person: 0,
      online: 1,
      extraParams: extraParam
    };

    // 调用createEngine方法
    textToSpeech.createEngine(initParamsInfo,
      (err: BusinessError, textToSpeechEngine: textToSpeech.TextToSpeechEngine) => {
        if (!err) {
          console.info(TAG, 'Succeeded in creating engine');
          // 接收创建引擎的实例
          this.ttsEngine = textToSpeechEngine;
          // 设置speak的回调信息
          let speakListener: textToSpeech.SpeakListener = {
            // 开始播报回调
            onStart(requestId: string, response: textToSpeech.StartResponse) {
              console.info(TAG, `onStart, requestId: ${requestId} response: ${JSON.stringify(response)}`);
            },
            // 合成完成及播报完成回调
            onComplete(requestId: string, response: textToSpeech.CompleteResponse) {
              console.info(TAG, `onComplete, requestId: ${requestId} response: ${JSON.stringify(response)}`);
            },
            // 停止播报回调
            onStop(requestId: string, response: textToSpeech.StopResponse) {
              console.info(TAG, `onStop, requestId: ${requestId} response: ${JSON.stringify(response)}`);
            },
            // 返回音频流
            onData(requestId: string, audio: ArrayBuffer, response: textToSpeech.SynthesisResponse) {
              console.info(TAG,
                `onData, requestId: ${requestId} sequence: ${JSON.stringify(response)} audio: ${JSON.stringify(audio)}`);
            },
            // 错误回调
            onError(requestId: string, errorCode: number, errorMessage: string) {
              console.error(TAG,
                `onError, requestId: ${requestId} errorCode: ${errorCode} errorMessage: ${errorMessage}`);
            }
          };
          // 设置回调
          this.ttsEngine.setListener(speakListener);

        } else {
          console.error(TAG, `Failed to create engine. Code: ${err.code}, message: ${err.message}.`);
        }
      });
  }

  aboutToAppear() {
    this.initAISpeech();
  }

  aboutToDisappear() {

  }

  AISpeech(originalText: string, requestId: string) {
    if (this.ttsEngine) {
      // 设置播报相关参数
      let extraParam: Record<string, Object> = {
        'queueMode': 0,
        'speed': 1,
        'volume': 2,
        'pitch': 1,
        'languageContext': 'zh-CN',
        'audioType': 'pcm',
        'soundChannel': 3,
        'playType': 1
      };
      let speakParams: textToSpeech.SpeakParams = {
        requestId, // requestId在同一实例内仅能用一次，请勿重复设置
        extraParams: extraParam
      };
      // 调用播报方法
      // 开发者可以通过修改speakParams主动设置播报策略
      this.ttsEngine.speak(originalText, speakParams);
    }
  }

  startContinuousTask() {
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      // 点击通知后，将要执行的动作列表
      // 添加需要被拉起应用的bundleName和abilityName
      wants: [
        {
          bundleName: 'com.zjhw.charging',
          abilityName: 'EntryAbility'
        }
      ],
      // 指定点击通知栏消息后的动作是拉起ability
      actionType: wantAgent.OperationType.START_ABILITY,
      // 使用者自定义的一个私有值
      requestCode: 0,
      // 点击通知后，动作执行属性
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      // 车钥匙长时任务子类型。只有申请bluetoothInteraction类型的长时任务，车钥匙子类型才能生效。
      // 确保extraInfo参数中的Key值为backgroundTaskManager.BackgroundModeType.SUB_MODE，否则子类型不生效。
      // extraInfo: { [backgroundTaskManager.BackgroundModeType.SUB_MODE] : backgroundTaskManager.BackgroundSubMode.CAR_KEY }
    };


    try {
      // 通过wantAgent模块下getWantAgent方法获取WantAgent对象
      wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj: WantAgent) => {
        try {
          let list: Array<string> = ['audioPlayback', 'location'];
          // let list: Array<string> = ["bluetoothInteraction"]; 长时任务类型包含bluetoothInteraction，CAR_KEY子类型合法
          backgroundTaskManager.startBackgroundRunning(this.context, list, wantAgentObj)
            .then((res: backgroundTaskManager.ContinuousTaskNotification) => {
              console.info(TAG, 'Operation startBackgroundRunning succeeded');
              // 此处执行具体的长时任务逻辑，如录音，录制等。
              let time = 0;

              if (this.internalTime === undefined) {
                this.internalTime = setInterval(() => {
                  console.info(TAG, 'startBackgroundRunning  internal');
                  geoLocationManager.getCurrentLocation();
                  if (time % 15 === 0) {
                    let time = new Date();
                    let timeTip = `${time.getHours()}时 ${time.getMinutes()}分 ${time.getSeconds()}秒`;
                    this.requestId++;
                    this.AISpeech('现在是' + timeTip, this.requestId + '')
                  }
                  time++
                }, 1000)
              }
            })
            .catch((error: BusinessError) => {
              console.error(TAG,
                `Failed to Operation startBackgroundRunning. code is ${error.code} message is ${error.message}`);
            });
        } catch (error) {
          console.error(TAG,
            `Failed to Operation startBackgroundRunning. code is ${(error as BusinessError).code} message is ${(error as BusinessError).message}`);
        }
      });
    } catch (error) {
      console.error(TAG,
        `Failed to Operation getWantAgent. code is ${(error as BusinessError).code} message is ${(error as BusinessError).message}`);
    }
  }

  stopContinuousTask() {
    backgroundTaskManager.stopBackgroundRunning(this.context).then(() => {
      console.info(TAG, `Succeeded in operationing stopBackgroundRunning.`);
    }).catch((err: BusinessError) => {
      console.error(TAG, `Failed to operation stopBackgroundRunning. Code is ${err.code}, message is ${err.message}`);
    });
  }

  build() {
    Row() {
      Column() {
        Text('Index')
          .fontSize(50)
          .fontWeight(FontWeight.Bold)


        Button() {
          Text('申请长时任务').fontSize(25).fontWeight(FontWeight.Bold)
        }
        .type(ButtonType.Capsule)
        .margin({ top: 10 })
        .backgroundColor('#0D9FFB')
        .width(250)
        .height(40)
        .onClick(() => {
          // 通过按钮申请长时任务
          this.startContinuousTask();
        })


        Button() {
          Text('取消长时任务').fontSize(25).fontWeight(FontWeight.Bold)
        }
        .type(ButtonType.Capsule)
        .margin({ top: 10 })
        .backgroundColor('#0D9FFB')
        .width(250)
        .height(40)
        .onClick(() => {
          // 此处结束具体的长时任务的执行


          // 通过按钮取消长时任务
          this.stopContinuousTask();
        })


        Button() {
          Text('调用AI文本生成语音').fontSize(25).fontWeight(FontWeight.Bold)
        }
        .type(ButtonType.Capsule)
        .margin({ top: 10 })
        .backgroundColor('#0D9FFB')
        .width(250)
        .height(40)
        .onClick(() => {
          // 通过按钮注册长时任务取消回调
          // this.OnContinuousTaskCancel();
          this.requestId++;
          this.AISpeech('你好 我是华为智能机器人', this.requestId + '')
        })


        Button() {
          Text('取消注册长时任务取消回调').fontSize(25).fontWeight(FontWeight.Bold)
        }
        .type(ButtonType.Capsule)
        .margin({ top: 10 })
        .backgroundColor('#0D9FFB')
        .width(250)
        .height(40)
        .onClick(() => {
          // 通过按钮取消注册长时任务取消回调
          this.OffContinuousTaskCancel();
        })
      }
      .width('100%')
    }
    .height('100%')
  }
}