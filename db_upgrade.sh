source common.sh

DRY=0
export ENV_FILE=./env

echo "${BLUE}PARSE ARGS"
for i in "$@"; do
    case $i in
        -e=* | --env=*)
            export ENV_FILE="${i#*=}"
            echo "${CYAN}USE CUSTOM ENV FILE"
            shift
            ;;
        -d | --dry-run)
            DRY=1
            shift
            ;;
        -h | --help)
            echo "
    Usage:

        $0 [options] OldDbVersion NewDbVersion

    Flags:
        -e, --env=ENV_FILE      Set custom env file. If not set ./env is used
        -d, --dry               Dry-run
        -h, --help              Show this help
            "
            exit 0
        ;;
    esac
done


if [[ $1 =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
    export OLD_VERSION=${1}
else
    echo "${ERROR}$0 [options] OldDbVersion NewDbVersion"
    exit 1
fi
if [[ $2 =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
    export NEW_VERSION=${2}
else
    echo "${ERROR}$0 [options] OldDbVersion NewDbVersion"
    exit 1
fi

# --------------------------------------------------------------
# ---------------------------- MAIN ----------------------------
# --------------------------------------------------------------

source_env ${ENV_FILE}

bash ./build.sh -d -e=${ENV_FILE}
docker-compose -f docker-compose.dbUpgrade.yml up -d

if [ $DRY == 1 ]; then
    echo "${MAGENTA}Dry dump from $OLD_VERSION"
    echo "${MAGENTA}Dry import to $NEW_VERSION"
else
    echo "${GREEN}Dump from $OLD_VERSION"
    docker-compose -f docker-compose.dbUpgrade.yml exec -T old-db pg_dumpall -U postgres > dump.sql

    echo "${GREEN}Import to $NEW_VERSION"
    docker-compose -f docker-compose.dbUpgrade.yml exec -T new-db psql -U postgres < dump.sql
fi

docker-compose -f docker-compose.dbUpgrade.yml down
