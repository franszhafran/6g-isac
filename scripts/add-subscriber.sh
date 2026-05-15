#!/bin/bash
# Add a UE subscriber to free5GC via WebConsole REST API.
# Usage: ./add-subscriber.sh [IMSI] [KEY] [OPC]

set -e

WEBCONSOLE_URL="${WEBCONSOLE_URL:-http://localhost:5000}"
IMSI="${1:-001010000000001}"
KEY="${2:-fec86ba6eb707ed08905757b1bb44b8f}"
OPC="${3:-C42449363BBAD02B66D16BC975D77CC1}"
PLMN_ID="00101"   # MCC=001 MNC=01

echo "Logging in to webconsole..."
TOKEN=$(curl -sf -X POST "${WEBCONSOLE_URL}/api/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"free5gc"}' | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo "Adding subscriber IMSI=${IMSI} to ${WEBCONSOLE_URL}..."

curl -sf -X POST "${WEBCONSOLE_URL}/api/subscriber/imsi-${IMSI}/${PLMN_ID}" \
    -H "Content-Type: application/json" \
    -H "Token: ${TOKEN}" \
    -d "{
      \"plmnID\": \"${PLMN_ID}\",
      \"ueId\": \"imsi-${IMSI}\",
      \"AuthenticationSubscription\": {
        \"authenticationMethod\": \"5G_AKA\",
        \"permanentKey\": {
          \"permanentKeyValue\": \"${KEY}\",
          \"encryptionKey\": 0,
          \"encryptionAlgorithm\": 0
        },
        \"sequenceNumber\": \"16f3b3f70fc2\",
        \"authenticationManagementField\": \"8000\",
        \"milenage\": {\"op\": {\"opValue\": \"\", \"encryptionKey\": 0, \"encryptionAlgorithm\": 0}},
        \"opc\": {\"opcValue\": \"${OPC}\", \"encryptionKey\": 0, \"encryptionAlgorithm\": 0}
      },
      \"AccessAndMobilitySubscriptionData\": {
        \"gprsTimer3\": {\"timerUnit\": 7, \"timerValue\": 0},
        \"nssai\": {
          \"defaultSingleNssais\": [{\"sst\": 1, \"sd\": \"010203\"}],
          \"singleNssais\": []
        },
        \"subscribedUeAmbr\": {\"downlink\": \"1 Gbps\", \"uplink\": \"1 Gbps\"},
        \"gpsis\": [\"\"]
      },
      \"SessionManagementSubscriptionData\": [{
        \"singleNssai\": {\"sst\": 1, \"sd\": \"010203\"},
        \"dnnConfigurations\": {
          \"internet\": {
            \"pduSessionTypes\": {\"defaultSessionType\": \"IPV4\", \"allowedSessionTypes\": [\"IPV4\"]},
            \"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\", \"allowedSscModes\": [\"SSC_MODE_2\", \"SSC_MODE_3\"]},
            \"5gQosProfile\": {\"5qi\": 9, \"arp\": {\"priorityLevel\": 8, \"preemptCap\": \"NOT_PREEMPT\", \"preemptVuln\": \"PREEMPTABLE\"}, \"priorityLevel\": 8},
            \"sessionAmbr\": {\"uplink\": \"1000 Mbps\", \"downlink\": \"1000 Mbps\"},
            \"staticIpAddress\": []
          }
        }
      }],
      \"SmfSelectionSubscriptionData\": {
        \"subscribedSnssaiInfos\": {
          \"01010203\": {\"dnnInfos\": [{\"dnn\": \"internet\"}]}
        }
      },
      \"AmPolicyData\": {\"subscCats\": [\"free5gc\"]}
    }"

echo ""
echo "Done. Subscriber imsi-${IMSI} added."
