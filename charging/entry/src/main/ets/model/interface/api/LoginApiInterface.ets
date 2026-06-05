export interface formItem {
  account: string,
  password: string,
}

export interface formItem2 {
  v: string,
}

export interface avatarObject {
  fileAccessUrl: string
}

export interface userInfoReturning {
  account: string,
  userName: string,
  avatar: avatarObject
}

export interface userInfoImage {
  fileCode: string
}

export interface LoginResult {
  accessToken: string,
  refreshToken: string
}