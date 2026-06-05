import { formBindingData, formProvider } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'FormAbility'

export interface CardFormData {
  name: string, // 和卡片布局中对应
  pileNum: string, // 和卡片布局中对应
  status: string,
  beginTime: string,
  endTime: string,
}

export class CardService {
  private static cardStatus: string = ''

  static setCardData(formData: CardFormData, formId: string) {
    let formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    formProvider.updateForm(formId, formInfo).then(() => {
      console.log(TAG, 'FormAbility updateForm success.');
    }).catch((error: BusinessError) => {
      console.log(TAG, `Operation updateForm failed. Cause: ${JSON.stringify(error)}`);
    })
  }

  static setCardStatus(status: string) {
    CardService.cardStatus = status
  }

  static getCardStatus() {
    return CardService.cardStatus
  }
}