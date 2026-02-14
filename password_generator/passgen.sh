#!/usr/bin/env bash

# This is the password generator script

# Change program exit/warning behaviour:
# -e - immidiate exit when some command break,
# -o - use latest non-zero exit code when something breaks,
# -u - exit if some variable is null. Even one variable is enough to end script execution.
set -eou pipefail


# fix illegal type (byte) sequence
export LC_CTYPE=C

# Defaults
PASSWORD_SIZE=12
PASSWORD=""
# TODO: prohibited passwords
#PROHIBITED_COMBINATIONS=""

# Limits
MIN_PASSWORD_SIZE=3

# Dictionary of uppercase letter (English alphabet)
UPPERCASE_ENGLISH_SYMBOLS='ABCDEFGHIJKLMNOPQRSTUVWXYZ'

# Dictionary of lowercase letters (English alphabet)
LOWERCASECASE_ENGLISH_SYMBOLS='abcdefghijklmnopqrstuvwxyz'

# Dictionary of digits
DIGITS='0123456789'

# Dictionary of special characters
# space symbol included
SPECIAL_SYMBOLS=" !\"#$%&'()*+,-./:;<=>?@[\\]^_\`{\|}~"

MANDATORY_SYMBOLS=("$UPPERCASE_ENGLISH_SYMBOLS" "$LOWERCASECASE_ENGLISH_SYMBOLS" \
                   "$DIGITS" "$SPECIAL_SYMBOLS")

# Array of similar looking characters
SIMILAR_SYMBOLS=('ilI1' 'ce' 'nr' 'b6G'\
                 '8B' 'kK' 'fF' 'oO0' \
                 'pP' 'sS5' 'uvV' 'wW' \
                 'xX' 'yY' 'zZ2')

# Flags
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--size)
            # search argument in regex number expression
            if ! [[ "$2" =~ ^[0-9]+$ ]]; then
                echo "Sorry, a number expected after \"$1\"."
                exit 1
            else
                if [[ "$2" -lt "$MIN_PASSWORD_SIZE" ]]; then
                    echo -e "Sorry, but size of password is too small (less than $MIN_PASSWORD_SIZE symbols).\nPassword, will be the default size - $PASSWORD_SIZE.\n"
                else
                    PASSWORD_SIZE="${2-}"
                fi
            fi 
            shift # past argument
            shift # past value
            ;;
        -*)
            echo "Unknown option \"$1\"."
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1") # save positional arg
            shift # past argument
            ;;
    esac
done

# restore positional parameter
set -- "${POSITIONAL_ARGS[@]-'default'}" s

# Fill up counter arrays with zeros
for (( group_number = 0; group_number < ${#MANDATORY_SYMBOLS[@]}; group_number++)); do
    SIMILAR_SYMBOLS_COUNTER[group_number]=0
done

for (( group_number = 0; group_number < ${#SIMILAR_SYMBOLS[@]}; group_number++)); do
    SIMILAR_SYMBOLS_COUNTER[group_number]=0
done

# TODO: Dictionary of prohibited passwords
# PROHIBITED_PASSWORDS={}


# Password symbol check
function checkSoloSymbolInSymbolGroups() {
    local SYMBOL="${1-}"

    # exit if no symbol provided
    if [[ -z "$SYMBOL" ]]; then
        return 1
    fi

    # every group number
    for (( group_number = 0; group_number < ${#SIMILAR_SYMBOLS[@]}; group_number++)); do
        # symbol match symbol in group
        if echo "${SIMILAR_SYMBOLS[group_number]}" | grep -qF "$SYMBOL"; then
            if [[ ${SIMILAR_SYMBOLS_COUNTER[$group_number]} -gt 0 ]]; then
                # there is already a conflict symbol in group
                return 1
            fi
            # add up to counter
            (( SIMILAR_SYMBOLS_COUNTER[group_number] += 1 ))
        fi
    done
    # a symbol has no conflicts in every group
    return 0
}

function checkPasswordStrength() {
    local PASSWORD="${1-}"

    # exit if no password is provided
    if [[ -z "$PASSWORD" ]]; then
        return 1
    fi
    
    local number_of_group_matches=0
    
    # get mandatory sets
    for symbol_set in "${MANDATORY_SYMBOLS[@]}"; do
        # check if password has symbol in trimmed set
        if grep -F -q -e "$(printf '%s\n' "$symbol_set" | sed 's/./&\n/g')" <<< "$PASSWORD"; then
            (( number_of_group_matches++ ))
        fi
    done

    (( number_of_group_matches == ${#MANDATORY_SYMBOLS[@]} )) || return 1
}

# Function of password creation
function generatePassword() {
    PASSWORD=''

    # clear counters
    for (( group_number=0; group_number < ${#SIMILAR_SYMBOLS[@]}; group_number++ )); do
        SIMILAR_SYMBOLS_COUNTER[group_number]=0
    done

    while [[ ${#PASSWORD} -lt "$PASSWORD_SIZE" ]]; do
        # generate random symbol (one of symbols from keyboard or space)
        local RANDOM_SYMBOL
        RANDOM_SYMBOL=$(< /dev/urandom tr -dc '[:print:]' | head -c 1) && sleep 0.001
        # check symbol in password
        if ! echo "$PASSWORD" | grep -F -q "$RANDOM_SYMBOL" && \
        [[ $(checkSoloSymbolInSymbolGroups "$RANDOM_SYMBOL") -eq 0 ]]; then
            # add symbol in the end of password
            PASSWORD+="$RANDOM_SYMBOL"
        fi
    done
    
    return 0
}

function main() {
    # Run and check password generator
    while ! checkPasswordStrength "$PASSWORD"; do
        generatePassword
    done
    
    # display password in console
    echo "Your password: $PASSWORD"
    exit 0
}

main
