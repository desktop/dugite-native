const glob = require('glob')
const path = require('path')
const fs = require('fs')

module.exports = ({ github, context, artifactsDir, releaseId }) => {
  glob(artifactsDir + '/**/*', { nodir: true }, async function (err, files) {
    for (const file of files) {
      const filename = path.basename(file)
      console.log(`Uploading ${filename}`)

      await github.repos.uploadReleaseAsset({
        owner: context.repo.owner,
        repo: context.repo.repo,
        release_id: releaseId,
        name: filename,
        data: fs.readFileSync(file),
      })
    }
  })
}
