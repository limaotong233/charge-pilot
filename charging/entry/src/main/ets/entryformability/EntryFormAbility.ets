import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { LocalPreferences } from '../service/LocalPreferences'
import { getReserveDetail } from '../api/AdvanceChargingApi'
import { CardService, CardFormData } from '../service/Card'
import { ReserveDetailReturning } from '../model/interface/api/AdvanceChargingApiInterface'

const TAG = 'EntryFormAbility-local'

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    // Called to return a FormBindingData object.
    let formData = '';
    return formBindingData.createFormBindingData(formData);
  }

  onCastToNormalForm(formId: string) {
    // Called when the form provider is notified that a temporary form is successfully
    // converted to a normal form.
  }

  onUpdateForm(formId: string) {
    // Called to notify the form provider to update a specified form.
    console.log(TAG, `FormAbility onUpdateForm, formId = ${formId}`);
    LocalPreferences.init(this.context, {
      name: 'myStore'
    })
    this.requestRemoteDate();
  }

  onFormEvent(formId: string, message: string) {
    console.log(TAG, `FormAbility onFormEvent, formId = ${formId}, message: ${JSON.stringify(message)}`);
  }

  requestRemoteDate() {
    let carFormDate: CardFormData = {
      name: '', // 和卡片布局中对应
      pileNum: '', // 和卡片布局中对应
      status: '',
      beginTime: '',
      endTime: '',
    }
    console.log(TAG, '开始调用 requestRemoteDate')
    getReserveDetail<ReserveDetailReturning>({ id: '' }).then((res) => {
      console.info(TAG, '接口 用户预约信息', JSON.stringify(res))
      if (res) {
        carFormDate = {
          name: res.stationName, // 和卡片布局中对应
          pileNum: res.portName.split('-')[1], // 和卡片布局中对应
          status: res.portStatus === 0 ? '闲' : '忙',
          beginTime: res.startTime + '',
          endTime: res.endTime + '',
        }
      }
      this.setCardData(carFormDate)
    }).catch((err: Error) => {
      console.log(TAG, '调用失败 getReserveDetail')
    })
  }

  setCardData(carFormDate: CardFormData) {
    let formID = LocalPreferences.get('formId')
    console.log(TAG, `LocalPreferences FormExtensionAbility ${formID}`)
    if (formID) {
      CardService.setCardData(carFormDate, formID + '')
    }
  }

  onRemoveForm(formId: string) {
    // Called to notify the form provider that a specified form has been destroyed.
  }

  onAcquireFormState(want: Want) {
    // Called to return a {@link FormState} object.
    return formInfo.FormState.READY;
  }
};