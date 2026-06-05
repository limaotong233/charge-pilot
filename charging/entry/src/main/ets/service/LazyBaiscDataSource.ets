import { StationListItemReturning } from '../model/interface/api/HomeApiInterface';

export class BasicDataSource implements IDataSource {
  totalCount(): number {
    throw new Error('Method not implemented.');
  }

  getData(index: number): string {
    throw new Error('Method not implemented.');
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    throw new Error('Method not implemented.');
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    throw new Error('Method not implemented.');
  }
}

export class MyDataSource extends BasicDataSource {
  private dataArray: StationListItemReturning[] = [];

  public totalCount(): number {
    return this.dataArray.length
  }

  public pushData(data: StationListItemReturning) {
    this.dataArray.push(data);
  }
}