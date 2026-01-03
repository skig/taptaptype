#!/bin/bash

# The script is a typing trainer
# It shows a sample text that should be typed by a user
# It prints the statistics at the end of session
# It is possible to provide an argument N with amount of rerun sessions.
# Usage
# taptaptype.sh [N]
# N - optional number of sessions

GREY=$'\033[90m'
RED=$'\033[91m'
RESET=$'\033[0m'
UNDERLINE=$'\033[4m'
CLEAR_LINE=$'\r\033[K'
HIDE_CURSOR=$'\e[?25l'
SHOW_CURSOR=$'\e[?25h'

move_cursor_to() {
    printf '\033[%d;%dH' "$1" "$2"
}

# Sample texts
TEXT_SAMPLES=(
    "The quick brown fox jumps over the lazy dog!"
    "A central processing unit (CPU), also called a central processor, main processor, or just processor, is the primary processor in a given computer. Its electronic circuitry executes instructions of a computer program, such as arithmetic, logic, controlling, and input/output (I/O) operations."
    "The fundamental operation of most CPUs, regardless of the physical form they take, is to execute a sequence of stored instructions that is called a program. The instructions to be executed are kept in some kind of computer memory. Nearly all CPUs follow the fetch, decode and execute steps in their operation, which are collectively known as the instruction cycle."
    "Alfred Nobel, in his last will and testament, stated that his wealth should be used to create a series of prizes for those who confer the greatest benefit on mankind in the fields of physics, chemistry, peace, physiology or medicine, and literature. Though Nobel wrote several wills during his lifetime, the last one was written a year before he died and was signed at the Swedish-Norwegian Club in Paris on 27 November 1895."
    "Overclocking is a process of increasing the clock speed of a CPU (and other components) beyond their rated speeds. Increasing a component's clock rate causes it to perform more operations per second. Overclocking might increase CPU temperature and cause it to overheat, so most users do not overclock and leave the clock speed unchanged."
    "A Hello, World! program is usually a simple computer program that emits (or displays) to the screen (often the console) a message similar to Hello, World. A small piece of code in most general-purpose programming languages, this program is used to illustrate a language's basic syntax. Such a program is often the first written by a student of a new programming language."
    "The origin of C is closely tied to the development of the Unix operating system, originally implemented in assembly language on a PDP-7 by Dennis Ritchie and Ken Thompson, incorporating several ideas from colleagues. Eventually, they decided to port the operating system to a PDP-11. The original PDP-11 version of Unix was also developed in assembly language."
    "Niels Henrik Abel was a Norwegian mathematician who made pioneering contributions in a variety of fields. His most famous single result is the first complete proof demonstrating the impossibility of solving the general quintic equation in radicals. This question was one of the outstanding open problems of his day, and had been unresolved for over 250 years."
    "In the radio series and the first novel, a group of hyper-intelligent pan-dimensional beings demand to learn the Answer to the Ultimate Question of Life, the Universe, and Everything from the supercomputer Deep Thought, specially built for this purpose. It takes Deep Thought 7 million years to compute and check the answer, which turns out to be 42."
    "It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair."
    "To be, or not to be, that is the question: Whether 'tis nobler in the mind to suffer the slings and arrows of outrageous fortune, or to take arms against a sea of troubles and by opposing end them."
    "Four score and seven years ago our fathers brought forth on this continent, a new nation, conceived in Liberty, and dedicated to the proposition that all men are created equal."
    "I have a dream that one day this nation will rise up and live out the true meaning of its creed: We hold these truths to be self-evident, that all men are created equal."
    "In a hole in the ground there lived a hobbit. Not a nasty, dirty, wet hole, filled with the ends of worms and an oozy smell, nor yet a dry, bare, sandy hole with nothing in it to sit down on or to eat: it was a hobbit-hole, and that means comfort."
    "In economics and business decision-making, a sunk cost (also known as retrospective cost) is a cost that has already been incurred and cannot be recovered. Sunk costs are contrasted with prospective costs, which are future costs that may be avoided if action is taken. In other words, a sunk cost is a sum paid in the past that should no longer be relevant to decisions about the future. Even though economists argue that sunk costs are no longer relevant to future rational decision-making, people in everyday life often take previous expenditures in situations, such as repairing a car or house, into their future decisions regarding those properties."
    "The term Concorde fallacy derives from the fact that the British and French governments continued to fund the joint development of the costly Concorde supersonic airplane even after it became apparent that there was no longer an economic case for the aircraft. The British government privately regarded the project as a commercial disaster that should never have been started. Political and legal issues made it impossible for either government to pull out."
)

TEXT=""

select_random_text() {
    local array_size=${#TEXT_SAMPLES[@]}
    local random_index=$((RANDOM % array_size))
    TEXT="${TEXT_SAMPLES[$random_index]}"
}

TYPED_TEXT=""
CURRENT_POS=0
MISTAKES=0
TOTAL_MISTAKES=0
START_TIME=0

TERM_WIDTH=0
AVAILABLE_WIDTH=0
STATS_LINE=0

setup_terminal() {
    stty -echo -icanon time 0 min 1
    printf "${HIDE_CURSOR}"
    clear
}

restore_terminal() {
    stty echo icanon
    printf "${SHOW_CURSOR}"
    echo
}

draw_initial_screen() {
    clear
    printf "Type the text:\n"
    printf "================\n"
    printf "\n\n"
    printf "\n\n"
    printf "\n  Press ESC to quit\n\n"
}

update_text_display() {
    local text="$1"
    local typed="$2"
    local current_pos="$3"

    move_cursor_to 4 3

    local current_line=4
    local chars_in_line=0

    for (( i=0; i<${#text}; i++ )); do
        local char="${text:$i:1}"

        if (( chars_in_line >= AVAILABLE_WIDTH )); then
            current_line=$((current_line + 1))
            printf "\n  "
            move_cursor_to $current_line 3
            chars_in_line=0
        fi

        if (( i < ${#typed} )); then
            local typed_char="${typed:$i:1}"
            if [[ "$char" == "$typed_char" ]]; then
                printf "%s" "$char"
            else
                if [[ "$char" == " " ]]; then
                    printf "%s" "${RED}_${RESET}"
                else
                    printf "${RED}%s${RESET}" "$char"
                fi
            fi
        elif (( i == current_pos )); then
            printf "${UNDERLINE}${GREY}%s${RESET}" "$char"
        else
            printf "${GREY}%s${RESET}" "$char"
        fi

        chars_in_line=$((chars_in_line + 1))
    done
}

calculate_stats_line() {
    local text="$1"
    local line_count=1

    local chars_in_line=0
    for (( i=0; i<${#text}; i++ )); do
        if (( chars_in_line >= AVAILABLE_WIDTH )); then
            line_count=$((line_count + 1))
            chars_in_line=0
        fi
        chars_in_line=$((chars_in_line + 1))
    done

    echo $((4 + line_count + 1))
}

update_stats_display() {
    local wpm_actual="$1"
    local accuracy="$2"
    local stats_line="$3"

    move_cursor_to "$stats_line" 1
    printf "${CLEAR_LINE}  WPM: %.0f Accuracy: %.1f%% | Position: %d/%d" \
           "$wpm_actual" "$accuracy" "$CURRENT_POS" "${#TEXT}"
}

calculate_wpm() {
    local chars="$1"
    local time_elapsed="$2"

    if (( time_elapsed > 0 )); then
        echo "scale=2; ($chars / 5) * (60 / $time_elapsed)" | bc -l
    else
        echo "0"
    fi
}

calculate_cpm() {
    local chars="$1"
    local time_elapsed="$2"

    if (( time_elapsed > 0 )); then
        echo "scale=2; $chars * (60 / $time_elapsed)" | bc -l
    else
        echo "0"
    fi
}

calculate_accuracy() {
    local correct_chars="$1"
    local total_chars="$2"

    if (( total_chars > 0 )); then
        echo "scale=2; ($correct_chars * 100) / $total_chars" | bc -l
    else
        echo "100"
    fi
}

handle_input() {
    local char
    local current_time
    local time_elapsed
    local wpm
    local accuracy
    local correct_chars

    select_random_text

    TERM_WIDTH=$(tput cols)
    AVAILABLE_WIDTH=$((TERM_WIDTH - 3))
    STATS_LINE=$(calculate_stats_line "$TEXT")

    draw_initial_screen
    update_text_display "$TEXT" "$TYPED_TEXT" "$CURRENT_POS"

    while (( CURRENT_POS < ${#TEXT} )); do
        read -rsn1 char
        if [[ $char == $'\e' ]]; then
            break
        fi

        if [[ $char == $'\177' || $char == $'\b' ]]; then
            if (( CURRENT_POS > 0 )); then
                local char_to_remove="${TYPED_TEXT:$((CURRENT_POS-1)):1}"
                local expected_char="${TEXT:$((CURRENT_POS-1)):1}"

                CURRENT_POS=$((CURRENT_POS - 1))
                TYPED_TEXT="${TYPED_TEXT:0:$CURRENT_POS}"

                if [[ "$char_to_remove" != "$expected_char" ]] && (( MISTAKES > 0 )); then
                    MISTAKES=$((MISTAKES - 1))
                fi
            fi
        else
            if [[ ${#char} -eq 0 ]]; then
                char=" "
            fi

            if [[ ${#char} -eq 1 ]]; then
                local expected_char="${TEXT:$CURRENT_POS:1}"
                TYPED_TEXT+="$char"

                if [[ "$char" != "$expected_char" ]]; then
                    MISTAKES=$((MISTAKES + 1))
                    TOTAL_MISTAKES=$((TOTAL_MISTAKES + 1))
                fi

                CURRENT_POS=$((CURRENT_POS + 1))

                if (( START_TIME == 0 )); then
                    START_TIME=$(date +%s)
                fi
            fi
        fi

        current_time=$(date +%s)
        time_elapsed=$((current_time - START_TIME))
        correct_chars=$((${#TYPED_TEXT} - MISTAKES))
        wpm_actual=$(calculate_wpm "$correct_chars" "$time_elapsed")
        accuracy=$(calculate_accuracy "$correct_chars" "${#TYPED_TEXT}")

        update_text_display "$TEXT" "$TYPED_TEXT" "$CURRENT_POS"
        update_stats_display "$wpm_actual" "$accuracy" "$STATS_LINE"
    done
}

reset_session() {
    TYPED_TEXT=""
    CURRENT_POS=0
    MISTAKES=0
    TOTAL_MISTAKES=0
    START_TIME=0

    TERM_WIDTH=0
    AVAILABLE_WIDTH=0
    STATS_LINE=0
}

show_results() {
    local end_time=$(date +%s)
    local total_time=$((end_time - START_TIME))
    local correct_chars=$((${#TYPED_TEXT} - MISTAKES))
    local wpm_actual=$(calculate_wpm "$correct_chars" "$total_time")
    local wpm_raw=$(calculate_wpm "${#TYPED_TEXT}" "$total_time")
    local cpm_actual=$(calculate_cpm "$correct_chars" "$total_time")
    local cpm_raw=$(calculate_cpm "${#TYPED_TEXT}" "$total_time")
    local accuracy=$(calculate_accuracy "$correct_chars" "${#TYPED_TEXT}")

    clear
    printf "\nResults\n"
    printf "========\n\n"
    printf "  Time: %d seconds\n" "$total_time"
    printf "  WPM: %.0f/%.0f (real/raw)\n" "$wpm_actual" "$wpm_raw"
    printf "  CPM: %.0f/%.0f (real/raw)\n" "$cpm_actual" "$cpm_raw"
    printf "  Accuracy: %.1f%%\n" "$accuracy"
    printf "  Characters typed: %d\n" "${#TYPED_TEXT}"
    printf "  Typos: %d\n" "$MISTAKES"
    printf "  Total typos: %d\n" "$TOTAL_MISTAKES"
    printf "\n"
}

main() {
    local repetitions=1

    if [[ $# -eq 1 ]]; then
        if [[ $1 =~ ^[0-9]+$ ]] && (( $1 > 0 )); then
            repetitions=$1
        else
            echo "Error: number_of_rounds should be >= 1"
            echo "Usage: $0 [number_of_rounds]"
            exit 1
        fi
    elif [[ $# -gt 1 ]]; then
        echo "Error: Too many arguments"
        echo "Usage: $0 [number_of_rounds]"
        exit 1
    fi

    if ! command -v bc &> /dev/null; then
        echo "Error: 'bc' calculator wasn't found."
        exit 1
    fi

    setup_terminal
    trap restore_terminal EXIT

    local completed_sessions=0
    local total_wpm_actual=0
    local total_wpm_raw=0
    local total_cpm_actual=0
    local total_cpm_raw=0
    local total_accuracy=0
    local total_time=0
    local total_chars_typed=0
    local total_typos=0

local session_num=1
    while (( session_num <= repetitions )); do
        reset_session

        handle_input

        if (( START_TIME > 0 )); then
            local session_completed=0

            if (( CURRENT_POS >= ${#TEXT} )); then
                session_completed=1
                completed_sessions=$((completed_sessions + 1))

                local end_time=$(date +%s)
                local session_time=$((end_time - START_TIME))
                local correct_chars=$((${#TYPED_TEXT} - MISTAKES))
                local session_wpm_actual=$(calculate_wpm "$correct_chars" "$session_time")
                local session_wpm_raw=$(calculate_wpm "${#TYPED_TEXT}" "$session_time")
                local session_cpm_actual=$(calculate_cpm "$correct_chars" "$session_time")
                local session_cpm_raw=$(calculate_cpm "${#TYPED_TEXT}" "$session_time")
                local session_accuracy=$(calculate_accuracy "$correct_chars" "${#TYPED_TEXT}")

                total_wpm_actual=$(echo "scale=2; $total_wpm_actual + $session_wpm_actual" | bc -l)
                total_wpm_raw=$(echo "scale=2; $total_wpm_raw + $session_wpm_raw" | bc -l)
                total_cpm_actual=$(echo "scale=2; $total_cpm_actual + $session_cpm_actual" | bc -l)
                total_cpm_raw=$(echo "scale=2; $total_cpm_raw + $session_cpm_raw" | bc -l)
                total_accuracy=$(echo "scale=2; $total_accuracy + $session_accuracy" | bc -l)
                total_time=$((total_time + session_time))
                total_chars_typed=$((total_chars_typed + ${#TYPED_TEXT}))
                total_typos=$((total_typos + MISTAKES))
            fi

            if (( repetitions > 1 )); then
                if (( session_completed == 1 )); then
                    printf "\n=== Results for Session %d ===\n" "$session_num"
                else
                    printf "\n=== Results for Session %d (Incomplete) ===\n" "$session_num"
                fi
            fi

            show_results

            if (( session_completed == 1 && session_num < repetitions )); then
                printf "Press any key to continue to next session...\n"
                read -rsn1
                session_num=$((session_num + 1))
            elif (( session_completed == 0 )); then
                break
            else
                session_num=$((session_num + 1))
            fi
        else
            break
        fi
    done

    if (( repetitions > 1 )); then
        printf "\n=== Summary ===\n"
        printf "Completed sessions: %d/%d\n" "$completed_sessions" "$repetitions"

        if (( completed_sessions > 0 )); then
            local avg_wpm_actual=$(echo "scale=1; $total_wpm_actual / $completed_sessions" | bc -l)
            local avg_wpm_raw=$(echo "scale=1; $total_wpm_raw / $completed_sessions" | bc -l)
            local avg_cpm_actual=$(echo "scale=1; $total_cpm_actual / $completed_sessions" | bc -l)
            local avg_cpm_raw=$(echo "scale=1; $total_cpm_raw / $completed_sessions" | bc -l)
            local avg_accuracy=$(echo "scale=1; $total_accuracy / $completed_sessions" | bc -l)

            printf "  Total time: %d seconds\n" "$total_time"
            printf "  Total characters typed: %d\n" "$total_chars_typed"
            printf "  Total typos: %d\n" "$total_typos"
            printf "  Average WPM: %.0f/%.0f (real/raw)\n" "$avg_wpm_actual" "$avg_wpm_raw"
            printf "  Average CPM: %.0f/%.0f (real/raw)\n" "$avg_cpm_actual" "$avg_cpm_raw"
            printf "  Average accuracy: %.1f%%\n" "$avg_accuracy"
        fi
        printf "\n"
    fi

    restore_terminal
}

main "$@"
