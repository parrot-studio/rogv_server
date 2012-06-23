ROGv - Forts Watching System : Server
===============

Description
---------------
ROのGvGにおいて、「現状」を把握するためのシステム「ROGv」のサーバ側です。
以下の技術が使われています。

- Ruby(1.9.2以降で確認)
- Sinatra
- memcached（現行バージョンでは利用せず）
- MongoDB

Sample Site
---------------
http://parrot-studio.com/rogvs/

EAQ(Expected Asked Questions)
---------------
### どうやって構築するのですか？

設置後にconfig.ymlを書き換えでOK。
細かい設置方法は以下のサイトでどうぞ。

http://www.google.co.jp/

### データはどこから持ってくるのですか？

https://github.com/parrot-studio/rogv_client

ChangeLog
---------------
#### ver1.2
- dump系の仕組みを追加
- ディレクトリ構造を変更

#### ver1.1
- 複数の更新クライアントを考慮した処理に変更
- データ割り込みを追加
- 参照専用モードを追加

#### ver1.0
- 公開版

License
---------------
The MIT License

see LICENSE file for detail

Author
---------------
ぱろっと(@parrot_studio / parrot.studio.dev at gmail.com)
