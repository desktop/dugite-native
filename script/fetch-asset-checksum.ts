import { createHash } from 'crypto'

export async function fetchAssetChecksum(uri: string) {
  const hs = createHash('sha256')

  const headers = {
    'User-Agent': 'dugite-native',
    accept: 'application/octet-stream',
  }

  await fetch(uri, { headers })
    .then(x =>
      x.ok
        ? Promise.resolve(x)
        : Promise.reject(new Error(`Server responded with ${x.status}`))
    )
    .then(x => x.arrayBuffer())
    .then(x => hs.end(Buffer.from(x)))

  return hs.digest('hex')
}
