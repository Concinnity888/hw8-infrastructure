#!/usr/bin/env bash

CURRENT_TAG=$(git tag | sort -r | head -1)
PREV_TAG=$(git tag | sort -r | head -1 | tail -1)
AUTHOR=$(git show ${CURRENT_TAG} | grep Author:)
DATE=$(git show ${PREV_TAG} | grep Date:)

CHANGELOG=$(git log ${PREV_TAG}.. --pretty=format:"%s | %an, %ad\n" --date=short | tr -s "\n" " ")
DESCRIPTION="${AUTHOR} \n ${DATE} \n Номер версии: ${CURRENT_TAG} \n changelog: ${CHANGELOG}"
UNIQUE_KEY="https://github.com/Concinnity888/hw8-infastructure/releases/tag/${CURRENT_TAG}"
URL="https://api.tracker.yandex.net/v2/issues/"

REQUEST='{
  "summary": "'"${CURRENT_TAG}"'",
  "description": "'"${DESCRIPTION}"'",
  "queue": "TMP",
  "unique": "'"${UNIQUE_KEY}"'"
}'
echo "\nREQUEST: ${REQUEST}\n"
echo "\nOAUTH: ${OAUTH}\n"
echo "\nORG: ${ORG}\n"

RESPONSE=$(
  curl -X POST ${URL} \
  --header "Authorization: OAuth ${OAUTH}" \
  --header "X-Org-ID: ${ORG}" \
  --header "Content-Type: application/json" \
  --data "${REQUEST}"
)
echo "\nStatus code: ${RESPONSE}\n"

if [ ${RESPONSE} = 201 ]; then
  echo "Задача создана"
  exit 0
elif [ ${RESPONSE} = 403 ]; then
  echo "Ошибка аторизации"
  exit 1
elif [ ${RESPONSE} = 409 ]; then
  echo 'Задача с таким релизом уже создана'
  UPDATE=$(curl -X POST \
    "https://api.tracker.yandex.net/v2/issues/${RESPONSE}" \
    --header "Content-Type: application/json" \
    --header "Authorization: OAuth ${OAUTH} " \
    --header "X-Org-Id: ${ORG}" \
    --data '{
      "summary": "'"${CURRENT_TAG}"'",
      "description": "'"${DESCRIPTION}"'",
    }'
  )
  if [ ${UPDATE} = 200 ]; then
    echo "Задача успешно обновлена"
    exit 0
  else
    echo "Ошибка обновления"
    exit 1
  fi
else
  echo "Ошибка"
  exit 1
fi
