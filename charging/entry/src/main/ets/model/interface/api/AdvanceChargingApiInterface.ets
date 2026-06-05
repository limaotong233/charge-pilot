export interface BindDetailReturning {
  id: string,
  userId: string,
  stationId: string,
  portId: string,
  stationName: string,
  portName: string
}

export interface UnbindVO {
  id: string
}

export interface BindVO {
  stationName: string
  portName: string
}

export interface ReserveAddVO {
  stationId: string,
  portId: string,
  startTime: string,
  endTime: string,
  socValue: number
}

export interface ReserveCancelVO {
  reserveId: string,
}

export interface ReserveDetailReturning {
  reserveId: string,
  stationId: string,
  portId: string,
  stationName: string
  portName: string
  startTime: string | null,
  endTime: string | null,
  createdTime: Date | null,
  portStatus: number | null,
  defferTime: number | null
}

export interface StationNameListVO {
  stationName: string
  pageSize:number
  currentPage:number
}

interface StationName{
  stationId: string,
  stationName: string,
}

export interface StationNameListItem {
  list: StationName []
}

export interface filteredOptionItem {
  value: string,
  stationId: string,
  stationName: string,
}

export interface PortNameListVO {
  stationId: string
}

export interface PortNameListItem {
  portId: string,
  portName: string,
}

export interface filteredPortOptionItem {
  value: string,
  portId: string,
  portName: string,
}

