import { DataBaseManage } from './DataBaseManage'
import distributedKVStore from '@ohos.data.distributedKVStore';


class DataBaseService {
  static __instance: DataBaseManage

  static createInstance(config: distributedKVStore.KVManagerConfig) {
    if (DataBaseService.__instance) {
      return DataBaseService.__instance
    }
    return DataBaseService.__instance = new DataBaseManage(config)
  }

  static getInstance() {
    return DataBaseService.__instance
  }
}

export {
  DataBaseService
}
