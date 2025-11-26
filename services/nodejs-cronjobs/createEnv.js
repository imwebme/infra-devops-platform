const CryptoJS = require('crypto-js')
const fs = require('fs')

const args = process.argv.slice(2)
const encrypted = args[0]
const passphrase = args[1]

if (!encrypted || !passphrase) {
  console.log('Usage: node createEnv.js <encrypted_text> <passphrase>.')
  process.exit(1)
}

const bytes = CryptoJS.AES.decrypt(encrypted, passphrase)
const decrypted = bytes.toString(CryptoJS.enc.Utf8)

fs.writeFile('.env', decrypted, (err) => {
  if (err) {
    console.error('Error writing to file', err)
    process.exit(1)
  }
  console.log(`Decrypted content written to env`)
})
