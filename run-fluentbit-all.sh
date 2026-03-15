#! /bin/sh

. ./run-active-options.sh
${RUN_ANSIBLE_PARALLEL} fluentbit-all.yaml ${RUN_ANSIBLE_LOGGING_SECRETS} "$@"
