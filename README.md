# nicoterm
Search niconico video from your terminal!

[niconico コンテンツ検索API](http://search.nicovideo.jp/docs/api/search.html)

[![https://gyazo.com/c4828651673a270fcb598f2df1171da1](https://i.gyazo.com/c4828651673a270fcb598f2df1171da1.gif)](https://gyazo.com/c4828651673a270fcb598f2df1171da1)

## Requirements
- [jq](https://stedolan.github.io/jq/)
- [curl](http://curl.haxx.se/)
- [open(osx)](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/open.1.html) | gnome-open | xdg-open

## Usage
`./nicoterm.sh [OPTIONS] query`
```
OPTIONS:
  --help, -h
    Show help
  --order-by-mylist, -m
    Order search results by mylist counter desc (default)
  --order-by-comment, -c
    Order search results by comment counter desc
  --order-by-view, -v
    Order search results by view counter desc
  --order-by-arrival-date, -a
    Order search results by arrival date
```

- j|C-n: cursor down
- k|C-p: cursor up
- l|C-b: go to next page
- h|C-f: go to prev page
- g: move cursor to top
- G: move cursor to bottom
- o: open cursor video
- q: quit
