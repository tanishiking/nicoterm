# Requirements curl jq
# TODO: Refactoring

NICO_VIDEO_API_URL='http://api.search.nicovideo.jp/api/v2/video/contents/search'
NICO_VIDEO_WATCH_URL='http://www.nicovideo.jp/watch/'
LINES_PER_CONTENT=3

nicodo() {
  local line max_line char query
  local request_command
  local -A opts
  local url

  tput clear
  tput reset
  # Not to wrap output
  printf '\033[?7l'

  request_command="curl --silent '$NICO_VIDEO_API_URL?targets=title&fields=contentId,title,viewCounter,description&_sort=-viewCounter&_offset=0&_limit=10&_context=nicodo.zsh'"
  query=$@
  request_command="$request_command --data-urlencode q=$query"
  json_array=$(eval $request_command | jq '.data')
  echo $json_array | jq -r '.[] | "\(.contentId)\t\(.title)\n\(.description)\n--------------------------------"'
  tput cup 0 0

  while IFS= read -r -n1 -s char; do
    exec < /dev/tty
    oldstty=$(stty -g)
    stty raw -echo min 0
    tput sc
    echo '\033[6n' > /dev/tty
    tput rc
    # tput u7 > /dev/tty    # when TERM=xterm (and relatives)
    IFS=';' read -r -d R -a pos
    stty $oldstty
    row=$((${pos[0]:2} - 1))
    case $char in
      j)
        tput cud1
        continue
        ;;
      k)
        if [[ $row -gt 0 ]]; then
          # Move cursor up if not cursor on top
          tput cuu1
        fi
        continue
        ;;
      q)
        break
        ;;
      g)
        tput cup 0 0
        continue
        ;;
      o)
        if [[ `expr $row % $LINES_PER_CONTENT` != `expr $LINES_PER_CONTENT - 1` ]]; then
          # if cursor not on list divider
          content_id=$(echo $json_array | jq -r ".[`expr $row / $LINES_PER_CONTENT`] | .contentId")
          url="$NICO_VIDEO_WATCH_URL$content_id"
          open $url
        fi
        continue
        ;;
      *)
        continue
        ;;
    esac
  done
  # enable to wrap output
  printf '\033[?7h'
  tput reset
  tput clear
}


nicodo $@
