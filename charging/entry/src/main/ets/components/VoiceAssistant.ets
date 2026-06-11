import { router } from '@kit.ArkUI'
import { speechRecognizer, textToSpeech } from '@kit.CoreSpeechKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { abilityAccessCtrl, common, Permissions, PermissionRequestResult } from '@kit.AbilityKit'
import { intentService, IntentResult } from '../service/IntentService'

@Component
export struct VoiceAssistant {
  @State isPanelOpen: boolean = false
  @State isListening: boolean = false
  @State recognizedText: string = ''
  @State responseText: string = ''
  @State sessionId: string = ''
  private asrEngine?: speechRecognizer.SpeechRecognitionEngine
  private ttsEngine?: textToSpeech.TextToSpeechEngine
  private uiContext?: UIContext

  aboutToAppear() {
    this.uiContext = this.getUIContext()
    this.initASR()
    this.initTTS()
  }

  // 检查并请求麦克风权限
  async checkMicPermission(): Promise<boolean> {
    const permission: Permissions = 'ohos.permission.MICROPHONE'
    try {
      const atManager = abilityAccessCtrl.createAtManager()
      const context = getContext(this) as common.UIAbilityContext
      const result: PermissionRequestResult = await atManager.requestPermissionsFromUser(context, [permission])
      return result.authResults[0] === 0
    } catch (e) {
      console.error('checkMicPermission error', JSON.stringify(e))
      return false
    }
  }

  aboutToDisappear() {
    if (this.asrEngine) {
      this.asrEngine.shutdown()
    }
  }

  // 初始化语音识别引擎
  initASR() {
    let extraParams: Record<string, Object> = {
      'locate': 'CN',
      'recognizerMode': 'short'
    }
    let initParamsInfo: speechRecognizer.CreateEngineParams = {
      language: 'zh-CN',
      online: 1,
      extraParams: extraParams
    }
    speechRecognizer.createEngine(initParamsInfo,
      (err: BusinessError, engine: speechRecognizer.SpeechRecognitionEngine) => {
        if (!err) {
          this.asrEngine = engine
          this.setASRListener()
        } else {
          console.error('ASR init failed', err.code, err.message)
        }
      })
  }

  // 设置语音识别监听
  setASRListener() {
    let that = this
    let listener: speechRecognizer.RecognitionListener = {
      onStart(sessionId: string, eventMessage: string) {
        console.info('ASR onStart', sessionId)
      },
      onEvent(sessionId: string, eventCode: number, eventMessage: string) {
        console.info('ASR onEvent', eventCode)
      },
      onResult(sessionId: string, result: speechRecognizer.SpeechRecognitionResult) {
        if (result.result && result.result.length > 0) {
          that.recognizedText = result.result
        }
        if (result.isFinal && result.isLast) {
          that.onRecognizeComplete(result.result)
        }
      },
      onComplete(sessionId: string, eventMessage: string) {
        console.info('ASR onComplete')
        that.isListening = false
      },
      onError(sessionId: string, errorCode: number, errorMessage: string) {
        console.error('ASR onError', errorCode, errorMessage)
        that.isListening = false
        that.responseText = '语音识别失败，请重试'
      }
    }
    this.asrEngine?.setListener(listener)
  }

  // 初始化语音合成引擎
  initTTS() {
    let extraParam: Record<string, Object> = {
      'style': 'interaction-broadcast', 'locate': 'CN', 'name': 'EngineName'
    }
    let initParamsInfo: textToSpeech.CreateEngineParams = {
      language: 'zh-CN',
      person: 0,
      online: 1,
      extraParams: extraParam
    }
    textToSpeech.createEngine(initParamsInfo,
      (err: BusinessError, engine: textToSpeech.TextToSpeechEngine) => {
        if (!err) {
          this.ttsEngine = engine
          let speakListener: textToSpeech.SpeakListener = {
            onStart(requestId: string, response: textToSpeech.StartResponse) {},
            onComplete(requestId: string, response: textToSpeech.CompleteResponse) {},
            onStop(requestId: string, response: textToSpeech.StopResponse) {},
            onData(requestId: string, audio: ArrayBuffer, response: textToSpeech.SynthesisResponse) {},
            onError(requestId: string, errorCode: number, errorMessage: string) {}
          }
          this.ttsEngine.setListener(speakListener)
        }
      })
  }

  // 语音播报
  speak(text: string) {
    if (this.ttsEngine) {
      let extraParam: Record<string, Object> = {
        'queueMode': 0, 'speed': 1, 'volume': 2, 'pitch': 1,
        'languageContext': 'zh-CN', 'audioType': 'pcm', 'soundChannel': 3, 'playType': 1
      }
      let speakParams: textToSpeech.SpeakParams = {
        requestId: `voice_${Date.now()}`,
        extraParams: extraParam
      }
      this.ttsEngine.speak(text, speakParams)
    }
  }

  // 开始语音识别（检查权限）
  async startListening() {
    if (!this.asrEngine) return
    const granted = await this.checkMicPermission()
    if (!granted) {
      this.responseText = '需要麦克风权限才能使用语音功能'
      return
    }
    this.isListening = true
    this.recognizedText = ''
    this.responseText = ''
    this.sessionId = `session_${Date.now()}`

    let recognizerParams: speechRecognizer.StartParams = {
      sessionId: this.sessionId,
      audioInfo: {
        audioType: 'pcm',
        sampleRate: 16000,
        soundChannel: 1,
        sampleBit: 16
      },
      extraParams: {
        'recognitionMode': 0,
        'vadBegin': 2000,
        'vadEnd': 800,
        'maxAudioDuration': 30000
      }
    }
    this.asrEngine.startListening(recognizerParams)
  }

  // 停止语音识别
  stopListening() {
    if (this.asrEngine && this.isListening) {
      this.asrEngine.finish(this.sessionId)
    }
  }

  // 识别完成，匹配意图
  onRecognizeComplete(text: string) {
    this.isListening = false
    const result: IntentResult | null = intentService.matchIntent(text)

    if (result) {
      this.responseText = result.response
      this.speak(result.response)
      // 延迟跳转，让用户看到反馈文字
      setTimeout(() => {
        this.isPanelOpen = false
        const navOptions: router.RouterOptions = { url: result.page }
        if (result.keyword) {
          navOptions.params = { keyword: result.keyword }
        }
        router.pushUrl(navOptions)
      }, 1500)
    } else {
      this.responseText = '抱歉，没有理解您的指令'
      this.speak('抱歉，没有理解您的指令，请再说一次')
    }
  }

  // 切换面板
  togglePanel() {
    this.isPanelOpen = !this.isPanelOpen
    if (!this.isPanelOpen && this.isListening) {
      this.stopListening()
    }
  }

  build() {
    if (this.isPanelOpen) {
      // 全屏遮罩 + 面板
      Stack({ alignContent: Alignment.BottomStart }) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.3)')
          .onClick(() => {
            this.togglePanel()
          })

        Column() {
          Row() {
            Text('语音助手')
              .fontSize('16lpx')
              .fontWeight(FontWeight.Bold)
            Blank()
            Text('✕')
              .fontSize('18lpx')
              .fontColor('#999999')
              .onClick(() => {
                this.togglePanel()
              })
          }
          .width('100%')
          .padding({ left: '16lpx', right: '16lpx', bottom: '16lpx' })

          Column() {
            if (this.isListening) {
              Row() {
                Column()
                  .width('8lpx')
                  .height('8lpx')
                  .borderRadius('4lpx')
                  .backgroundColor('#FF4444')
                  .animation({
                    duration: 800,
                    iterations: -1,
                    curve: Curve.EaseInOut
                  })
                Text('正在聆听...')
                  .fontSize('14lpx')
                  .fontColor('#FF4444')
                  .margin({ left: '8lpx' })
              }
            }

            if (this.recognizedText.length > 0) {
              Text(this.recognizedText)
                .fontSize('16lpx')
                .fontColor('#333333')
                .margin({ top: '12lpx' })
                .width('100%')
                .textAlign(TextAlign.Center)
            }

            if (this.responseText.length > 0) {
              Text(this.responseText)
                .fontSize('14lpx')
                .fontColor('#4f6ef7')
                .margin({ top: '12lpx' })
                .width('100%')
                .textAlign(TextAlign.Center)
            }
          }
          .width('100%')
          .constraintSize({ minHeight: '80lpx' })
          .justifyContent(FlexAlign.Center)

          Column() {
            Text('可以说：')
              .fontSize('12lpx')
              .fontColor('#999999')
              .margin({ bottom: '8lpx' })
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
              ForEach(['搜索充电站', '开始充电', '查看订单', '路线规划', '充电统计', '停止充电'],
                (tag: string) => {
                  Text(tag)
                    .fontSize('12lpx')
                    .fontColor('#4f6ef7')
                    .padding({
                      left: '12lpx',
                      right: '12lpx',
                      top: '6lpx',
                      bottom: '6lpx'
                    })
                    .borderRadius('16lpx')
                    .backgroundColor('#F0F4FF')
                    .margin({ left: '4lpx', right: '4lpx', bottom: '8lpx' })
                    .onClick(() => {
                      this.recognizedText = tag
                      this.onRecognizeComplete(tag)
                    })
                })
            }
            .width('100%')
          }
          .width('100%')
          .margin({ top: '20lpx' })

          Row() {
            Text(this.isListening ? '松开结束' : '按住说话')
              .fontSize('16lpx')
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
          }
          .width('200lpx')
          .height('48lpx')
          .borderRadius('24lpx')
          .backgroundColor(this.isListening ? '#FF4444' : '#4f6ef7')
          .justifyContent(FlexAlign.Center)
          .margin({ left: '16lpx', top: '16lpx' })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              if (!this.isListening) {
                this.startListening()
              }
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              if (this.isListening) {
                this.stopListening()
              }
            }
          })
        }
        .width('100%')
        .padding({ top: '16lpx', left: '16lpx', right: '16lpx', bottom: '32lpx' })
        .borderRadius({ topLeft: '16lpx', topRight: '16lpx' })
        .backgroundColor(Color.White)
        .position({ bottom: '0lpx' })
        .zIndex(2)
      }
      .width('100%')
      .height('100%')
      .zIndex(999)
    } else {
      // 仅悬浮按钮（不阻挡页面交互）
      Column() {
        Text('MIC')
          .fontSize('12lpx')
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width('52lpx')
      .height('52lpx')
      .borderRadius('26lpx')
      .backgroundColor('#4f6ef7')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .shadow({
        radius: 12,
        color: 'rgba(79, 110, 247, 0.4)',
        offsetX: 0,
        offsetY: 4
      })
      .position({ left: '16lpx', bottom: '80lpx' })
      .zIndex(999)
      .onClick(() => {
        this.togglePanel()
      })
    }
  }
}
