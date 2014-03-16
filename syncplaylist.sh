#!/usr/bin/env bash

# Define base directories.
LOCAL_MUSIC=${HOME}/Music/music
EXTERN=/mnt/wdr3600/music/benny


# Iterate over command line switches.
while :
do
  case $1 in
    -h | --help | -\?)
      echo -e "Command \"syncplaylist playlist.3mu\" syncronizes playlist.3mu."\
            "If no playlist is given the last playlist of moc player"\
            "is syncronized.\n"
      echo -e "-e directory \tExtern directory to syncronize."
      echo -e "-l directory \tLocal directory to syncronize."
      exit 0      # This is not an error, User asked help. Don't do "exit 1"
      ;;
    -e | --extern-dir)
      EXTERN="$2"
      if [ ! -d "$EXTERN" ]; then 
        echo "Extern directory \"$LOCAL_MUSIC\" does not exist."
        exit 1
      fi
      shift 2
      ;;
    -l | --local-dir)
      LOCAL_MUSIC="$2"
      if [ ! -d "$LOCAL_MUSIC" ]; then 
        echo "Local directory \"$LOCAL_MUSIC\" does not exist."
        exit 1
      fi
      shift 2
      ;;
    -* | --*)
      echo "Unknown option \"$1\". Execution stopped."
      exit 1
      ;;
    *)  # no more options. Stop while loop
      break
      ;;
  esac
done


# If no playlist given sync last songs from moc player.
if [ -z $1 ]; then
  set -- $1 ${HOME}/.moc/playlist.m3u
fi

# Create temp files for playlist manipulation.
TEMP=$(mktemp)
TEMP2=$(mktemp)


# Iterate through given playlists.
for LIST in "$@"; do
  echo -e "\e[1;33mUPDATING playlist $LOCAL_PLAYLIST on ${EXTERN}.\e[0m"
  SONG_COUNT=0
  EXTERN_PLAYLIST=${EXTERN}/playlists/$(basename "$LIST")

  # Remove comments and DOS newlines from playlist.
  sed '/^#/ d' $LIST > $TEMP
  tr -d '\015' < $TEMP > $TEMP2
  SONG_MAX=$(wc -l "$TEMP2" | cut -d' ' -f1)

  # Clear temp file.
  > "$TEMP"

  # Use rsync to syncronize music files and copy playlist to extern music
  # disk.
  while read -r song; do
    echo -e "\n\n\e[1;36m${SONG_COUNT}/${SONG_MAX}: Syncing ${song}"
    echo -e "to ${EXTERN}.\e[0m"
    # The --temp-dir is a workaround for curlftps error with file permissions.
    # TODO: Check if curlftp used or not.
    rsync -vPh --temp-dir=/var/tmp/rsync --modify-window=1 --size-only "$song" "$EXTERN"
    basename "$song" >> "$TEMP"
    SONG_COUNT=$(($SONG_COUNT + 1))
  done < "$TEMP2"

  if [ ! -d "${EXTERN}/playlists" ]; then 
    mkdir "${EXTERN}/playlists"
  fi
  sed -i -e 's:^:../:' "$TEMP"
  mv "$TEMP" "$EXTERN_PLAYLIST"

  echo -e "\e[1;33m${SONG_COUNT} songs synced.\e[0m"
  echo -e "\e[1;33mUPDATED playlist $LIST on ${EXTERN}.\e[0m\n\n"
done

rm -f $TEMP $TEMP2

