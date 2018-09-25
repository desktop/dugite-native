const octokit = require("@octokit/rest")();
const rp = require("request-promise");

// five targeted OS/arch combinations
// two files for each targeted OS/arch
// two checksum files for the previous
const SUCCESSFUL_RELEASE_FILE_COUNT = 5 * 2 * 2;

process.on("unhandledRejection", reason => {
  console.log(reason);
});

async function run() {
  const token = process.env.GITHUB_ACCESS_TOKEN;
  if (token == null) {
    throw new Error("No GITHUB_ACCESS_TOKEN environment variable set");
  }

  octokit.authenticate({
    type: "token",
    token
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
  const { tag_name, draft, id } = release;

  if (!draft) {
    throw new Error(
      `Latest published release ${tag_name} is not a draft. Aborting...`
    );
  }

  console.log(`✅ Latest release ${tag_name} is a draft...`);

  const assets = await octokit.repos.getAssets({
    owner: "desktop",
    repo: "dugite-native",
    release_id: id
  });

  if (assets.data.length !== SUCCESSFUL_RELEASE_FILE_COUNT) {
    throw new Error(
      `Draft has ${
        assets.data.length
      } assets, expecting ${SUCCESSFUL_RELEASE_FILE_COUNT}. This means the build agents are probably still going. Aborting...`
    );
  }

  const entries = [];

  for (const asset of assets.data) {
    const { name, url } = asset;
    if (name.endsWith(".sha256")) {
      const fileName = name.slice(0, -7);
      const options = {
        url,
        headers: {
          Accept: "application/octet-stream",
          "User-Agent": "dugite-native",
          Authorization: `token ${token}`
        },
        secureProtocol: "TLSv1_2_method"
      };

      const fileContents = await rp(options);
      const checksum = fileContents.trim();
      entries.push({ fileName, checksum });
    }
  }

  const fileList = entries.map(e => `| ${e.fileName} | ${e.checksum} |`);
  const fileListText = fileList.join("\n");
  const draftReleaseNotes = `**TODO:** details about what's changed since the last release

| File | SHA256 checksum |
| --- | --- |
${fileListText}`;

  console.log(`✅ Draft for latest release ${tag_name}:`);
  console.log(draftReleaseNotes);

  // TODO: ask user if they want to update it on GitHub

  const numberWithoutPrefix = tag_name.substring(1);

  const result = await octokit.repos.editRelease({
    owner: "desktop",
    repo: "dugite-native",
    release_id: id,
    tag_name,
    name: `Git ${numberWithoutPrefix}`,
    body: draftReleaseNotes
  });

  const { html_url } = result.data;

  console.log(
    `✅ Draft for release ${tag_name} updated. Visit ${html_url} to add changelog and publish...`
  );
}

run();
