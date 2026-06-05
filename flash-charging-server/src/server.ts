import app from './app'
import { config } from './config'

const PORT = config.port

app.listen(PORT, '0.0.0.0', () => {
  console.log(`闪充后端服务已启动: http://0.0.0.0:${PORT}`)
  console.log(`环境: ${config.nodeEnv}`)
})
