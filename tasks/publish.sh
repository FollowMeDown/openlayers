#!/bin/bash

#
# Run this script to publish a new version of the library to npm.  This requires
# that you have a clean working directory and have created a tag that matches
# the version number in package.json.
#
set -o errexit

#
# All profiles to be built.  Must correspond to .json files in the config
# directory.
#
PROFILES="ol ol-debug"

#
# URL for canonical repo.
#
REMOTE=https://github.com/tschaub/ol3.git

#
# Display usage and exit.
#
display_usage() {
  cat <<-EOF

  Usage: ${1} <version>

  To publish a new release, update the version number in package.json and
  create a tag for the release.

  The tag name must match the version number prefixed by a "v" (for example,
  version 3.2.1 would be tagged v3.2.1).

  The tag must be pushed to ${REMOTE} before the release can be published.

EOF
  exit 1
}

#
# Exit if the current working tree is not clean.
#
assert_clean() {
  source `git --exec-path`/git-sh-setup && \
      require_clean_work_tree "publish" "Please commit or stash them."
}

#
# Exit if the requested version doesn't match package.json.
#
assert_version_match() {
  v=`grep -o '"version":.*' package.json | sed 's/"version": *"\(.*\)",/\1/'`
  if test "${1}" != "${v}"; then
    echo "Version mismatch: requested '${1}', but package.json specifies '${v}'"
    exit 1
  fi
}

#
# Build all of the distribution profiles.
#
build_profiles() {
  for p in ${@}; do
    echo building dist/${p}.js
    node ./tasks/build.js config/${p}.json dist/${p}.js
  done
}

#
# Check out the provided tag.  This ensures that the tag has been pushed to
# the canonical remote.
#
checkout_tag() {
  git fetch ${REMOTE} refs/tags/v${1}:refs/tags/v${1}
  git checkout refs/tags/v${1}
}

#
# Build all profiles and publish.
main() {
  root=$(cd -P -- "$(dirname -- "${0}")" && pwd -P)/..
  cd ${root}
  assert_clean
  checkout_tag ${1}
  assert_version_match ${1}
  rm -rf dist
  build_profiles ${PROFILES}
  npm publish
}

if test ${#} -ne 1; then
  display_usage ${0}
else
  main ${1}
fi