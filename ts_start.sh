#!/bin/bash
# CONFIGURABLE DOCKERIZED THREAT STACK AGENT
# https://github.com/lever/threatstack-docker
#
# See: https://threatstack.zendesk.com/hc/en-us/articles/360016123992
# for additional information about the agent.

set -e

# configure the configuration location
if [ -z ${THREATSTACK_CONFIG_PATH} ]; then
  export THREATSTACK_CONFIG_PATH='/etc/ts-agent/ts_config.json'
fi

# set the deploy key
if [ -z ${THREATSTACK_DEPLOY_KEY} ]; then
  echo 'You must set the THREATSTACK_DEPLOY_KEY variable for this container to function.'
  exit 2
fi

# optionally set custom rulesets and log level
if [ -z ${THREATSTACK_RULESET} ]; then
  export THREATSTACK_RULESET="Base Rule Set, Docker Rule Set"
fi

if [ -z ${THREATSTACK_LOGLEVEL} ]; then
  export THREATSTACK_LOGLEVEL="info"
fi

# template out the configuration file based on inputs
sed -i -r "s/THREATSTACK_DEPLOY_KEY/${THREATSTACK_DEPLOY_KEY}/g" ${THREATSTACK_CONFIG_PATH}
sed -i -r "s/THREATSTACK_RULESET/${THREATSTACK_RULESET}/g" ${THREATSTACK_CONFIG_PATH}
sed -i -r "s/THREATSTACK_LOGLEVEL/${THREATSTACK_LOGLEVEL}/g" ${THREATSTACK_CONFIG_PATH}

# start the threat stack agent
exec cloudsight setup ${THREATSTACK_SETUP_ARGS} --config=${THREATSTACK_CONFIG_PATH} --in_container=1 && \
  cloudsight stop && \
  cloudsight --main
