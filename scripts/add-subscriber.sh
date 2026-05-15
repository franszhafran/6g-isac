#!/bin/bash
# Add a UE subscriber to Open5GS via WebUI REST API
# Usage: ./add-subscriber.sh [IMSI] [KEY] [OPC]

set -e

WEBUI_URL="${WEBUI_URL:-http://localhost:9999}"
IMSI="${1:-001010000000001}"
KEY="${2:-fec86ba6eb707ed08905757b1bb44b8f}"
OPC="${3:-C42449363BBAD02B66D16BC975D77CC1}"

echo "Adding subscriber IMSI=${IMSI} to ${WEBUI_URL}..."

curl -sf -X POST "${WEBUI_URL}/api/db/Subscriber" \
    -H "Content-Type: application/json" \
    -d "{
        \"schema\": \"1\",
        \"imsi\": \"${IMSI}\",
        \"msisdn\": [],
        \"security\": {
            \"k\": \"${KEY}\",
            \"op\": null,
            \"opc\": \"${OPC}\",
            \"amf\": \"8000\"
        },
        \"ambr\": {
            \"downlink\": {\"value\": 1, \"unit\": 3},
            \"uplink\": {\"value\": 1, \"unit\": 3}
        },
        \"slice\": [{
            \"sst\": 1,
            \"default_indicator\": true,
            \"session\": [{
                \"name\": \"internet\",
                \"type\": 3,
                \"pcc_rule\": [],
                \"ambr\": {
                    \"downlink\": {\"value\": 1, \"unit\": 3},
                    \"uplink\": {\"value\": 1, \"unit\": 3}
                },
                \"qos\": {
                    \"index\": 9,
                    \"arp\": {
                        \"priority_level\": 8,
                        \"pre_emption_capability\": 1,
                        \"pre_emption_vulnerability\": 1
                    }
                }
            }]
        }],
        \"subscriber_status\": 0,
        \"network_access_mode\": 0,
        \"access_restriction_data\": 32,
        \"subscribed_rau_tau_timer\": 12
    }"

echo "Done. Subscriber ${IMSI} added."
