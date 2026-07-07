export interface ServerEnv {
  port: number
  host: string
}

const DEFAULT_PORT: number = 3000
const DEFAULT_HOST: string = '0.0.0.0'

function parsePort(rawPort?: string): number {
  if (rawPort === undefined || rawPort.trim().length === 0) {
    return DEFAULT_PORT
  }

  const parsed = Number(rawPort)
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return DEFAULT_PORT
  }

  return Math.floor(parsed)
}

export function readServerEnv(): ServerEnv {
  return {
    port: parsePort(process.env.PORT),
    host: process.env.HOST?.trim().length ? process.env.HOST : DEFAULT_HOST
  }
}
