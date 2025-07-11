#!/bin/bash
NEW_RELIC_USER_KEY=${1:-KEY}
curl -X POST https://api.newrelic.com/graphql -H 'Content-Type: application/json' -H 'API-Key: '${NEW_RELIC_USER_KEY} --data @scripts/change_tracking.query