import { createApp } from './app'
import { readServerEnv } from './config/env'

const env = readServerEnv()
const app = createApp()

app.listen(env.port, env.host, () => {
  console.log(`ContractScanner server listening on http://${env.host}:${env.port}`)
})
