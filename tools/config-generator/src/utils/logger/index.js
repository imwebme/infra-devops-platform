import { transports, format } from 'winston'
import debugLogger from './debugLogger.js'
import productionLogger from './productionLogger.js'
import dotenv from 'dotenv'
dotenv.config()

const httpTransportOptions = {
  host: 'http-intake.logs.datadoghq.com',
  path: `/api/v2/logs?dd-api-key=${process.env.DATADOG_API_KEY}&ddsource=nodejs&service=${process.env.DD_SERVICE}&ddtags=env:${process.env.DD_ENV}`,
  ssl: true,
}

const httpTransport = new transports.Http({
  ...httpTransportOptions,
  level: 'info',
  format: format.json(),
})

let logger = debugLogger()

if (process.env.NODE_ENV === 'prod' && process.platform !== 'darwin')
  logger = productionLogger()

if (process.env.DATADOG_ENABLED_DEBUG === 'true') logger.add(httpTransport)

export default logger
