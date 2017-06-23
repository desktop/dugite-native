const AWS = require('aws-sdk')
const Path = require('path')
const Fs = require('fs')

const BucketName = process.env.ASSETS_S3_BUCKET

if (!BucketName) {
  console.error('No bucket name found in environment, exiting')
  process.exit(1)
  return
}

const AccessKey = process.env.ASSETS_S3_KEY

if (!AccessKey) {
  console.error('No access key found in environment, exiting')
  process.exit(1)
  return
}

const SecretAccessKey = process.env.ASSETS_S3_SECRET

if (!SecretAccessKey) {
  console.error('No secret access key found in environment, exiting')
  process.exit(1)
  return
}

function upload (assetPath, assetKey) {
  const s3Info = {accessKeyId: AccessKey, secretAccessKey: SecretAccessKey}
  const s3 = new AWS.S3(s3Info)

  const uploadParams = {
    Bucket: BucketName,
    ACL: 'public-read',
    Key: assetKey,
    Body: Fs.createReadStream(assetPath)
  }

  return new Promise((resolve, reject) => {
    s3.upload(uploadParams, (error, data) => {
      if (error) {
        reject(error)
      } else {
        resolve()
      }
    })
  })
}

const buildNo = process.env['TRAVIS_BUILD_NUMBER'] || process.env['APPVEYOR_BUILD_NUMBER']

if (!/\d+/.test(buildNo)) {
  throw new Error(`Invalid build number from environment: ${buildNo}`)
}

const assetPath = process.argv[2]
const assetName = Path.basename(assetPath)
const key = `dugite-native/builds/${buildNo}/${assetName}`
const url = `https://s3.amazonaws.com/${BucketName}/${key}`

if (!Fs.existsSync(assetPath)) {
  console.error('Asset path could not be found, exiting')
  process.exit(1)
  return
}

console.log(`Uploading ${assetName} to ${url}`)
upload(assetPath, key)
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
