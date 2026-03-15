#! /bin/sh

set -e
set +u

KEY_BITS=4096
DEFAULT_DAYS=731

usage() {
    echo "Usage: $0 SUBJECT_NAME LOGICAL_NAME [VALIDITY_DAYS]"
    echo "  SUBJECT_NAME   Desired certificate subject name (CN value, or full openssl -subj string)"
    echo "  LOGICAL_NAME   Logical key name used for output path: CA/clients/LOGICAL_NAME"
    echo "  VALIDITY_DAYS  Optional certificate validity in days (default: ${DEFAULT_DAYS})"
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    usage
    exit 1
fi

SUBJECT_NAME="$1"
LOGICAL_NAME="$2"
VALIDITY_DAYS="${3:-$DEFAULT_DAYS}"

case "$VALIDITY_DAYS" in
    ''|*[!0-9]*)
        echo "Error: VALIDITY_DAYS must be a positive integer" >&2
        exit 1
        ;;
esac

if [ "$VALIDITY_DAYS" -le 0 ]; then
    echo "Error: VALIDITY_DAYS must be greater than zero" >&2
    exit 1
fi

[ -d CA ] || {
    echo "Error: missing CA directory. Run ./ydb-ca-update.sh first." >&2
    exit 1
}
cd CA

for required in ca.cnf secure/ca.key certs/ca.crt index.txt serial.txt; do
    if [ ! -f "$required" ]; then
        echo "Error: missing CA/$required. Run ./ydb-ca-update.sh first." >&2
        exit 1
    fi
done

mkdir -pv clients

SAFE_LOGICAL_NAME=$(printf '%s' "$LOGICAL_NAME" | tr -c 'A-Za-z0-9._-' '_')
OUT_DIR="clients/${SAFE_LOGICAL_NAME}"

if [ -d "$OUT_DIR" ]; then
    BACKUP_DIR="${OUT_DIR}/backup_$(date "+%Y-%m-%d_%H-%M-%S")"
    mkdir -pv "$BACKUP_DIR"
    for cert_file in client.key client.csr client.crt client.pem; do
        if [ -f "${OUT_DIR}/${cert_file}" ]; then
            mv -v "${OUT_DIR}/${cert_file}" "${BACKUP_DIR}/"
        fi
    done
else
    mkdir -pv "$OUT_DIR"
fi

if [ "$SUBJECT_NAME" = "${SUBJECT_NAME#/}" ]; then
    SUBJECT="/O=YDB/CN=${SUBJECT_NAME}"
else
    SUBJECT="$SUBJECT_NAME"
fi

KEY_FILE="${OUT_DIR}/client.key"
CSR_FILE="${OUT_DIR}/client.csr"
CRT_FILE="${OUT_DIR}/client.crt"
PEM_FILE="${OUT_DIR}/client.pem"

echo "** Generating key for client ${SAFE_LOGICAL_NAME}..."
openssl genrsa -out "$KEY_FILE" ${KEY_BITS}

echo "** Generating CSR for client ${SAFE_LOGICAL_NAME}..."
openssl req -new -sha256 -key "$KEY_FILE" -subj "$SUBJECT" -out "$CSR_FILE"

echo "** Signing certificate for client ${SAFE_LOGICAL_NAME}..."
openssl ca -config ca.cnf -keyfile secure/ca.key -cert certs/ca.crt -policy signing_policy \
    -extensions signing_client_req -out "$CRT_FILE" -outdir "$OUT_DIR" -in "$CSR_FILE" -days "$VALIDITY_DAYS" -batch

cat "$KEY_FILE" "$CRT_FILE" certs/ca.crt >"$PEM_FILE"

echo "All done. Client certificate files are in CA/${OUT_DIR}"
