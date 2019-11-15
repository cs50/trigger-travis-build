#!/bin/bash


set -eo pipefail

ORG="cs50"

function usage() {
    echo "Usage: $0 OPTION..."
    echo "-t, --token             TOKEN           your Travis CI API token (default: \$TRAVIS_TOKEN)"
    echo "-o, --org               ORGANIZATION    organization name (default: $ORG)"
    echo "-r, --repo              REPOSITORY      repository name"
    echo "-b, --branch            BRANCH          branch name (default: master)"
    echo "-bi, --base-image       IMAGE           base image (default: \$TRAVIS_SLUG:\$TRAVIS_BRANCH)"
    echo "--tag                   TAG             tag name for target image (default: \$TRAVIS_BRANCH)"
    echo "-v, --verbose                           enable verbose mode"
    exit 1
}


function log() {
    [[ $VERBOSE -eq 1 ]] && echo "$1 ..."
}

while [ $# -gt 0 ]; do
    case $1 in
        -t|--token)
            shift
            TRAVIS_TOKEN=$1
            ;;
        -r|--repo)
            shift
            REPO=$1
            ;;
        -b|--branch)
            shift
            BRANCH=$1
            ;;
        -o|--org)
            shift
            ORG=$1
            ;;
        -bi|--base-image)
            shift
            BASE_IMAGE=$1
            ;;
        -v|--verbose)
            VERBOSE=1
            ;;
        --tag)
            shift
            TARGET_TAG=$1
            ;;
        *)
            usage
            ;;
    esac

    shift
done

[[ "$TRAVIS_BRANCH" == "master" ]] && TAG="latest" || TAG="$TRAVIS_BRANCH"
BASE_IMAGE="${BASE_IMAGE:=$ORG/$REPO:$TAG}"
log "Base image is $BASE_IMAGE ..."

TARGET_TAG=${TARGET_TAG:=$TAG}
log "Target tag is $TARGET_TAG ..."

BRANCH="${BRANCH:=master}"
log "Branch is $BRANCH ..."

function valid_options() {
    return $([ -n "${TRAVIS_TOKEN+x}" ] && \
        [ -n "${REPO+x}" ])
}

log "Validating command-line options ..."
if ! valid_options; then
    usage
fi

body="{
    \"request\": {
        \"branch\":\"$BRANCH\",
        \"config\": {
            \"env\": {
                \"BASE_IMAGE\": \"$BASE_IMAGE\",
                \"TAG\": \"$TARGET_TAG\"
            }
        }
    }
}"

log "Payload is $body ..."
log "Triggering build for $ORG/$REPO ..."
curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H "Travis-API-Version: 3" \
    -H "Authorization: token $TRAVIS_TOKEN" \
    -d "$body" \
    https://api.travis-ci.com/repo/$ORG%2F$REPO/requests
