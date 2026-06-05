export interface routePlanningCarInfoItem {
  mileageNumber: number,
  capacity: number,
  startSOCValue: number,
  endSOCValue: number
}

export interface routePlanningParamsInfo {
  keyWord: string,
  startOrEnd: string,
  isSwitch: boolean
}

export interface addressComponent {
  countryName: string,
  adminLevel1: string,
  adminLevel2: string,
  adminLevel3: string,
  adminLevel4: string,
}

export interface location {
  latitude: number,
  longitude: number
}