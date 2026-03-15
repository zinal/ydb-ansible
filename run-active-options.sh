# Active options for run-* scripts

# Useful extra options:
#  -k  for password prompt
RUN_ANSIBLE="ansible-playbook -b -i hosts"
RUN_ANSIBLE_PARALLEL="ansible-playbook -b -f 40 -i hosts"
RUN_ANSIBLE_LOGGING_SECRETS='--extra-vars "@files/secret-credentials.yml"'

# End Of File