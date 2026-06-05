import { mapCommon, navi } from '@kit.MapKit';
import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { buffer, url } from '@kit.ArkTS';
import { useToastHook } from '../service';
import { downLoadFile } from '../api/CollectionApi';

//计算两点之间直线距离 origins:mapCommon.LatLng[],
export const getDistance = async (destinations: mapCommon.LatLng[]) => {

  let location = await geoLocationManager.getCurrentLocation();
  let params: navi.DrivingMatrixParams = {
    'origins': [location],
    'destinations': destinations,
    'language': 'zh_CN'
  }

  return await navi.getDrivingMatrix(params).then((result) => {
    console.log('接口 getDrivingMatrix success', JSON.stringify(result))
    return result.rows
  }).catch((err: BusinessError) => {
    console.log('接口 getDrivingMatrix error', JSON.stringify(err))
  })
}

export const createObjectURL = (blob: ArrayBuffer, mimeType: string) => {
  const base64 = buffer.from(blob).toString('base64')
  return `data:${mimeType};base64,${base64}`
}
