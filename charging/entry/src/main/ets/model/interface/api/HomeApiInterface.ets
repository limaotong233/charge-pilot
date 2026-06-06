export interface StationListVO {
  currentPage: number,
  pageSize: number,
  stationName: string,
  chargeType: number | null,
  sortBy: string | null,
  latitude: number | null,
  longitude: number | null
}

export interface StationListReturning {
  total: number,
  list: Array<StationListItemReturning>
}

export interface StationListItemReturning {
  stationId: string,
  stationName: string,
  latitude: number
  longitude: number,
  chargeType: number,
  portCount: number,
  chargeFee: number,
  chargePower: number,
  usedCount: number,
  isCollect: number,
  distance: number,
  fileCode: string | null,
  delFlag: number
}

export interface StationDetailVO {
  stationId: string
}

export interface StationDetailReturning {
  stationId: string,
  stationName: string,
  stationType: number,
  latitude: number
  longitude: number,
  chargeType: number,
  portCount: number,
  chargeFee: number,
  chargePower: number,
  usedCount: number,
  serviceProvider: string,
  openTime: string,
  invoiceType: string,
  paymentMethod: string,
  isCollect: number,
  distance: number,
  fileCode: string
}

export interface StationPortListReturning {
  portId: string,
  portName: string,
  stationId: string,
  stationName: string,
  chargeFee: number,
  chargePower: number,
  serviceProvider: string,
  openTime: string,
  invoiceType: string,
  paymentMethod: string
  reserveTime: string,
  portStatus: number
}

export interface EnterDetailVO {
  id: string
}

export interface EnterDetailItem {
  id: string,
  portId: string,
  portName: string,
  stationId: string,
  stationName: string,
  chargeFee: number,
  chargePower: number,
  chargeType: number,
  enterTime: Date,
  latitude: number,
  longitude: number
}