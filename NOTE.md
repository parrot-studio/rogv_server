READMEには書きたくないが、一応まとめないと困る何か
===============

なぜREADMEに書かないのか
---------------
システムの性質を考えればわかるじゃないですか・・・


一方で、複雑化してきたシステムに私の頭が追いつかなくなってきたし、
作者が追いつかないものを他の人が扱えるかというのも微妙なので、
「ここ」にメモっておく方向で


3つのモード
---------------
#### 本番モード（sample\_mode:false / view\_mode:false）
- 本番運用するためのモード
- 認証での保護に加え、クライアントからの更新もできる環境

 - Basic認証：有効
 - クライアントからの更新：可能
 - 管理系の利用：可能
 - 宣伝フッタ：非表示


#### 表示モード（sample\_mode:false / view\_mode:true）
- 本番データの表示のみをサポートしたモード
- 同盟先などとデータのみを共有する場合に使用

 - Basic認証：有効
 - クライアントからの更新：不能
 - 管理系の利用：不能
 - 宣伝フッタ：非表示


#### サンプルモード（sample\_mode:true）
- サンプル環境用モード
- http://parrot-studio.com/rogvs/ で公開するためのモード

 - Basic認証：無効
 - クライアントからの更新：不能
 - 管理系の利用：不能
 - 宣伝フッタ：表示


config/settings.yml
---------------
#### 概要
- YAML形式で記述
- クローズドに運用する前提でPASS等は平文で書くようになっている。他のシステムと共有しないこと
 - ブラウザツールバー等でPASSが漏れるリスクはあることも留意すべき
 - システムがhttpsで運用されるといいのだけど、趣味のシステムでそこまでは・・・
- v3.xまでの config.yml とは構造や名称が異なるため注意
 - 設定の意味は同一

#### 詳細
- env : 環境設定
 - server\_name : RO的な意味でのサーバ名。表示に使う
 - sample\_mode view\_mode : モード説明参照
 - attention\_minitues : 砦viewで強調表示するためのuptime。現在交戦中の可能性が高い場所を区別
 - result/recently\_size : 結果表示のデフォルトデータ数
 - result/min\_size result/max\_size : 結果表示の最小/最大データ数。負荷を考えて指定
- cache : キャッシュ関連設定。Gv中とその前後は無効化される
 - memcache : メモリキャッシュ（memcached）を利用するかの設定
 - db : ストレージキャッシュを利用するかの設定。管理ツールかscriptでキャッシュ削除
- db : mongodbへの接続情報
 - name : スキーマ名
- memcache : memcachedへの接続情報
 - header : memcached上の名前空間。同じものを指定するとキャッシュが混在する
- auth : 認証情報
 - basic : Basic認証情報。ページアクセスそのものを制御
 - admin : 管理ページ用認証情報
  - expire_sec : 管理系セッション有効時間（現状うまく動作しない？）
 - update_key : サーバ更新用key。Basic認証のIDとは別の長いものを設定する（※平文で扱われるので注意）
 - delete_key : データを削除するためのkey（※平文で扱われるので注意）
- viewer : rogv_viewerへの接続情報（設定不要）

config/config.yml（v3.x以下）
---------------
#### 概要
- v3.xまで使われていた設定ファイル
- v4.1をリリースする際に削除予定

#### 詳細
- server\_name：RO的な意味でのサーバ名。表示に使う
- attention\_minitues：砦viewで強調表示するためのuptime。現在交戦中の可能性が高い場所を区別
- db：mongodbへの接続情報
- auth/key：サーバ更新用key。Basic認証のIDとは別の長いものを設定する（※平文で扱われるので注意）
- auth/username auth/password：Basic認証情報
- auth/delete_key：データを削除するためのkey。廃止するかも（※平文で扱われるので注意）
- auth/sample\_mode auth/view\_mode：モード説明参照
- memcache/server memcache/port：memcachedへの接続情報
- memcache/header：memcached上の名前空間。同じものを指定するとキャッシュが混在する
- use\_cache：表示高速化キャッシュ（memcached）を利用するかの指定。Gv中とその前後は無効化される
- admin/user admin/pass：管理系にログインするための情報
- admin/expire\_sec：管理系セッション有効時間（現状うまく動作しない？）
- result/recently\_size：結果表示のデフォルトデータ数
- result/min\_size result/man\_size：結果表示の最小/最大データ数。負荷を考えて指定
- result/store：集計結果をmongodbにキャッシュするかの指定


script
---------------
#### 概要
- cronで各種処理を実行するためのもの
- 管理系で同じことができるようにするが、cronが使えるなら自動化できる
- 「RACK_ENV=production」指定のかわりに「-e production」指定が可能
- おそらく設置ディレクトリにcdしてから実行しないとおかしくなるかも

#### dumper.rb
mongodbのデータをdumpして固める。データは「dump/」以下に保存される。古いdumpの削除は管理系から

- -e ENV/--env=ENV：実行環境指定（デフォルトはdevelopment）

#### add_total.rb
未集計の新しい週データを集計する。未集計でも古いデータは処理されない。
「-d」指定されたら新しいかに関わらずその日を集計に追加する。

- -e ENV/--env=ENV：実行環境指定（デフォルトはdevelopment）
- -d DATE/--date=DATE：日付指定集計

#### total_rebuilder.rb
週次集計および全体集計を全てやり直す。
from指定した場合、その日以降を集計する。（例：統合以後のデータのみ集計したい）
手動で登録された結果データ（現在未実装）はクリアされない。

当初、管理画面からの実行を実装予定だったが、実行時間がかかるのと、
破壊的な更新を気軽に使えるのも望ましくないと考え、スクリプト実行のみとする

- -e ENV/--env=ENV：実行環境指定（デフォルトはdevelopment）
- -f DATE/--from=DATE：指定日以降を集計（集計データの削除は無関係に全て）
- -s/--silent：サイレントモード。確認や実行状況の表示をおこなわない

#### cache\_cleaner.rb
ストレージ保存キャッシュを全てクリアする。「cache/db:true」の環境でのみ使用。
memcachedと違い、mongodbへのキャッシュはいくらでも肥大化するため、それをクリアするためのもの

- -e ENV/--env=ENV：実行環境指定（デフォルトはdevelopment）


その他
---------------
- セキュリティに関してはかなりザル運用なので注意
 - クローズドで活用されることを前提にしているため
 - 万が一不正アクセスされても、被害は「ROでの優位性が損なわれる」レベルのため
- Basic認証をかけている以上、不正アクセスは犯罪です
- PASS等を他システムと共有することで起こるリスクはシステムの範囲外です

TODO
---------------
- 複数日をまたぐタイムラインの閲覧
- 共有ファイルUpload（リプレイなど）
- TEへの対応
 - 仕様がわからないとどうしようも・・・
 - おそらくはコードを共有する別システムを作る感じになる予定
 - 共通化はまた別途検討
