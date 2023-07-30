#!/usr/bin/env bash

function SetupColors
{
	DEFAULT='\033[00m'
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	YELLOW='\033[0;33m'
	BLUE='\033[0;34m'
}

function SetupTestData
{
	echo -e "$BLUE Setting up test data $DEFAULT"
	git clone --depth=1 https://github.com/neomutt/sample-mail
	export DEMO_DIR=$PWD/sample-mail
	echo -e "$BLUE DEMO_DIR is $DEMO_DIR (but tmux needs work to inherit this, see NEOMUTT_TMUX_SERVER)$DEFAULT"
}

function SetupTestEnv
{
	SetupColors
	echo -e "$BLUE Setting up test env"
	# https://stackoverflow.com/questions/8645053/how-do-i-start-tmux-with-my-current-environment#comment23100473_8645053
	NEOMUTT_TMUX_SERVER="neomutt_test_server_$$"
	NEOMUTT_TMUX_SESSION="neomutt_test_session_$$"
	NEOMUTT_BINARY=neomutt

	CAPTURE_DIR="/tmp/$$.NEOMUTT.CAPTURES"
	echo -e "$BLUE Captures in $CAPTURE_DIR"
	mkdir -p $CAPTURE_DIR
	FAILURE=false
}

function capture_compare
{
	echo -e "$YELLOW Test case $1 $DEFAULT"
	CAPTURE_FILE="$CAPTURE_DIR/$1"

	tmux -L $NEOMUTT_TMUX_SERVER capture-pane -p -e -t $NEOMUTT_TMUX_SESSION > $CAPTURE_FILE
	if ! diff --side-by-side --suppress-common-lines $CAPTURE_FILE master/$1 
	then
		echo -e $RED "❌ $1"
		FAILURE=true
	else 
		echo -e $GREEN "✅ $1"
	fi
	echo -e "$DEFAULT"
}

function SendKeysToTmuxSession
{
	tmux -L $NEOMUTT_TMUX_SERVER send-keys -t $NEOMUTT_TMUX_SESSION $@
	sleep 0.5	
}

function CleanUp
{
	# Last session would automatically kill socket so all good
	tmux -L $NEOMUTT_TMUX_SERVER kill-session -t $NEOMUTT_TMUX_SESSION
	rm -rf sample-mail
	echo -e "$BLUE Exiting, cleaning up"
	if $FAILURE
	then
		echo -e "$RED There were failures, see $CAPTURE_DIR"
	fi
}

function StartTmux
{
	tmux -L $NEOMUTT_TMUX_SERVER -u new-session -d -x 120 -y 50 -s $NEOMUTT_TMUX_SESSION
	echo -e "${BLUE} tmux started on $NEOMUTT_TMUX_SESSION"
}

trap 'CleanUp' SIGINT SIGTERM EXIT


SetupTestEnv
SetupTestData
StartTmux

function DoTesting
{
	# Initial View
	SendKeysToTmuxSession 'neomutt' SPACE '-F' SPACE 'sample-mail/demo.rc' ENTER

	SendKeysToTmuxSession ENTER

	capture_compare initial

	SendKeysToTmuxSession C-n C-n C-o

	capture_compare chrysler
	capture_compare blahblahblah
}

DoTesting

# Folder Pane, open
# SendKeysToTmuxSession DOWN
# SendKeysToTmuxSession DOWN
# SendKeysToTmuxSession C-Right
# 
# capture_compare folder_pane_open
# 
# # Folder Pane, closed
# SendKeysToTmuxSession Escape
# 
# capture_compare folder_pane_closed
# 
# # Fuzzy file search
# SendKeysToTmuxSession 112
# 
# capture_compare file_fuzzy
# 
# # File contents
# SendKeysToTmuxSession C-Right
# 
# capture_compare file_contents
# 
# SendKeysToTmuxSession Escape
# SendKeysToTmuxSession Escape
# 
# # Page down
# SendKeysToTmuxSession x
# SendKeysToTmuxSession ENTER
# SendKeysToTmuxSession PageDown
# SendKeysToTmuxSession PageDown
# 
# capture_compare page_down
# 
# # Page up
# SendKeysToTmuxSession PageUp
# 
# capture_compare page_up
# 
# 
# # Copy
# TestCopy
# 
# # Print path
# SendKeysToTmuxSession :print_path ENTER
# 
# capture_compare print_path
# 
# 
# 
# 
# rm -rf a
