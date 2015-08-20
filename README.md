# kenpatsu

[![Join the chat at https://gitter.im/naoh16/kenpatsu](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/naoh16/kenpatsu?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
研発プログラムのウェブ閲覧システム

## ディレクトリ構成

  - ```scripts```
    - PDF等から発表データを抽出するためのスクリプト
  - ```viewer_app```
    - PhoneGapベースで開発しているWeb閲覧システム
  - ```viewer_app/www```
    - Apacheなどの/var/wwwとか~/public_html相当のディレクトリ
  - ```work```
    - scriptsのスクリプト群を実行する作業フォルダ
    - 著作権上の問題が起こりえるファイル群が入っているため、基本的にgitには同期しない

## 2015年春季版

作成中

## 2014年秋季版

  1. workフォルダにwordファイルから抽出したtxtファイル（2014autumn_program.txt）を用意する
  2. run.shを実行する（なおこのスクリプトは以下の作業を行っている）
    - ```scripts/asj_txt2csv.pl```を実行してasj2014a.jsonを作成
    - asj2014a.jsonを```viewer_app/www```以下に保存
  3. ```viewer_app/www/index.html```をWebブラウザ等で開く
    （ただし、```file:///```ではJSONファイルのロードに失敗することがある）
