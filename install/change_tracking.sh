#!/bin/bash
NEW_RELIC_ACCOUNT_ID=${1:-KEY}
NEW_RELIC_USER_KEY=${2:-KEY}
NEW_RELIC_APP_NAME=${3:-DemoApp}
TAG=${4:-tag_raw}
cd /home/appuser/catalogue;
DESCRIPTION=$(git log --pretty=format:"%s" -n 1 | sed "s/'//g;s/\"//g;s/\// /g");
HASH=$(git log --pretty=format:"%H" -n 1);

ENTITY_GUID=$(curl -X POST https://api.newrelic.com/graphql -H 'Content-Type: application/json' -H 'API-Key: '${NEW_RELIC_USER_KEY} -d '{ "query": "{ actor { entitySearch(query: \"accountId='${NEW_RELIC_ACCOUNT_ID}' AND name='"'"${NEW_RELIC_APP_NAME}"'"' AND domain = '"'"'APM'"'"'\") { query results { entities { guid } } } } }"}'| jq -r '.data.actor.entitySearch.results.entities[0].guid')
cd /home/appuser/install;

sed "s/DESCRIPTION/${DESCRIPTION}/;s/TAG/${TAG}/;s/HASH/${HASH}/;s/ENTITY_GUID/${ENTITY_GUID}/;" ./change_tracking.query > ./change_tracking.query.work
curl -X POST https://api.newrelic.com/graphql -H 'Content-Type: application/json' -H 'API-Key: '${NEW_RELIC_USER_KEY} --data @./change_tracking.query.work
