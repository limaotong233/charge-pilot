export interface CollectionListVO {
  currentPage: number,
  pageSize: number,
  stationName: string
}

export interface CollectionListReturning {
  total: number,
  list: Array<CollectionListItem>
}

export interface CollectionListItem {
  id: string,
  stationId: string,
  stationName: string,
  stationType: number,
  chargeType: number,
  latitude: number
  longitude: number,
  chargeFee: number,
  portCount: number,
  chargePower: number,
  usedCount: number,
  distance: number,
  isCollect: number,
  delFlag: number,
  fileCode: string | null
}

export interface AddCollectVO {
  stationId: string
}
export interface downLoadFileVO {
  fileCode: string
}
