const octokit = require("@octokit/rest")();

// five targeted OS/arch combinations
// two files for each targeted OS/arch
// two checksum files for the previous
const SUCCESSFUL_RELEASE_FILE_COUNT = 5 * 2 * 2;

process.on("unhandledRejection", (reason, p) => {
  console.log("Unhandled Rejection, reason:", reason);
});

async function run() {
  if (process.env.GITHUB_ACCESS_TOKEN == null) {
    throw new Error("No GITHUB_ACCESS_TOKEN environment variable set");
  }

  octokit.authenticate({
    type: "token",
    token: process.env.GITHUB_ACCESS_TOKEN
  });

  const user = await octokit.users.get();
  const me = user.data.login;

  console.log(`✅ token found for ${me}...`);
  const foundScopes = user.headers["x-oauth-scopes"];
  if (foundScopes.indexOf("public_repo") === -1) {
    throw new Error(
      `Found GITHUB_ACCESS_TOKEN does not have required scope 'public_repo' which is required to read draft releases on dugite-native`
    );
  }

  console.log(
    `✅ token has 'public_scope' scope to make changes to releases...`
  );

  const releases = await octokit.repos.getReleases({
    owner: "desktop",
    repo: "dugite-native",
    per_page: 1,
    page: 1
  });

  const release = releases.data[0];

  console.log(`id: ${release.id}`);
  console.log(`tag name: ${release.tag_name}`);
  console.log(`draft: ${release.draft}`);

  const tag = release.tag_name;

  if (release.draft === false) {
    throw new Error(
      `Latest published release ${tag} is not a draft. Aborting...`
    );
  }

  const assets = await octokit.repos.getAssets({
    owner: "desktop",
    repo: "dugite-native",
    release_id: release.id
  });

  if (assets.data.length !== SUCCESSFUL_RELEASE_FILE_COUNT) {
    throw new Error(
      `Latest draft release ${tag} has ${
        assets.data.length
      } files, expecting ${SUCCESSFUL_RELEASE_FILE_COUNT}. The builds are probably still going. Aborting...`
    );
  }

  const entries = [];

  for (const asset of assets.data) {
    const { name, browser_download_url } = asset;
    if (name.endsWith(".sha256")) {
      const fileName = name.slice(0, -3);
      console.log(`found SHA256 file ${name} for ${fileName}`);
      const checksum = downloadFile(browser_download_url);
      entries.push({ fileName, checksum });
    } else {
      console.log(`skipping file: ${name}`);
    }
  }

  const fileList = entries.map(e => `| ${e.fileName} | ${e.checksum} |`);
  const fileListText = fileList.join("\n");
  const draftReleaseNotes = `{details about what's changed since the last release}

| File | SHA256 checksum |
| --- | --- |
${fileListText}`;

  console.log(`draft release: ${draftReleaseNotes}`);
}

run();
