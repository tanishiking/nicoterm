# Requirements curl jq
# TODO: Refactoring

NICO_VIDEO_API_URL='http://api.search.nicovideo.jp/api/v2/video/contents/search'
NICO_VIDEO_WATCH_URL='http://www.nicovideo.jp/watch/'
LINES_PER_CONTENT=3

get_json_and_show() {
  local request_command
  tput clear
  request_command="curl --silent '$NICO_VIDEO_API_URL?targets=title&fields=contentId,title,viewCounter,description&_sort=-viewCounter&_offset=$OFFSET&_limit=$LIMIT&_context=nicodo.zsh'"
  request_command="$request_command --data-urlencode q=$query"
  json_array=$(eval $request_command | jq '.data')
  echo $json_array | jq -r '.[] | "\(.contentId)\t\(.title)\n\(.description)\n--------------------------------"'
  echo "Current page: `expr $current_page + 1` || Query: $query"
  tput cup 0 0
}

open_url() {
  url=$1
  if which xdg-open > /dev/null; then
    xdg-open $url
  elif which gnome-open > /dev/null; then
    gnome-open $url
  elif which open > /dev/null; then
    open $url
  else
    tput reset
    tput clear
    echo "Cannot detect (xdg-open | gnome-open | open) command" 1>&2
    exit 1
  fi
}

nicodo() {
  local line char query
  local url next_page

  tput clear
  tput reset
  # Not to wrap output
  printf '\033[?7l'

  SCREEN_LINES=`expr $(tput lines) - 1`
  LIMIT=`expr $SCREEN_LINES / $LINES_PER_CONTENT`
  MAX_LINE=`expr $LINES_PER_CONTENT \* $LIMIT - 1`

  current_page=0
  OFFSET=0

  query=$@
  get_json_and_show

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
        if [[ $row -lt `expr $MAX_LINE - $LINES_PER_CONTENT` ]]; then
          # Move cursor down if not cursor on bottom
          tput cud $LINES_PER_CONTENT
        fi
        ;;
      k)
        if [[ $row -gt 0 ]]; then
          # Move cursor up if not cursor on top
          tput cuu $LINES_PER_CONTENT
        fi
        ;;
      l)
        next_page=`expr $current_page + 1`
        current_page=`expr $current_page + 1`
        OFFSET=`expr $next_page \* $LIMIT`
        get_json_and_show
        ;;
      h)
        if [[ $current_page -gt 0 ]]; then
          prev_page=`expr $current_page - 1`
          current_page=`expr $current_page - 1`
          OFFSET=`expr $prev_page \* $LIMIT`
          get_json_and_show
        fi
        ;;
      q)
        break
        ;;
      g)
        tput cup 0 0
        ;;
      G)
        tput cup $MAX_LINE 0
        ;;
      o)
        content_id=$(echo $json_array | jq -r ".[`expr $row / $LINES_PER_CONTENT`] | .contentId")
        url="$NICO_VIDEO_WATCH_URL$content_id"
        open_url $url
        ;;
      *)
        ;;
    esac
  done
  # enable to wrap output
  printf '\033[?7h'
  tput reset
  tput clear
}


nicodo $@