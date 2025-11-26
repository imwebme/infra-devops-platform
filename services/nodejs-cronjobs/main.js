/* eslint-disable no-restricted-globals */
/* eslint-disable no-control-regex */
const tracer = require('dd-trace').init()
const configs = require('./src/utils/configs')
const winstonLogger = require('./src/utils/logger')
const Client = require('./src/utils/mongodb/mongodbCommon')
const { sleep } = require('./src/utils/common')
const moment = require('moment')
const axios = require('axios')

require('moment-timezone')

moment.tz.setDefault('Asia/Seoul')

const { slackWebhookUrl, enableSlack } = configs
let logType = 'info'

const allowedServices = [
  'OrderService',
  'UserService',
  'SellerService',
  'ItemService',
  'GameService',
  'AdService',
  'CrawlService',
  'EmailService',
  'HealthCheckService',
  'ShortsNotificationService',
  'DailyCheckInService',
  'AlluluService',
  'CommonService',
  'AlgameService',
  'ToonService',
  'AppLovinService',
  'AlttoService',
  'TestService',
  'MonitorService',
  'BiddingService',
  'DramaService',
  'SkuCatalogService',
  'BiddingService',
  'ShopinDataService',
]

const [, , log, ...functionStrs] = process.argv

// Handle process signals to ensure MongoDB connections are closed
process.on('beforeExit', (code) => {
  closeMongoConnections()
  console.log('beforeExit:', code)
})
process.on('exit', (code) => {
  closeMongoConnections()
  console.log('exit:', code)
})
process.on('uncaughtException', (err) => {
  closeMongoConnections()
  console.log('uncaughtException:', err)
})
process.on('SIGINT', (code) => {
  console.log('SIGINT:', code)
  closeMongoConnections()
  process.exit(0)
})
process.on('SIGTERM', (code) => {
  console.log('SIGTERM:', code)
  closeMongoConnections()
  process.exit(0)
})

async function executeFunction(service, serviceName, functionName, args) {
  // const parsedArgs = args.map(parseSingleArg)
  if (typeof service[functionName] === 'function') {
    await service[functionName](...args)
  } else {
    throw new Error(`Unknown function: ${serviceName}.${functionName}`)
  }
}

async function executeFunctions() {
  const results = initializeResultsArray()

  try {
    await runServiceFunctions(results)
  } finally {
    await closeMongoConnections()

    await sendSlackMessage(results.join('\n'), logType)
  }
  await sleep(3000)
  process.exit(0)
}

function initializeResultsArray() {
  const results = new Array(functionStrs.length).fill('')
  results.unshift(`*[⏰] CronJob 실행(${log})*`)
  return results
}

async function runServiceFunctions(results) {
  for (let i = 0; i < functionStrs.length; i += 1) {
    const functionStr = functionStrs[i]
    const [serviceName, functionName, ...args] = parseFunctionArgs(functionStr)

    if (!allowedServices.includes(serviceName)) {
      await sendSlackMessage(
        `[❌] Unknown or unallowed service: ${serviceName}`,
        'error',
      )
      process.exit(1)
    }

    const Service = require(`./src/services/${serviceName}`)

    try {
      await executeFunction(Service, serviceName, functionName, args)
      results[i + 1] = `[✅] ${serviceName}.${functionName}(${args.join(', ')})`
    } catch (error) {
      results[i + 1] = `[❌] ${serviceName}.${functionName}(${args.join(
        ', ',
      )}): ${error.stack}`
      logType = 'error'
      break
    }
  }
  fillSkippedFunctions(results)
}

function fillSkippedFunctions(results) {
  for (let i = 0; i < results.length; i += 1) {
    if (results[i] === '') {
      results[i] = `[❌] ${functionStrs[i - 1]}: Skipped due to previous error`
    }
  }
}

async function sendSlackMessage(
  message,
  type = 'info',
  maxRetries = 3,
  retryDelay = 3000,
) {
  const timestamp = new Date().toLocaleString('en-US', {
    timeZone: 'Asia/Seoul',
  })

  winstonLogger.info(message)

  if (enableSlack && type === 'error') {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        const response = await axios.post(slackWebhookUrl, {
          text: `*[${timestamp}]* | *[${type}]* | ${message}`,
        })
        if (response.status === 200) {
          console.log('Message sent successfully')
          return
        }
        console.log(`Failed to send message, status code: ${response.status}`)
      } catch (error) {
        console.log(`Attempt ${attempt} failed: ${error}`)
        if (attempt < maxRetries) {
          console.log(`Retrying in ${retryDelay}ms...`)
          await sleep(retryDelay / 1000)
        } else {
          console.error('Failed to send message after all retries')
        }
      }
    }
  }
}

async function closeMongoConnections() {
  try {
    await Client.closeAll()
    console.log('MongoDB connections closed')
  } catch (error) {
    console.error('Failed to close MongoDB connections:', error)
  }
}

function parseFunctionArgs(input) {
  // 정규 표현식을 사용하여 서비스 이름, 함수 이름과 괄호 안의 값을 분리
  const regex = /^(\w+)\.(\w+)\((.*)\)$/
  const match = input.match(regex)

  if (!match) {
    sendSlackMessage(
      `[❌] Input string is not in the expected format: ${input}`,
      'error',
    )
  }

  const serviceName = match[1]
  const funcName = match[2]
  const argsString = match[3]

  // 문자열을 분석하여 인수들을 추출
  const args = []
  let currentArg = ''
  let insideString = false
  let insideObjectOrArray = 0

  for (let i = 0; i < argsString.length; i += 1) {
    const char = argsString[i]

    if (char === "'" && insideObjectOrArray === 0) {
      insideString = !insideString
      currentArg += char
    } else if ((char === '{' || char === '[') && !insideString) {
      insideObjectOrArray += 1
      currentArg += char
    } else if ((char === '}' || char === ']') && !insideString) {
      insideObjectOrArray -= 1
      currentArg += char
    } else if (char === ',' && !insideString && insideObjectOrArray === 0) {
      args.push(currentArg.trim())
      currentArg = ''
    } else {
      currentArg += char
    }
  }

  if (currentArg) {
    args.push(currentArg.trim())
  }

  // 각 인수를 적절한 타입으로 변환
  const parsedArgs = args.map((arg) => {
    if (/^\d+$/.test(arg)) {
      return parseInt(arg, 10)
    }
    if (/^'.*'$/.test(arg)) {
      return arg.slice(1, -1)
    }
    if (/^\{.*\}$/.test(arg) || /^\[.*\]$/.test(arg)) {
      // 작은따옴표를 큰따옴표로 변환하고, 객체의 키에도 큰따옴표를 추가
      const jsonString = arg.replace(/'/g, '"').replace(/(\w+):/g, '"$1":')
      return JSON.parse(jsonString)
    }
    if (/^(true|false)$/.test(arg)) {
      return arg === 'true' || arg === true
    }
    sendSlackMessage(`[❌] Unknown argument format: ${arg}`, 'error')
    return arg
  })

  return [serviceName, funcName, ...parsedArgs]
}

executeFunctions()
