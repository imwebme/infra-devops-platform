import { createLogger, format, transports } from 'winston'
const { combine, printf } = format

const productionLogger = () => {
  return createLogger({
    level: 'info',
    exitOnError: false,
    format: combine(
      format.label({
        label: 'LOGGER',
      }),
      printf((info) => {
        if (info.level !== 'error') {
          return JSON.stringify(info)
        }

        const newInfo = {
          ...info,
          ...((info.message || info.stack) && {
            error: {
              ...(info.message && { message: info.message }),
              ...(info.stack && { stack: info.stack }),
            },
          }),
        }

        if (info.message === 'Document not found') {
          return ''
        }

        return JSON.stringify(newInfo)
      }),
    ),
    transports: [new transports.Console()],
  })
}

export default productionLogger
