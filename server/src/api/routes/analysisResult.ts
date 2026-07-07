import { Router } from 'express'

import { getAnalysisResult } from '../controllers/analysisController'

export const analysisResultRouter = Router()

analysisResultRouter.get('/tasks/:taskId/result', getAnalysisResult)
