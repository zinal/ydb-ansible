#! /bin/sh

. ./run-active-options.sh
${RUN_ANSIBLE_PARALLEL} loglugger.yaml ${RUN_ANSIBLE_LOGGING_SECRETS} "$@"
