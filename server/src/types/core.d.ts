import type { responseStatus } from '@/consts'
import type { Response } from 'express'

export type ResponseStatusType =
  (typeof responseStatus)[keyof typeof responseStatus]

export interface SendResponseArgs {
  res: Response
  message?: string
  data?: any
  pagination?: any
  status?: ResponseStatusType
  statusCode?: number
  error?: any
}

export type SuccessArgs = Pick<
  SendResponseArgs,
  'res' | 'message' | 'data' | 'pagination'
>
export type CreatedArgs = Pick<SendResponseArgs, 'res' | 'message' | 'data'>
export type AcceptedArgs = Pick<SendResponseArgs, 'res' | 'message' | 'data'>
export type NoContentArgs = Pick<SendResponseArgs, 'res' | 'message'>
