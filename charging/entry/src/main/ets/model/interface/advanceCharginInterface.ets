export interface orderlyPileItem {
  siteName: string,
  siteNumber: number
}

export interface orderlyPileErrorsItem {
  siteName?: string,
  siteNumber?: string
}

export interface carInfoItem {
  mileageNumber: number,
  capacity: number,
  socValue: number
}

export interface siteInfoFormItem {
  createTime: string,
  countCode: string,
  carName: string,
  advanceStartTime: string,
  advanceEndTime: string
}

export interface formItem {
  stationName: string,
  portName: string,

}

export interface formIndexItem {
  stationIndex: number,
  portIndex: number
}
