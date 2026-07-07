import { Router } from 'express'

import { getTaskStatus } from '../controllers/analysisController'

export const taskStatusRouter = Router()

taskStatusRouter.get('/tasks/:taskId/status', getTaskStatus)
