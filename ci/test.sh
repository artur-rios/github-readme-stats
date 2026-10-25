#!/bin/sh
# POSIX sh, not bash: the Alpine image has no bash. No pipes, so pipefail is not missed.
# The check of the old test.yml workflow (Perform tests): install, test, lint, bench tests, Prettier. The Codecov
# upload step is not ported: it needs Codecov's token, which this setup does not hold.
set -eu

npm ci
npm run test
npm run lint
npm run bench
npm run format:check
