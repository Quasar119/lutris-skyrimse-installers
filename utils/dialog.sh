#!/bin/bash

dialogtype=$1; shift

if [ -n "$FORCE_INTERFACE" ]; then
	interface=$FORCE_INTERFACE
elif [ -n "$(command -v zenity)" ]; then
	interface="zenity"
elif [ -n "$(command -v xmessage)" ]; then
	interface="xmessage"
elif [ -n "$(command -v xterm)" ]; then
	interface="xterm"
else
	echo "ERROR: no interface available. Make sure zenity or xmessage or xterm are installed on the system"
	exit 1
fi

errorbox() {
	message=$1; shift
	case "$interface" in
		zenity)
			zenity --ok-label=Exit --ellipsize --error --text "$message"
			;;
		xmessage)
			xmessage -buttons exit:1 "ERROR: $message"
			;;
		xterm)
			xterm -e bash -c "
				echo 'ERROR: $message'
				echo
				echo -n 'Press enter to exit. '
				read
			"
			;;
	esac

	return 1
}

infobox() {
	message=$1; shift
	case "$interface" in
		zenity)
			zenity --ok-label=Continue --ellipsize --info --text "$message"
			;;
		xmessage)
			xmessage -buttons continue:0 "$message"
			;;
		xterm)
			xterm -e bash -c "
				echo '$message'
				echo
				echo -n 'Press enter to continue. '
				read
			"
			;;
	esac

	return 0
}

warnbox() {
	message=$1; shift
	case "$interface" in
		zenity)
			zenity --ok-label=Continue --ellipsize --warning --text "$message"
			;;
		xmessage)
			xmessage -buttons continue:0 "WARNING: $message"
			;;
		xterm)
			xterm -e bash -c "
				echo 'WARNING: $message'
				echo
				echo -n 'Press enter to continue. '
				read
			"
			;;
	esac
}

directorypicker() {
	message=$1; shift
	case "$interface" in
		zenity)
			finish_selection="false"
			selection_entry=""
			while [ "$finish_selection" != "true" ]; do
				raw_entry=$(zenity --entry --entry-text="$selection_entry" --extra-button="Browse" --text "$message"); confirm=$?
				eval selection_entry="$raw_entry"

				case "$confirm" in
					0)
						if [ ! -d "$selection_entry" ]; then
							zenity --error --ellipsize --text="Directory '$selection_entry' does not exist"
						else
							finish_selection=true
						fi
						;;
					1)
						if [ "$selection_entry" == "Browse" ]; then
							selection_entry=$(zenity --file-selection --directory)
						else
							finish_selection=true
						fi
						;;
				esac
			done

			if [ "$confirm" == "0" ]; then
				echo $(realpath "$selection_entry")
			fi

			return $confirm
			;;

		xmessage|xterm)
			tmpfile=$(mktemp /tmp/file-selection-XXXX)
			xterm -e bash -c "
				finish_selection='false'
				while [ \"\$finish_selection\" != 'true' ]; do
					echo '$message'
					echo 'Type the directory path (or leave empty to cancel) and press enter:'
					read raw_entry
					eval selection_entry=\"\$raw_entry\"

					if [ -z \"\$selection_entry\" ]; then
						exit 1
					elif [ ! -d \"\$selection_entry\" ]; then
						echo -e \"\nERROR: Directory '\$selection_entry' does not exist\n\"
					else
						echo \$(realpath \"\$selection_entry\") > $tmpfile
						finish_selection='true'
					fi
				done
			"; confirm=$?

			if [ "$confirm" == "0" ]; then
				cat $tmpfile
				rm $tmpfile
			fi

			return $confirm
			;;
	esac
}

textentry() {
	message=$1; shift
	default_value=$1; shift
	case "$interface" in
		zenity)
			entry_value=$(zenity --entry --entry-text="$default_value" --text "$message"); confirm=$?

			if [ "$confirm" == "0" ]; then
				echo "$entry_value"
			fi

			return $confirm
			;;
		xmessage|xterm)
			tmpfile=$(mktemp /tmp/text-entry-XXXX)
			xterm -e bash -c "
				echo '$message'
				echo 'Type (or leave empty to cancel) and press enter:'
				read entry_value

				if [ -z \"\$entry_value\" ]; then
					exit 1
				else
					echo \"\$entry_value\" > $tmpfile
				fi
			"; confirm=$?

			if [ "$confirm" == "0" ]; then
				cat $tmpfile
				rm $tmpfile
			fi

			return $confirm
			;;
	esac
}

$dialogtype "$@"
exit $?

