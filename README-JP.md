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
* forward, backward の区別なく、常に window 内全体を着地先の候補対象とする。(forwad, backwardを適切に選択する脳の疲れが無い。)
* ジャンプキーの選択は常に大文字小文字が無視される。Shift キーを押す脳の疲れを軽減 (大文字で目立たせてジャンプキーを出し、小文字で選択)。
* fold された範囲を移動候補からスキップ(デフォルトの '/, ?' でカーソルが fold に埋もれてしまう恐怖、苛立ちから開放)
* normal, visual, operator モードから呼び出し可能。
* visual, operator モードでは、作用範囲をハイライトして視覚化。例えば、d の作用範囲を見た目で確認しながら決定。
* 着地候補間を jkhlnp 等のキーで自由に移動( excursion-mode )
* cli-mode, excursion-mode それぞれで、どのキーがどの動作になるか、というキーバインドをフルカスタマイズ可能。
* cli-mode から excursion-mode のアクションを直接呼び出し可能。( `_action_missing()` hook )
* 一定時間キー入力がない場合に、easymotion スタイルのジャンプキーを自動表示(ただしタイマーはエミュレートなのでキー入力への反応が鈍くなる)。
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
3. ジャンプキーが表示されるので、到着したい目的地のキーを入力  
(ジャンプキーは大文字で表示されるが、小文字で入力で良い)

以上が、一番基本的な cli-mode での使い方。
ピンクのハイライトがデフォルトの着地点なので、ジャンプキーを表示させずに直接着地したい場合は、`<CR>`。

次は、もう一つのモードである excursion モードの使い方を説明する。

1. Normal モードで `s` を押す。
2. 1文字入力, 候補が表示される。`<Tab>`キーを押す。この時点で excursion-mode に入る。
3. jkhlやnpを押してみよう。候補間を移動できる。`v`, `V`, `<C-v>` で visual 選択も出来る。`d` で delete、`y` でヤンク。

直接 excursion モードに入るキーマップも用意しています。  
ここでは、`<C-e>` にマッピングします。

```Vim
nmap <C-e> <Plug>(smalls-excursion)
```

1. `<C-e>` を押す。
2. 何か一文字入力。例えば `,` とする。この時点で excursion-mode に入る。
3. hjklnp 等で移動し、`d`で削除、`y` でヤンク等する。

この方法のメリットは、excursion-mode に切り替える操作が発生しない点です。  
デメリットは、着地候補絞り込みの入力文字数が固定になる点です。  
入力文字数が `g:smalls_auto_excursion_min_input_length` の値を超えると、自動的に excursion-mode に入ります。  
デフォルトは `1` です。  

# 果たしてコレは便利なのか？

デフォルトの `f` や `t` の方が速く、脳内のコンテキストスイッチも少ないので良い、という場面は多くあるでしょう。  
しかし、「現在位置から数行先の例えば `)` までを消したい( or ビジュアル選択したい)といった場合、標準の `d/` の組み合わせよりも楽になる可能性はあります。  

「 どの操作がもっとも決定的か ？ 」といった問いは、同種のカーソル移動系プラグインに共通する議題です。  
機能的な比較よりも、どれか一番しっくりくるものを選んで、徹底的に慣れてみてからまた考えれば良いというのが私の意見です。  
この種のプラグインはどれを使うにしても「 考えなくても手が動く程度に操作に習熟する 」、その上で意味が出てくるものだと予想しています。  
予想、というのは作者の私自身がまだ手が慣れていないからです。  

# なぜ作ったか？
* 複数文字で検索して、一発で候補に飛びたい。  
easymotion は 'word の先頭', 'word の終わり', '行' 等、移動前に移動先の性質を判断してから呼び出す必要があり、脳が疲れる。  
キータイプが少し増えてもいいからもう少し気楽に呼び出したい。また大画面では、複数文字で候補を絞り込んでからジャンプした方が結果的にキー入力が少なくて済む。  
呼び出し前に移動先が、行か、word start か word end かを選ぶのは疲れる。  
* forwad, backward はいらない。見えている window 全体を対象として移動したい。  
要は一つのキーのみから呼び出したい。現在のカーソル位置から移動先への相対位置から forward, backward 判断してキーを選ぶのが疲れる。  
* ジャンプの移動先を選ぶのに大文字押したくない。  
Shift キーと組み合わせて大文字(Capital Letter)を入力したくない。  
小文字だけでジャンプ出来たほうが結果的に速い。  
* しかし結果的には excursion-mode が副産物として出来たので、単なる search > easymotion style jump プラグインではなくなった。  

# smalls-mode

smalls.vim には２つのモードがある。

| モード     | 説明        |
| ---------- |-------------|
| cli-mode   | `<Plug>(smalls)` で入るモード、候補の選択とジャンプ。 <br> `<C-e>`や`<Tab>`等を入力することで excursion-mode に入る |
| excursion-mode  | excursion (小旅行)モード。 <br> cli-mode で絞り込んだ候補間をjkhl で移動したり、`d`(削除), `y`(ヤンク)等を行う。|


## cli-mode
cli-mode のキーマップはデフォルトで以下の様になっている。  
後述するが、このキーバインドは全て変更可能。  

| *Key*            | *Action*                        | *Description*                       |
| ---------------- | ------------------------------- | ----------------------------------- |
| `<C-g>`          | do_cancel                       | キャンセル                          |
| `<C-c>`          | do_cancel                       | キャンセル                          |
| `<Esc>`          | do_cancel                       | キャンセル                          |
| `<CR>`           | do_jump_first                   | デフォルト候補に着地                |
| `<C-h>`          | do_delete                       | カーソル後方の文字を削除            |
| `<BS>`           | do_delete                       | カーソル後方の文字を削除            |
| `<C-a>`          | do_head                         | カーソルを行頭へ                    |
| `<C-f>`          | do_char_forward                 | カーソルを1文字進める               |
| `<C-b>`          | do_char_backward                | カーソルを1文字戻す                 |
| `<C-k>`          | do_kill_to_end                  | 行末まで削除                        |
| `<C-u>`          | do_kill_line                    | 行をクリア                          |
| `<C-r>`          | do_special                      | 実験的機能(意味なし)                |
| `<C-e>`          | do_excursion                    | excursion-mode に入る               |
| `<C-d>`          | do_excursion_with_delete        | excursion-mode の delete            |
| `D`              | do_excursion_with_delete_line   | excursion-mode の delete_line       |
| `<C-y>`          | do_excursion_with_yank          | excursion-mode の yank              |
| `Y`              | do_excursion_with_yank_line     | excursion-mode の yank_line         |
| `V`              | do_excursion_with_select_V      | excursion-mode の select_V          |
| `<C-v>`          | do_excursion_with_select_CTRL_V | excursion-mode の select_CTRL_V     |
| `<Tab>`          | do_excursion_with_next          | excursion-mode の next              |
| `<C-n>`          | do_excursion_with_next          | excursion-mode の next              |
| `<S-Tab>`        | do_excursion_with_prev          | excursion-mode の prev              |
| `<C-p>`          | do_excursion_with_prev          | excursion-mode の prev              |
| NOT_ASSIGNED     | do_auto_excursion_off           | auto_excursion を一時的にoff        |
| NOT_ASSIGNED     | `__UNMAP__`                     | Key に bind されたマッピングを解除  |
| `{jump_trigger}` | do_jump                         | ジャンプキーを表示(デフォルトは`;`) |

## excursion-mode

| *Key*                | *Action*                  | *Description*                       |
| -------------------- | ------------------------- | ----------------------------------- |
| `<C-g>`              | do_cancel                 | キャンセル                          |
| `<C-c>`              | do_cancel                 | キャンセル                          |
| `<C-e>`              | do_back_cli               | cli-mode へ戻る                     |
| `<Esc>`              | do_back_cli               | cli-mode へ戻る                     |
| `<CR>`               | do_set                    | 着地候補に着地                      |
| `;`                  | do_set                    | 着地候補に着地                      |
| `n`                  | do_next                   | 次の着地候補へ                      |
| `<Tab>`              | do_next                   | 次の着地候補へ                      |
| last_char in cli(*1) | do_next                   | 次の着地候補へ                      |
| `p`                  | do_prev                   | 前の着地候補へ                      |
| `<S-Tab>`            | do_prev                   | 前の着地候補へ                      |
| `gg`                 | do_first                  | 最初の候補へ                        |
| `G`                  | do_last                   | 最後の候補へ                        |
| `0`                  | do_line_head              | 現在行の最初の候補へ                |
| `^`                  | do_line_head              | 現在行の最初の候補へ                |
| `$`                  | do_line_tail              | 現在行の最後の候補へ                |
| `k`                  | do_up                     | 上の着地候補へ                      |
| `j`                  | do_down                   | 下の着地候補へ                      |
| `h`                  | do_left                   | 左の着地候補へ                      |
| `l`                  | do_right                  | 右の着地候補へ                      |
| `<C-d>`              | do_delete                 | 着地候補までを delete               |
| `d`                  | do_delete                 | 着地候補までを delete               |
| `D`                  | do_delete_line            | 着地候補までを delete (line-wise)   |
| `<C-y>`              | do_yank                   | 着地候補までを yank                 |
| `y`                  | do_yank                   | 着地候補までを yank                 |
| `Y`                  | do_yank_line              | 着地候補までを yank (line-wise)     |
| `v`                  | do_select_v               | 着地候補までを v                    |
| `V`                  | do_select_V               | 着地候補までを V                    |
| `<C-v>`              | do_select_CTRL_V          | 着地候補までを CTRL_V               |
| 数字                 | SPECIAL                   | カウントを指定                      |
| NOT_ASSIGNED         | do_select_v_with_set      | 着地候補までを v し、do_set         |
| NOT_ASSIGNED         | do_select_V_with_set      | 着地候補までを V  し、do_set        |
| NOT_ASSIGNED         | do_select_CTRL_V_with_set | 着地候補までを CTRL_V し、do_set    |
| NOT_ASSIGNED         | `__UNMAP__`               | Key に bind されたマッピングを解除  |
| NOT_ASSIGNED         | do_jump                   | ジャンプキーを表示(デフォルトは`;`) |
*1 cli-mode で入力された最後の文字で `do_next` が実行可能。
例えば `<Plug>(smalls-excursion)` から呼び出し、`g:smalls_auto_excursion_min_input_length` が `1` の場合
に以下の様な行で `,` を入力し、excursion-mode に入った場合、繰り返し`,` を入力することで、次の着地候補に移動出来る。
```Vim
        \ map(['guifg', 'guibg', 'gui'], 's:scan(defstr, v:val)')
```
`]` の場合で `<Plug>(smalls-excursion)]]...`、`)`の場合は`<Plug>(smalls-excursion)))...` という具合に、同じキーで次の着地候補に移動できる。


# どちらのモードをメインに使用するか？

smalls.vim は開発当初、使用方法として、'検索 → easymotion style でのジャンプ'を想定していた。  
開発が進み、excursion-mode が導入された。excursion-mode は最初の頃、あくまでも主のcli-mode から移動する submode 的な位置づけだったが、excursion-mode の機能が拡充され、excursion-mode を主として使えるレベルに達した。  

# カスタマイズ

TODO

# FAQ

## excursion-mode に入った事が視覚的に分かりにくい。
* 慣れる。
* カーソルの色を変える拡張実装がされるのを待つ。
* ステータスラインの下の `[Excursion]` を視る。
* [vim-ezbar](https://github.com/t9md/vim-ezbar) を使用し、設定例を参考にステータスバーの色ごと変えることで気付き易くする。

## excursion-mode にいちいち切り替えるのが面倒。
`<Plug>(smalls-excursion)` を使用して下さい。

1文字ではなく、2文字入力後に excursion-mode に入るようにしたい。  
以下の設定で可能です。  
```Vim
let g:smalls_auto_excursion_min_input_length = 2
```

## デフォルトのキーマップを削除したい。

特殊なアクション `__UNMAP__` を設定するとそのキーマップは削除される。

## excursion-mode で、`l`, `h` で行を超えて移動したい。
excursion-mode の `do_next`, `do_prev` アクションがそれです。
以下の設定で可能です。

```Vim
call smalls#keyboard#excursion#extend_table({ "l": 'do_next', "h": 'do_prev', })
```

## excursion-mode で、移動数をカウント指定したい。
対応しています。  
例えば `3n` で 3つ先の着地点へ, `10j` で10行下の着地点へ移動が出来ます。

## キーバインドをカスタマイズしたい。
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
call smalls#keyboard#excursion#replace_table({})
```

# 開発の流れ-どのようにして今の形になったか？(自分用の思考整理メモ)

## 2013-10-25

clerver-f, sneak 等を試す。文字数が固定なのが慣れなく(慣れるまで使えば話は変わってくるが、、)、画面内を任意の文字数で検索して移動出来るプラグインとして smalls を実験的に作ってみる。

その後しばらく放置。

## 2013-11

Lokaltog 氏の vim-easymotion を理解する為に fork して書き換えつつ動作を理解。  
  
easymotion style のジャンプを smalls に導入  
  
この当時 forward, backward の検索方向区別があり、shade() 効果等のハイライトの指定に苦戦。  
String interportion を行う s:intrpl() を作ったことで matchadd() のハイライト範囲の記述が可読可能になり、大幅にメンテナンスしやすくなった。  
excursion mode を導入, hjkl で着地候補間を移動可能に。  
  
forwrd, backword の検索区別を廃止。方向を廃した事で、コードの不要箇所を一気に削除。  
例えば、excursion-mode での next は backwrd サーチでは poslit が逆になるので、最初に reverse() するとか、ハイライトの範囲を、backword, forward で半分shadeする方向を考慮する、shade 内の着地候補(candidate)のみハイライトするとか、その手の方向がある事での複雑さが一掃されて気楽になった。  
  
keyboard という仕組みを導入したことで、cli-mode, excursion-mode でのアクション追加が随分楽に。  
お試しでアクションを次々追加。  
  
operator-mode から呼び出す使用を想定に入れ、omap を追加。  
  
migemo を dev branch でお試し実装してみるが、一旦却下の判断をする。  
  
オペレータから呼び出した際、word top を着地点にすべきか、wordend を着地点にすべきかの判断に迷う。  
word end の方が分かりやすいと判断し、word end に決め打ち。(一時的にユーザー変数で動作制御可能にしたが削除)  
d オペレーションから呼び出した時に、word end の文字が含まれない動作について考える。これは `d/` 等と同様の動きではあるが、直感に反する。vim の help から inclusive, exclusive という説明を知る。  
末尾の文字を含み(inclusive)たければ、着地点を微調整(adjust_column)する必要がある。  
しかしこれは operator の motion-wise が修飾( or 強制 or 矯正 ) された時に問題が出る。  
motion の前に、`dv`, `dV`, `d<C-v>` 等とすることで、motion の wise を強制(矯正)できる事を知る。  
excursion-mode では operator の作用範囲を char-wise 前提で視覚化していたが、plugin 側で、ユーザーが矯正した mosion-wise の修飾文字(`v`,`V`,`<C-v>`)が取得できない事を知り視覚化に限界を感じる。  
kana 氏が2008年に同様の課題に直面し、`v:motion_force` なる組み込み変数を追加する提案(patch)を行っていることを知る。textobj-user では `v:motion_force` を見るロジックがある。  
プラグイン側で motion の修飾を知る事ができないので綺麗な解決は出来ない。  
`g:smalls_operator_motion_inclusive` を導入し、ユーザーの設定にまかせてこの件は終了にする。  
  
excursion-mode で移動数をカウント指定可能に。  
  
excursion-mode にキーマップ, アクションを大幅追加。(`G`, `gg`,`v`, `V`, `C-v`, `y`, `Y`, `d` 等)  
excursion-mode で 2 キーのキーバインドを可能にした。`gg` で 最初の候補へ飛べるようにするため。  
