const moment = require('moment')
const bmoment = require('moment-business-days')
const configs = require('../utils/configs')

class TestService {
  constructor() {
    this.test = 'test'
  }

  async test1() {
    console.log(await `this.test${1}`)
    console.log(JSON.stringify(configs))
  }

  async test2() {
    console.log(await `this.test${2}`)
  }

  async test3(flag = false) {
    console.log(typeof flag, flag)
    console.log(await `this.test${3}`)
  }

  async test4(
    arg1 = 1,
    arg2 = [1, 1],
    arg3 = 2,
    arg4 = 3,
    arg5 = [{ a: '0', b: '10' }],
    arg6 = [{ c: '100' }],
    arg7,
    arg8,
  ) {
    console.log(`arg1: ${arg1}, typeof arg1: ${typeof arg1}`)
    console.log(`arg2: ${arg2}, typeof arg1: ${typeof arg2}`)
    console.log(`arg3: ${arg3}, typeof arg1: ${typeof arg3}`)
    console.log(`arg4: ${arg4}, typeof arg1: ${typeof arg4}`)
    console.log(`
      arg5[0].a: ${arg5[0].a}, 
      arg5[0].b: ${arg5[0].b}, 
      typeof arg1: ${typeof arg5}
      `)
    console.log(`arg5[0].a: ${arg6[0].c}, typeof arg1: ${typeof arg5}`)
    console.log(`arg6: ${arg6}, typeof arg1: ${typeof arg6}`)
    console.log(`arg7: ${arg7}, typeof arg1: ${typeof arg7}`)
    console.log(`arg8: ${arg8}, typeof arg1: ${typeof arg8}`)
    console.log(await `this.test${4}`)
  }

  async test5() {
    // moment.tz.setDefault('Etc/UTC')
    bmoment.updateLocale('us', {
      workingWeekdays: [1, 2, 3, 4, 5],
      holidayFormat: 'YYYY-MM-DD',
      holidays: [
        '2023-01-01',
        '2023-01-21',
        '2023-01-22',
        '2023-01-23',
        '2023-01-24',
        '2023-03-01',
        '2023-05-05',
        '2023-05-27',
        '2023-05-29', // 석가탄신일 대체공휴일
        '2023-06-06',
        '2023-08-15',
        '2023-09-28',
        '2023-09-29',
        '2023-09-30',
        '2023-10-03',
        '2023-10-09',
        '2023-12-25',
        '2024-01-01',
        '2024-02-09',
        '2024-02-12',
        '2024-03-01',
        '2024-04-10',
        '2024-04-30',
        '2024-05-01',
        '2024-05-02',
        '2024-05-06',
        '2024-05-14',
        '2024-05-15',
        '2024-05-16',
        '2024-06-06',
        '2024-08-15',
        '2024-09-16',
        '2024-09-17',
        '2024-09-18',
        '2024-10-03',
        '2024-10-09',
        '2024-12-25',
      ],
    })
    console.log(await `this.test${5}`)
    console.log(moment.tz.guess())
    console.log(`isBusinessDay: ${moment().isBusinessDay()}`)
    console.log(moment().format())
  }
}

module.exports = new TestService()
