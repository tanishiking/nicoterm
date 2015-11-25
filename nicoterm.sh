# Requirements curl jq
# TODO: Refactoring

NICO_VIDEO_API_URL='http://api.search.nicovideo.jp/api/v2/video/contents/search'
NICO_VIDEO_WATCH_URL='http://www.nicovideo.jp/watch/'
LINES_PER_CONTENT=3
SCREEN_LINES=`expr $(tput lines) - 1`
LIMIT=`expr $SCREEN_LINES / $LINES_PER_CONTENT`
MAX_LINE=`expr $LINES_PER_CONTENT \* $LIMIT - $LINES_PER_CONTENT`
DISABLE_WRAP='\033[?7l'
ENABLE_WRAP='\033[?7h'

function get_jsonarray() {
  local offset=$1
  local query=$2
  local request_command
  request_command="curl --silent '$NICO_VIDEO_API_URL?targets=title&fields=contentId,title,viewCounter,description&_sort=-viewCounter&_offset=$offset&_limit=$LIMIT&_context=nicoterm'"
  request_command="$request_command --data-urlencode q=$query"
  json_array=$(eval $request_command | jq '.data')
  echo $json_array | jq -r '.[] | "\(.contentId)\t\(.title)\n\(.description)\n--------------------------------"'
}

function show_footer() {
  local current_page=$1
  local query=$2
  echo "Current page: `expr $current_page + 1` || Query: $query"
}

function show_page() {
  local query=$1
  local current_page=$2
  local offset=`expr $current_page \* $LIMIT`
  tput clear
  get_jsonarray $offset $query
  show_footer $current_page $query
  tput cup 0 0
}

function open_url() {
  local url=$1
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

function nicodo() {
  local query=$@
  local current_page=0
  local cursor_pos=0
  local content_id url

  tput clear
  tput reset
  # Not to wrap output
  printf $DISABLE_WRAP

  show_page $query $current_page

  while IFS= read -r -n1 -s char; do
    case $char in
      j)
        if [[ $cursor_pos -lt $MAX_LINE ]]; then
          # Move cursor down if not cursor on bottom
          cursor_pos=`expr $cursor_pos + $LINES_PER_CONTENT`
          tput cud $LINES_PER_CONTENT
        fi
        ;;
      k)
        if [[ $cursor_pos -gt 0 ]]; then
          # Move cursor up if not cursor on top
          cursor_pos=`expr $cursor_pos - $LINES_PER_CONTENT`
          tput cuu $LINES_PER_CONTENT
        fi
        ;;
      l)
        current_page=`expr $current_page + 1`
        cursor_pos=0
        show_page $query $current_page
        ;;
      h)
        if [[ $current_page -gt 0 ]]; then
          current_page=`expr $current_page - 1`
          cursor_pos=0
          show_page $query $current_page
        fi
        ;;
      q)
        break
        ;;
      g)
        cursor_pos=0
        tput cup 0 0
        ;;
      G)
        cursor_pos=$MAX_LINE
        tput cup $MAX_LINE 0
        ;;
      o)
        content_id=$(echo $json_array | jq -r ".[`expr $cursor_pos / $LINES_PER_CONTENT`] | .contentId")
        url="$NICO_VIDEO_WATCH_URL$content_id"
        open_url $url
        ;;
      *)
        ;;
    esac
  done
  printf $ENABLE_WRAP
  tput reset
  tput clear
}

nicodo $@
