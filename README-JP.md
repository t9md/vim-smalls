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

# 簡単な使い方
vimrc に以下の設定をする。
```Vim
    nmap s <Plug>(smalls)
```

文字がたくさん書かれたファイルを開く(マルチバイト文字のファイル以外。プログラムのソースコードが良い)。

1. Normal モードで `s` を押す。
2. 1文字入力, 続いて `;` (セミコロン) を入力。
3. ジャンプキーが表示されるので、到着したい目的地のキーを入力(ジャンプキーは大文字で表示されるが、小文字で入力で良い)
以上が、一番基本的な cli-mode での使い方。
ピンクのハイライトがデフォルトの着地点なので、ジャンプキーを表示させずに直接着地したい場合は、`<CR>`。

次は、もう一つのモードである excursion モードの使い方を説明する。

1. Normal モードで `s` を押す。
2. 1文字入力, 候補が表示される。`<Tab>`キーを押す。この時点で excursion-mode に入る。
3. jkhlやnpを押してみよう。候補間を移動できる。`v`, `V`, `<C-v>` で visual 選択も出来る。`d` で delete、`y` でヤンク。

果たしてコレは便利なのか？
デフォルトの `f` や `t` の方が速く、脳内のコンテキストスイッチも少ないので良い、という場面は多くあるでしょう。  
しかし、「現在位置から数行先の例えば `)` までを消したい(ビジュアル選択したい)といった場合は、smalls の操作に慣れれば標準の `d/` の組み合わせよりも(人によっては)楽になる可能性はあります。

# なぜ作ったか？
* 複数文字で検索して、一発で候補に飛びたい。
easymotion は 'word の先頭', 'word の終わり', '行' 等、移動前に移動先の性質を判断してから呼び出す必要があり、脳が疲れる。キータイプが少し増えてもいいからもう少し気楽に呼び出したい。また大画面では、複数文字で候補を絞り込んでからジャンプした方が結果的にキー入力が少なくて済む。
呼び出し前に移動先が、行か、word start か word end かを決定するなんて出来ない。
* forwad, backward はいらない。見えている window 全体を対象として移動したい。
要は一つのキーのみから呼び出したい。現在のカーソル位置から移動先への相対位置から forward, backward 判断してキーを選ぶのが疲れる。
* ジャンプの移動先を選ぶのに大文字押したくない。
Shift キーと組み合わせて大文字(Capital Letter)を入力したくない。小文字だけでジャンプ出来たほうが結果的に速い。
* しかし結果的には excursion-mode が副産物として出来たので、単なる search > easymotion style jump プラグインではなくなった。

# smalls-mode

smalls.vim には２つのモードがある。

| モード     | 説明         |
| ---------- |-------------|
| cli-mode   | <Plug>(smalls) で入るモード、候補の選択とジャンプ。`<C-e>`や`<Tab>`等を入力することで excursion-mode に入る |
| excursion-mode  | excursion (小旅行)モード。cli-mode で絞り込んだ候補間をjkhl で移動したり、`d`(削除), `y`(ヤンク)等を行う。|


## cli-mode
cli-mode のキーマップはデフォルトで以下の様になっている。  
後述するが、このキーバインドは全て変更可能。  

| *Key*          | *Action*                        | *Description*                       |
| <C-c>          | do_cancel                       | キャンセル                          |
| <Esc>          | do_cancel                       | キャンセル                          |
| <CR>           | do_jump_first                   | デフォルト候補に着地                |
| <C-h>          | do_delete                       | カーソル後方の文字を削除            |
| <BS>           | do_delete                       | カーソル後方の文字を削除
| <C-a>          | do_head                         | カーソルを行頭へ                    |
| <C-f>          | do_char_forward                 | カーソルを1文字進める               |
| <C-b>          | do_char_backward                | カーソルを1文字戻す                 |
| <C-k>          | do_kill_to_end                  | 行末まで削除してyank                |
| <C-u>          | do_kill_line                    | 行をクリアしてyank                  |
| <C-r>          | do_special                      | 実験的機能(意味なし)                |
| <C-e>          | do_excursion                    | excursion-mode に入る               |
| <C-d>          | do_excursion_with_delete        | excursion-mode の delete            |
| <C-y>          | do_excursion_with_yank          | excursion-mode の yank              |
| V              | do_excursion_with_select_V      | excursion-mode の select_V          |
| <C-v>          | do_excursion_with_select_CTRL_V | excursion-mode の select_CTRL_V     |
| <Tab>          | do_excursion_with_next          | excursion-mode の next              |
| <C-n>          | do_excursion_with_next          | excursion-mode の next              |
| <S-Tab>        | do_excursion_with_prev          | excursion-mode の prev              |
| <C-p>          | do_excursion_with_prev          | excursion-mode の prev              |
| {jump_trigger} | do_jump                         | ジャンプキーを表示(デフォルトは`;`) |

## excursion-mode

| *Key*   | *Action*         | *Description*         |
| <C-c>   | do_cancel        | キャンセル            |
| <C-e>   | do_back_cli      | cli-mode へ戻る       |
| <Esc>   | do_back_cli      | cli-mode へ戻る       |
| n       | do_next          | 次の着地候補へ        |
| <Tab>   | do_next          | 次の着地候補へ        |
| p       | do_prev          | 前の着地候補へ        |
| <S-Tab> | do_prev          | 前の着地候補へ        |
| k       | do_up            | 上の着地候補へ        |
| j       | do_down          | 下の着地候補へ        |
| h       | do_left          | 左の着地候補へ        |
| l       | do_right         | 右の着地候補へ        |
| d       | do_delete        | 着地候補までを delete |
| <C-d>   | do_delete        | 着地候補までを delete |
| y       | do_yank          | 着地候補までを yank   |
| <C-y>   | do_yank          | 着地候補までを yank   |
| v       | do_select_v      | 着地候補までを v      |
| V       | do_select_V      | 着地候補までを V      |
| <C-v>   | do_select_CTRL_V | 着地候補までを CTRL_V |
| ;       | do_set           | 着地候補に着地        |
| <CR>    | do_set           | 着地候補に着地        |

# カスタマイズ

TODO

# FAQ

## excursion-mode に入った事が視覚的に分かりにくい。
A. 
* 慣れる。
* カーソルの色を変える拡張実装がされるのを待つ。
* ステータスラインの下の `[Excursion]` を視る。
* [vim-ezbar](https://github.com/t9md/vim-ezbar) を使用し、設定例を参考にステータスバーの色ごと変えることで気付き易くする。

## `d` の operator モードから呼び出した時、word の末尾の文字が消されずに残る。
`g:smalls_operator_always_inclusive = 1`する事で変更可能です。
副作用があるため、この設定は非推奨です。
`:help g:smalls_operator_always_inclusive` に詳細が書かれています。
それよりは、`dvs` や `dVs` で operator のモーション-wise を明示的に指定する方が良いです。
あるいは、normal モードから smalls に入り、excursion モードから `d` したり、cli-mode から `<C-d>` で直接消す方が良いかもしれません。

## キーバインドをカスタマイズしたい。
A.
`:help smalls-example` に載っています。
ここでも例を示します。
一部のみ変更する場合は以下。

```Vim
  let cli_table_custom = {
        \ "\<C-g>": 'do_cancel',
        \ "\<C-j>": 'do_jump',
        \ }
  " 以下は cli-mode のキーテーブルを変更。同様に smalls#keyboard#excursion もある。
  call smalls#keyboard#cli#extend_table(cli_table_custom)
```

`smalls#keyboard#excursion#replace_table(table)` を使えば、キーテーブルを丸ごと入れ替えることも可能。
以下を設定すると、excursion モードでは何もしなくなる。

```Vim
call smalls#keyboard#excursion#replace_table({}
```
