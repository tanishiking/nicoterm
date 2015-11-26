# Requirements curl jq
# TODO: Refactoring

NICO_VIDEO_API_URL='http://api.search.nicovideo.jp/api/v2/video/contents/search'
NICO_VIDEO_WATCH_URL='http://www.nicovideo.jp/watch/'
LINES_PER_CONTENT=4
SCREEN_LINES=`expr $(tput lines) - 1`
LIMIT=`expr $SCREEN_LINES / $LINES_PER_CONTENT`
MAX_LINE=`expr $LINES_PER_CONTENT \* $LIMIT - $LINES_PER_CONTENT`
DISABLE_WRAP='\033[?7l'
ENABLE_WRAP='\033[?7h'
TARGETS='title,description,tags'
FIELDS='contentId,title,viewCounter,mylistCounter,commentCounter,description'
ORDER_BY_MYLIST='-mylistCounter'
ORDER_BY_VIEW='-viewCounter'
ORDER_BY_COMMENT='-commentCounter'
ORDER=$ORDER_BY_MYLIST

function get_jsonarray() {
  local offset=$1
  local query=$2
  local request_command content_id description view_counter
  request_command="curl --silent '$NICO_VIDEO_API_URL?targets=$TARGETS&fields=$FIELDS&_sort=$ORDER&_offset=$offset&_limit=$LIMIT&_context=nicoterm'"
  request_command="$request_command --data-urlencode q=$query"
  json_array=$(eval $request_command | jq '.data')
  echo $json_array | jq -r '.[] | .title, .description, .viewCounter, .mylistCounter, .commentCounter' | \
    while IFS= read -r title
               read -r description
               read -r view_counter
               read -r mylist_counter
               read -r comment_counter; do
      echo "$title"
      echo "$description"
      echo "再生数:$view_counter\tﾏｲﾘｽﾄ数:$mylist_counter\tｺﾒﾝﾄ数:$comment_counter"
      echo
    done
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
  printf $DISABLE_WRAP
  get_jsonarray $offset $query
  show_footer $current_page $query
  printf $ENABLE_WRAP
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
  local current_page=0
  local cursor_pos=0
  local content_id url query

  if [[ $# -eq 0 ]]; then
    show_usage
    exit 0
  fi
  for opt in "$@"; do
    case "$opt" in
      '-h'|'--help')
        show_usage
        exit 0
        ;;
      '-oc'|'--order-by-comment')
        ORDER=$ORDER_BY_COMMENT
        shift 1
        ;;
      '-ov'|'--order-by-view')
        ORDER=$ORDER_BY_VIEW
        shift 1
        ;;
      '-om'|'--order-by-mylist')
        ORDER=$ORDER_BY_MYLIST
        shift 1
        ;;
      -*)
        echo "$PROGNAME: illegal option -- '$(echo $1 | sed 's/^-*//')'" 1>&2
        exit 1
        ;;
      *)
        if [[ ! -z "@1" ]] && [[ ! "&1" =~ ^-+ ]]; then
          query=$1
          shift 1
        fi
    esac
  done

  tput clear
  tput reset
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
  tput reset
  tput clear
}

function show_usage() {
  echo "Usage: $0 [OPTIONS] query"
  echo
  echo "OPTIONS:"
  echo "  --help, -h"
  echo "    Show help"
  echo "  --order-by-mylist, -om"
  echo "    Order search results by mylist counter desc (default)"
  echo "  --order-by-comment, -oc"
  echo "    Order search results by comment counter desc"
  echo "  --order-by-view, -ov"
  echo "    Order search results by view counter desc"
}

nicodo $@
