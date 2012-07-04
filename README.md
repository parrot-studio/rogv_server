ROGv - Forts Watching System : Server
===============

Description
---------------
ROのGvGにおいて、「現状」を把握するためのシステム「ROGv」のサーバ側です。
以下の技術が使われています。

- Ruby(1.9.2以降で確認)
- Padrino（ver1.xはSinatra）
- memcached
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
#### ver2.2
- Gv時間とその前後1時間はキャッシュを利用しないように修正

#### ver2.1
- 一部でPadrino::Cacheを使うように修正
- Cacheの使用設定をconfigに追加
- ギルド単体のTimeline閲覧時、マルチバイトが正しくdecodeされていなかったのを修正

#### ver2.0
- 基盤をSinatraからPadrinoに変更
- バグ：ギルド単体のTimelineが閲覧できない（ver2.1で修正）

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
