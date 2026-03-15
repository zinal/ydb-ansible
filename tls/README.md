# TLS certificate generation script for YDB

In order to simplify generation and re-generation of certificates for YDB cluster, the `ydb-ca-update.sh` script has been created.

The recommended option is to generate a separate certificate for each cluster node. Users may choose to generate a single wildcard certificate for the whole cluster instead, by specifying the host name in the form of `*.domain.com`.

The script reads the list of certificate host names from `ydb-ca-nodes.txt` file, one hostname per line. Host names should be specified exactly as they are defined in the YDB cluster configuration file. If the wildcard name is used, it should match the correspoding hosts DNS names. Up to two host names can be specified in each line, both referring to the same host.

The generated certificates are written into the directory structure in the `CA` subdirectory, which is created if missing.

In case the certificate authority is not initialized yet, private CA key and certificate are generated.

For each host name or wildcard listed in the `ydb-ca-nodes.txt` file, each invocation of the script generates the new key and new certificate signed by the private CA. All generated files are put into `CA/certs/YYYY-MM-DD_hh-mi-ss` subdirectory.

## Client certificate generation

For mutual TLS client-server authentication, use the companion script:

`./ydb-client-cert.sh SUBJECT_NAME LOGICAL_NAME [VALIDITY_DAYS]`

This script expects CA infrastructure to already exist (created by a previous `./ydb-ca-update.sh` run).

- `SUBJECT_NAME` (mandatory): desired client certificate subject name. You can pass either CN value (for example `my-client`) or full OpenSSL subject string (for example `/O=YDB/CN=my-client`).
- `LOGICAL_NAME` (mandatory): logical key name used as output subdirectory name.
- `VALIDITY_DAYS` (optional): certificate validity period in days (default is `731`).

Generated files are written to `CA/clients/LOGICAL_NAME`:

- `client.key`
- `client.csr`
- `client.crt`
- `client.pem` (key + certificate + CA certificate)

If `CA/clients/LOGICAL_NAME` already exists, previous `client.key`, `client.csr`, `client.crt`, and `client.pem` files are moved to `backup_YYYY-MM-DD_hh-mm-ss` inside that same directory before new files are generated.
