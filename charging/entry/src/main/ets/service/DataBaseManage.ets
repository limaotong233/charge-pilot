import distributedKVStore from '@ohos.data.distributedKVStore';

class DataBaseManage {
  instance?: distributedKVStore.KVManager;
  store?: distributedKVStore.SingleKVStore

  constructor(config: distributedKVStore.KVManagerConfig) {
    try {
      // 创建KVManager实例
      this.instance = distributedKVStore.createKVManager(config);
      console.info('Succeeded in creating KVManager.');
      // 继续创建获取数据库
    } catch (e) {
      console.error(`Failed to create KVManager. Code:${e.code},message:${e.message}`);
    }
  }

  createStore(key: string, options: distributedKVStore.Options) {
    try {
      // const options = {
      //   createIfMissing: true, // 当数据库文件不存在时是否创建数据库，默认创建
      //   encrypt: false, // 设置数据库文件是否加密，默认不加密
      //   backup: false, // 设置数据库文件是否备份，默认备份
      //   autoSync: true, // 设置数据库文件是否自动同步。默认为false，即手动同步；设置为true时，表示自动同步
      //   kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION, // 设置要创建的数据库类型，默认为多设备协同数据库
      //   securityLevel: distributedKVStore.SecurityLevel.S2 // 设置数据库安全级别
      // };
      // storeId为数据库唯一标识符
      if (!this.instance) {
        return Promise.reject('instance not exist')
      }
      return this.instance.getKVStore<distributedKVStore.SingleKVStore>(key, options).then((kvStore) => {
        this.store = kvStore
        return kvStore
      });
    } catch (e) {
      console.error(`An unexpected error occurred. Code:${e.code},message:${e.message}`);
      return Promise.reject(e)
    }
  }

  put(key: string, value: Uint8Array | string | number | boolean | Object) {

    let localValue = value;
    if (localValue.toString() === '[object Object]') {
      localValue = JSON.stringify(localValue)
    }
    console.log('put localValue', localValue)
    if (!this.store) {
      return Promise.reject('store not exist')
    }
    try {
      return this.store.put(key, (localValue as Uint8Array | string | number | boolean));
    } catch (e) {
      console.error(`An unexpected error occurred. Code:${e.code},message:${e.message}`);
      return Promise.reject(e)
    }
  }

  async get(key: string): Promise<string | number | boolean | Uint8Array | Array<string>> {
    if (!this.store) {
      return Promise.reject('store not exist')
    }
    try {
      let localValue = await this.store.get(key);
      if (localValue.toString() === '[object String]' && /^({|\[)/.test(localValue as string)) {
        localValue = JSON.parse(localValue as string)
      }
      return localValue;
    } catch (e) {
      console.error(`Failed to get data. Code:${e.code},message:${e.message}`);
      return Promise.reject(e)
    }
  }

  delete(key: string) {
    if (!this.store) {
      return Promise.reject('store not exist')
    }
    try {
      return this.store.delete(key);
    } catch (e) {
      console.error(`An unexpected error occurred. Code:${e.code},message:${e.message}`);
      return Promise.reject(e)
    }
  }

  getStore() {
    return this.store;
  }
}

export { DataBaseManage }



