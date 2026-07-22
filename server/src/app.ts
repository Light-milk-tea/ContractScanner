import express, { Express, Request, Response } from 'express'

import { analysisResultRouter } from './api/routes/analysisResult'
import { chatRouter } from './api/routes/chat'
import { taskStatusRouter } from './api/routes/taskStatus'
import { uploadRouter } from './api/routes/upload'

export function createApp(): Express {
  const app = express()

  app.use(express.json())

  app.get('/health', (_request: Request, response: Response) => {
    response.json({
      status: 'ok',
      service: 'contract-scanner-server'
    })
  })

  app.use('/v1', uploadRouter)
  app.use('/v1', taskStatusRouter)
  app.use('/v1', analysisResultRouter)
  app.use('/v1', chatRouter)

  app.use((_request: Request, response: Response) => {
    response.status(404).json({
      code: 'SYS_404',
      message: 'Route not found'
    })
  })

  return app
}
