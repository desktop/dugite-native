const octokit = require("@octokit/rest")();

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

  const release = await octokit.repos.getLatestRelease({
    owner: "desktop",
    repo: "dugite-native"
  });

  console.log(`id: ${release.data.id}`);
  console.log(`tag name: ${release.data.tag_name}`);
  console.log(`draft: ${release.data.draft}`);

  const assets = await octokit.repos.getAssets({
    owner: "desktop",
    repo: "dugite-native",
    release_id: release.data.id
  });

  for (const asset of assets.data) {
    const { name, browser_download_url } = asset;
    if (name.endsWith(".sha256")) {
      const fileName = name.slice(0, -3);
      console.log(`found SHA256 file ${name} for ${fileName}`);
    } else {
      console.log(`skipping: ${name}`);
    }
  }
}

run();
