#!/bin/bash
dry_run=false

#region Argument validation
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            if [[ $# -lt 2 ]]; then
                echo "Error: --dry-run requires an argument (true or false)"
                exit 1
            fi
            dry_run=$2
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$dry_run" ]; then
    echo "Error: --dry-run flag is required with a value (true or false)."
    exit 1
fi

if [ "$dry_run" = true ]; then
    echo "Performing a dry run. No changes will be pushed."
elif [ "$dry_run" = false ]; then
    echo "Changes will be pushed."
else
    echo "Error: Invalid value for --dry-run. Use 'true' or 'false'."
    exit 1
fi
#endregion Argument validation

cd metascoop
echo "::group::Building metascoop executable"
go build -o metascoop
echo "::endgroup::"
./metascoop -ap=../apps.yaml -rd=../fdroid/repo -pat="$ACCESS_TOKEN"
EXIT_CODE=$?
cd ..

echo "Scoop had an exit code of $EXIT_CODE"

set -e

if [ $EXIT_CODE -eq 2 ]; then
    # Exit code 2 means that there were no significant changes
    echo "There were no significant changes"
    exit 0
elif [ $EXIT_CODE -eq 0 ]; then
    # Exit code 0 means that we can commit everything & push

    echo "We have changes to push"

    if [ "$dry_run" = true ]; then
        echo "Performing a dry run (no actual push)"
    else
      echo "Pushing changes..."
      git config --local user.name 'Bitwarden CI'
      git config --local user.email 'ci@bitwarden.com'
      git add .
      git commit -m"Automated update"
      git push
    fi
else
    echo "This is an unexpected error"

    exit $EXIT_CODE
fi