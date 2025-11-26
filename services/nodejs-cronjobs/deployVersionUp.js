const fs = require('fs')
const { deployVersion } = require('./deployVersion.json')

const currentDeployVersion = parseInt(deployVersion, 10)

fs.writeFileSync(
  './deployVersion.json',
  `{ "deployVersion": ${parseInt(currentDeployVersion + 1, 10)} }\n`,
)
