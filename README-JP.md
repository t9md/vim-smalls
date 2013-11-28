# まず最初に


[vim-easymotion](https://github.com/Lokaltog/vim-easymotion) という素晴らしいプラグインを作られた Lokaltog 氏に感謝します。  
Lokaltog 氏が考えたアイデアとコードの土台がなければ smalls は決して作れませんでした。

# コレは何？
カーソル移動プラグインの一つ。  
大きく、以下の２つの特徴を持つ。

* cli-mode
文字列を検索して easymotion スタイルでジャンプ

* excursion-mode
delete, yank 等の operator と組み合わせて使用する motion。operator の作用範囲を視覚化出来る点が特徴

基本的な方針として、現在の Window 内で見えている範囲を対象とする(つまり、スクロールはしない)。  

## 特徴
* easymotion スタイルで直接目的地にジャンプ
* forward, backward の区別なく、常に window 内全体を移動候補対処とする。(forwad, backwardを適切に選択する脳の疲れが無い。)
* ジャンプキーの選択は常に大文字小文字が無視される。Shift キーを押す脳の疲れを軽減 (大文字で目立たせてジャンプキーを出し、小文字で選択)。
* fold された範囲を移動候補からスキップ(デフォルトの '/, ?' でカーソルが fold に埋もれてしまう恐怖、苛立ちから開放)
* normal, visual, operator モードから呼び出し可能。
* visual, operator モードでは、作用範囲をハイライトして視覚化。例えば、d の作用範囲を見た目で確認しながら決定。
* 移動候補間を jkhlnp 等のキーで自由に移動( excursion-mode )
* cli-mode, excursion-mode それぞれで、どのキーがどの動作になるか、というキーバインドをフルカスタマイズ可能。
* cli-mode から excursion-mode のアクションを直接呼び出し可能。( _action_missing() fook による。)
* 一定時間キー入力がない場合に、easymotion スタイルのジャンプキーを自動表示
* ジャンプキーの自動表示が発動する最低文字数は変更可能(例: 最低3文字を超えてから有効にする。)
* 色のカスタマイズ

# 動画
![Movie](http://gifzo.net/NBDnZVtDNJ.gif)

# 設定例

    " Normal モードの 's' で発動
    nmap s <Plug>(smalls)
    " visual モードや、operator モードからも呼び出したい場合は以下も設定する。
    omap s <Plug>(smalls)
    xmap s <Plug>(smalls)


# 関連性の高いプラグイン
このプラグインは合わない？問題なしです！以下のプラグインを試してみてください。

* [easymotion](https://github.com/Lokaltog/vim-easymotion)
* [clever-f](https://github.com/rhysd/clever-f.vim)
* [sneak](https://github.com/justinmk/vim-sneak)
