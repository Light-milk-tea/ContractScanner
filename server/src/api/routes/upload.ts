import { Router } from 'express'

import { uploadContract } from '../controllers/analysisController'

export const uploadRouter = Router()

uploadRouter.post('/contracts/analyze', uploadContract)
