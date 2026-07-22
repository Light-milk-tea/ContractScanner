import { Router } from 'express'

import { askContractQuestion } from '../controllers/chatController'

export const chatRouter = Router()

chatRouter.post('/tasks/:taskId/chat', (request, response) => {
  void askContractQuestion(request, response)
})
