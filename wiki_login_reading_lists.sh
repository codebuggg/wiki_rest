#!/bin/bash

SITE_URL=$1
USER_NAME=$2
COOKIE_PREFIX=$3
if [[ -z "$SITE_URL" || -z "$USER_NAME" || -z "$COOKIE_PREFIX" ]]; then
    echo "wiki_login <api.php url> <username> <site cookie prefix>"
    echo "e.g. wiki_login https://localhost/core aaron my_wiki"
    exit 1
fi

API_URL="${SITE_URL}/api.php"
REST_URL="${SITE_URL}/rest.php"

echo "Getting (logged-out) session cookies and corresponding CSRF token..."
curl -s -i --insecure -a "${API_URL}?action=query&meta=tokens&type=login&format=json" | grep --color=always -e "^" -e "logintoken" -e "${COOKIE_PREFIX}_session"
echo
read -p "Enter ${COOKIE_PREFIX}_session from response cookies: " WEB_SESSION
read -p "Enter logintoken from response body (include backslashes): " LOGIN_TOKEN

echo "Checking if (logged-out) session persists (no set-cookie header should appear below)..."
curl -s -i --insecure -b "${COOKIE_PREFIX}_session=${WEB_SESSION}" -a "${API_URL}?action=query&meta=siteinfo&siprop=dbrepllag&sishowalldb=&format=json" | grep --color=always -e "set-cookie:"
echo
echo "...(no set-cookie header for ${COOKIE_PREFIX}_session should appear above)"

read -s -p "Enter user password: " USER_PASS
echo

echo "Getting (logged-in) session cookies via login..."
curl -s -i --insecure -b "${COOKIE_PREFIX}_session=${WEB_SESSION}" -X POST -H "content-type: application/x-www-form-urlencoded" -a "${API_URL}?action=clientlogin&format=json" --data-urlencode "username=${USER_NAME}" --data-urlencode "password=${USER_PASS}" --data-urlencode "logintoken=${LOGIN_TOKEN}" --data-urlencode "loginreturnurl=https://localhost/no_client_site_needed.php" | grep --color=always -e "^" -e "${COOKIE_PREFIX}_session" -e "${COOKIE_PREFIX}UserID" -e "${COOKIE_PREFIX}UserName"
echo
echo "...(a set-cookie header for session, UserID, and UserName should appear above)"
echo

read -p "Enter ${COOKIE_PREFIX}_session from response cookies: " WEB_SESSION
read -p "Enter ${COOKIE_PREFIX}UserID from response cookies: " WEB_SESSION_USERID
read -p "Enter ${COOKIE_PREFIX}UserName from response cookies: " WEB_SESSION_USERNAME
echo

# Test with api.php watchlistraw endpoint
echo "Getting logged-in user watchlist info..."
curl -s -i --insecure -b "${COOKIE_PREFIX}_session=${WEB_SESSION}" -b "${COOKIE_PREFIX}UserID=${WEB_SESSION_USERID}" -b "${COOKIE_PREFIX}UserName=${WEB_SESSION_USERNAME}" -a "${API_URL}?action=query&list=watchlistraw&format=json"
echo

echo "Getting (logged-in) session CRSF token..."
curl -s -i --insecure -b "${COOKIE_PREFIX}_session=${WEB_SESSION}" -b "${COOKIE_PREFIX}UserID=${WEB_SESSION_USERID}" -b "${COOKIE_PREFIX}UserName=${WEB_SESSION_USERNAME}" -a "${API_URL}?action=query&meta=tokens&type=csrf&format=json" | grep --color=always -e "^" -e "csrftoken" -e "${COOKIE_PREFIX}_session"
echo

read -p "Enter csrftoken from response (include slashes): " CSRF_TOKEN
echo

# Test with rest.php endpoint. Print the curl commands for easy manual reuse.
echo "Setting up Reading Lists..."
DATA="{}"
set -x
# Ensure we are starting from a clean state. This will harmlessly fail if reading lists are not already set up for this user.
curl -s -i --insecure -X POST -b "${COOKIE_PREFIX}_session=${WEB_SESSION}" -b "${COOKIE_PREFIX}UserID=${WEB_SESSION_USERID}" -b "${COOKIE_PREFIX}UserName=${WEB_SESSION_USERNAME}" -a "${REST_URL}/readinglists/v0/teardown" -H "Content-Type: application/json" --data "${DATA}"
echo

# Set up reading lists for this user. This will create a default list.
curl -s -i --insecure -X POST -b "${COOKIE_PREFIX}_session=${WEB_SESSION}" -b "${COOKIE_PREFIX}UserID=${WEB_SESSION_USERID}" -b "${COOKIE_PREFIX}UserName=${WEB_SESSION_USERNAME}" -a "${REST_URL}/readinglists/v0/setup" -H "Content-Type: application/json" --data "${DATA}" 
echo

# Retrieve the new default list
curl -s -i --insecure -b "${COOKIE_PREFIX}_session=${WEB_SESSION}" -b "${COOKIE_PREFIX}UserID=${WEB_SESSION_USERID}" -b "${COOKIE_PREFIX}UserName=${WEB_SESSION_USERNAME}" -a "${REST_URL}/readinglists/v0/lists?sort=foo"
echo

# Tear down lists
curl -s -i --insecure -X POST -b "${COOKIE_PREFIX}_session=${WEB_SESSION}" -b "${COOKIE_PREFIX}UserID=${WEB_SESSION_USERID}" -b "${COOKIE_PREFIX}UserName=${WEB_SESSION_USERNAME}" -a "${REST_URL}/readinglists/v0/teardown" -H "Content-Type: application/json" --data "${DATA}"
set +x

echo
