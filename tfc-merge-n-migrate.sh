#!/bin/bash
###
# title             : tfc-merge-n-migrate
# file              : shell script
# created           : 2020-07
# modified          : ----------
# www-site          : https://github.com/joshua-bradley/tfc-merge-n-migrate.gi
# description       : script for merging terraform cloud (tfc) work spaces using terraform-cli
# executor-version  : bash
# version           : 0.0.1
###

###
# script debugging flags
###
set -Eeou pipefail
#set -Eeoux pipefail

###
# Global Variables
###
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# readonly MAX_RETRIES=30
# readonly SLEEP_BETWEEN_RETRIES_SEC=10

###
# functions
###

# logging functions
function log() {
    local -r level="$1"
    local -r message="$2"
    local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo >&2 -e "\n ${timestamp} [${level}] [${SCRIPT_NAME}] ${message}"
}

function log_info() {
    local -r message="$1"
    log "INFO" "${message}"
}

function log_warn() {
    local -r message="$1"
    log "WARN" "${message}"
}

function log_error() {
    local -r message="$1"
    log "ERROR" "${message}"
}

# prerequisite check functions
function command_exists() {
    command -v "$@" >/dev/null 2>&1
}

function env_check() {
    echo -e " checking for system prerequisites.... \n"
    if ! command_exists 'terraform'; then
        log_error "Info: terraform is not installed."
        echo -e "\n  To Inistall Terraform-CLI Packacge please review the following document.... "
        echo -e "  https://learn.hashicorp.com/terraform/getting-started/install"
        log_error "Could not find terraform. Cannot proceed with workspace migration."
    else
        log_info "terraform-cli found...\n proceeding with migration...."
    fi
}

# tfstate backup functions
function pull_state() {
    for repo in "$@"; do
        local repo_name=$(echo ${repo} | awk -F/ '{print $NF}')
        log_info "Pulling State from ${repo_name}"
        cd "${PWD}/${repo}"
        terraform state pull >"${SCRIPT_DIR}/${repo_name}.tfstate.bak"
        log_info "${repo_name} has been backed up to ${SCRIPT_DIR}/${repo_name}.tfstate.bak"
        cd "${SCRIPT_DIR}"
    done
}

function restore_state() {
    for repo in "$@"; do
        local repo_name=$(echo ${repo} | awk -F/ '{print $NF}')
        log_info "Restoring State from ${repo_name}"
        cd "${PWD}/${repo}"
        terraform state push -force -lock=true "${SCRIPT_DIR}/${repo_name}.tfstate.bak"
        log_info "${repo_name} has been restored from ${SCRIPT_DIR}/${repo_name}.tfstate.bak"
        cd "${SCRIPT_DIR}"
    done
}

# merge tfstate from multiple workspaces
function merge_state() {
    for repo in "$@"; do
        local repo_name=$(echo ${repo} | awk -F/ '{print $NF}')
        log_info "Merging State from ${repo_name}"
        # cd $PWD/$repo
        for resource in $(terraform state list -state=${repo_name}.tfstate.bak); do
            echo -e "${resource}"
            terraform state mv -state="${PWD}/${repo_name}.tfstate.bak" -state-out="${PWD}/merged.tfstate" $resource $resource
        done
        # terraform state mv -state="${SCRIPT_DIR}/${repo_name}.tfstate.bak" -state-out="${SCRIPT_DIR}" merged.tfstate
        log_info "${repo_name} has been merged to ${SCRIPT_DIR}/merged.tfstate"
        # cd "${SCRIPT_DIR}"
    done
}

function build_combined_workspace() {
    for repo in "$@"; do
        echo "${PWD}"/"${repo}"
        for tf_files in "${PWD}"/"${repo}"/*.tf; do
            # echo "${tf_files}"
            filename="${tf_files##*/}"
            log_info "copying ${filename} to new repo"
            if [[ -f test/"${filename}" ]]; then
                echo "file already exists in target repo"
            else
                cp "${tf_files}" test/
            fi
        done
    done
    mv ${SCRIPT_DIR}/merged.tfstate test/
}

###
# Main
###

function main() {
    # echo "mainline"
    pull_state "$@"
    merge_state "$@"
    build_combined_workspace "$@"
}

clear
env_check "$@"
main "$@"
