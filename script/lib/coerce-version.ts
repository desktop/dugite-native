// Coerces a version string to ensure it starts with 'v' or is 'latest'
// Because I always forget to type v2.x.y when specifying versions
export const coerceVersionPrefix = (version: string): string =>
  version === 'latest' || version.startsWith('v') ? version : `v${version}`
