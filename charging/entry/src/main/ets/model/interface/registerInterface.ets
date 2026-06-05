export interface RegisterFormItem {
  account: string,
  userName: string,
  password: string,
  confirmPassword: string
}

export interface RegisterErrorsItem {
  account?: string,
  userName?: string,
  password?: string,
  confirmPassword?: string
}
