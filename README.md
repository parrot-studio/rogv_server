ROGv - Forts Watching System : Server
===============

Attention!!
---------------
すでに開発は終了しております。
後継システム「Gagnrath」をご利用ください。

https://github.com/parrot-studio/gagnrath

Description
---------------
ROのGvGにおいて、「現状」を把握するためのシステム「ROGv」のサーバ側です。
以下の技術が使われています。

- Ruby(1.9.3で確認 / 2.0.0での動作は確認しているが、現時点では保証しない)
- Padrino（ver1.xはSinatra）
- memcached
- MongoDB

EAQ(Expected Asked Questions)
---------------
### どうやって構築するのですか？

設置後にsetting.ymlを書き換えでOK。
細かい設置方法は以下のサイトでどうぞ。

http://www.google.co.jp/

### データはどこから持ってくるのですか？

https://github.com/parrot-studio/rogv_client

ChangeLog
---------------
ChangeLog.md 参照

License
---------------
The MIT License

see LICENSE file for detail

Author
---------------
ぱろっと(@parrot_studio / parrot.studio.dev at gmail.com)
