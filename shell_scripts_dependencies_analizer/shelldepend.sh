#!/usr/bin/env bash

# This is the shell-scripts dependencies analizer
# Change program exit/warning behaviour:
# -e - immidiate exit when some command break,
# -o - use latest non-zero exit code when something breaks,
# -u - exit if some variable is null. Even one variable is enough to end script execution.
set -u
set -o pipefail

# Defaults:
# folder where to check scripts
TARGET_DIRECTORY='./'

# set of possible shell's
SHELLS=( 'sh' 'dash' 'ksh' 'bash' 'zsh' 'fish' )

# strict mode for finding unset variables in scripts
STRICT_MODE=false

# script usage mini manual

POSITIONAL_ARGS=()

# Usage manual
function usage() {
    echo "Usage: $0 [OPTIONS] [DIRECTORY]"
    echo "Options:"
    echo "  -s, --strict    Enable strict mode to report undeclared variables"
    echo "  -h, --help      Show this help message"
}

# use options
while [[ $# -gt 0 ]]; do
    case $1 in 
        -s|--strict)
            # set strict mode
            STRICT_MODE=true
            shift # past flag
            ;;
        -h|--help)
            # show help message
            usage
            shift # past flag
            ;;
        -*)
            echo -e "Did not expect flag - $1"
            # print usage

            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# If directory provided as argument, use it
if [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
    TARGET_DIRECTORY="${POSITIONAL_ARGS[0]}"
fi

echo "Analyze directory: $TARGET_DIRECTORY"
if [[ "$STRICT_MODE" == "true" ]]; then
    echo "Strict mode: ON (Checking undeclared variables)"
fi
echo "---------------------------------------------------"

# Check if a file is a shell script via shebang
function is_shell_script() {
    local file="$1"
    local first_line
    # Read first line, suppressing errors if file is unreadable
    first_line=$(head -n 1 "$file" 2>/dev/null)
    
    # Check for #!
    if [[ "$first_line" != \#!* ]]; then
        return 1
    fi

    for shell in "${SHELLS[@]}"; do
        if [[ "$first_line" =~ $shell ]]; then
            return 0
        fi
    done
    return 1
}

# Get list of built-in commands to exclude them from "External commands"
BUILTINS=$(compgen -b)

function analyze_script() {
    local script_path="$1"
    
    # Strip comments for analysis to avoid false positives
    # We create a temporary content stream
    local content_no_comments
    content_no_comments=$(sed 's/#.*//g' "$script_path")

    # Find Sources (Internal Dependencies)
    # Looks for: source xxx, . xxx
    local sources
    sources=$(echo "$content_no_comments" | grep -E '^\s*(source|\.)\s+' | awk '{print $2}' | \
        sort -u)

    # Find Variables (Declared vs Used)
    # Declared: starts with VAR=
    local declared_vars
    declared_vars=$(echo "$content_no_comments" | grep -oE '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' | \
        tr -d '=' | tr -d ' ' | sort -u)
    
    # Used: $VAR or ${VAR}
    local used_vars
    used_vars=$(echo "$content_no_comments" | grep -oE '\$\{?[a-zA-Z_][a-zA-Z0-9_]*\}?' | \
        sed 's/[${}]//g' | sort -u)

    # Find External Commands
    # Logic: Look for the first word of lines that are not assignments
    local possible_cmds
    possible_cmds=$(echo "$content_no_comments" | \
        grep -vE '^\s*[a-zA-Z_][a-zA-Z0-9_]*=' | \
        awk '{print $1}' | \
        grep -E '^[a-zA-Z_-]+$' | \
        sort -u)

    local external_cmds=()
    
    # Keywords/Syntactic sugar to ignore
    local ignore_list="if then else elif fi case esac for while do done function return local export alias"

    for cmd in $possible_cmds; do
        # Skip if in ignore list or empty
        if [[ -z "$cmd" ]] || [[ $ignore_list =~  $cmd ]]; then
            continue
        fi

        # Check if it's a builtin
        if echo "$BUILTINS" | grep -q "^$cmd$"; then
            continue
        fi

        # Check if it exists in PATH of the current system
        if command -v "$cmd" >/dev/null 2>&1; then
            external_cmds+=("$cmd")
        else
            # If not in path, it might be a function declared in the script or unknown
            # For this graph, we treat "found in PATH" as confirmed external dependency
            : 
        fi
    done

    # Output / Graph Node Construction
    echo "📦 Script: $script_path"
    
    # Internal Dependencies (Sourced files)
    if [[ -n "$sources" ]]; then
        while read -r src; do
             echo " ├── 🔗 Internal: $src"
        done <<< "$sources"
    else
        echo " ├── 🔗 Internal: None"
    fi

    # External Dependencies (System commands)
    if [[ ${#external_cmds[@]} -gt 0 ]]; then
        local ext_list="${external_cmds[*]}"
        # formatting as comma separated
        echo -e " ├── 🛠\x20\x20External: ${ext_list// /, }"
    else
        echo -e " ├──\x20🛠\x20\x20External: None"
    fi

    # Variable Analysis
    local decl_count
    decl_count=$(echo "$declared_vars" | wc -w)
    echo -e " └── 🎚️\x20\x20Variables (Declared: $decl_count)"

    # Strict Mode Check (Undeclared variables)
    if [[ "$STRICT_MODE" == "true" ]]; then
        local undeclared_found=false
        for u_var in $used_vars; do
            # Skip special variables like $1, $?, $PWD
            if [[ "$u_var" =~ ^[0-9]+$ ]] || [[ "$u_var" == "?" ]] || [[ "$u_var" == "*" ]] || [[ "$u_var" == "@" ]]; then
                continue
            fi
            
            # Check if used variable is in declared list
            if ! echo "$declared_vars" | grep -q "^$u_var$"; then
                # Check if it is an environment variable (basic check)
                if [[ -z "${!u_var+x}" ]]; then
                     echo -e "\x20\x20\x20\x20\x20⚠️  WARNING: '$u_var' used but not declared/exported" >&2
                     undeclared_found=true
                fi
            fi
        done
        if [[ "$undeclared_found" == "false" ]]; then
            echo -e "\x20\x20\x20\x20\x20✅ Strict Check Passed"
        fi
    fi
    echo "" # New line separator for graph
}

# Find shell-scripts
# Using 'find' to get files, then filtering via loop for robust shebang check
while IFS= read -r file; do
    if is_shell_script "$file"; then
        analyze_script "$file"
    fi
done < <(find "$TARGET_DIRECTORY" -type f -not -path '*/.*' 2>/dev/null)
