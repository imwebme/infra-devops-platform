import { createLogger, format, transports } from 'winston'
const { combine, timestamp, printf } = format

const consoleTransport = new transports.Console({
  format: combine(
    format.colorize({
      all: true,
    }),
    timestamp({
      format: 'YYYY-MM-DD HH:mm:ss',
    }),
    printf((info) => {
      const { timestamp, level, message, statusCode, stack, label } = info

      if (/http/.test(level)) {
        const parsedMessage = JSON.parse(message)
        return `${timestamp} [${label}] ${level}: ${parsedMessage.method} ${parsedMessage.url}`
      }
      if (/error/.test(level)) {
        return `${timestamp} [${label}] ${level}: ${
          statusCode ?? ''
        }${message}\n${stack ?? ''}`
      }
      return `${timestamp} [${label}] ${level}: ${message}`
    }),
  ),
})

const loggerTransports = [consoleTransport]

const logger = () => {
  return createLogger({
    level: 'debug',
    format: combine(
      format.errors({ stack: true }),
      format.label({
        label: 'LOGGER',
      }),
    ),
    transports: loggerTransports,
    handleExceptions: false,
    handleRejections: false,
  })
}

export default logger
