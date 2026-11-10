# Neptune 4 Plus Type-C版：上部LEDをFluidd / Mobilerakerから制御する

ELEGOO Neptune 4 Plus **Type-C版**の上部ガントリーLEDを、FluiddまたはMobilerakerからON/OFFするための実機検証記録です。

2つの制御ファイルを同時操作する方法自体は、Neptune 4 ProやMax向けに先行事例があります。本記事は新規発明を主張するものではなく、現行Neptune 4 Plus Type-C版での追試、既存情報の組合せ、および追加の実測結果をまとめたものです。

> [English version](README.md)

## 検証環境

- 機種：ELEGOO Neptune 4 Plus
- ハードウェア：Type-Cツールヘッドケーブル版
- 本体ファームウェア：`V1.4.1.4`
- 液晶ファームウェア：`1.2.22`
- 操作UI：Fluidd / Mobileraker
- 検証日：2026-11-09

追加検証：本体ファームウェア `V1.4.1.5`（2026-11-10）

旧リボンケーブル版、Neptune 4/4 Pro、Neptune 4 Maxでは未検証です。

## V1.4.1.5へ更新した場合

同じ実機を`V1.4.1.4`から`V1.4.1.5`へ更新したところ、Fluiddから`FLASHLIGHT_SWITCH`を実行しても点灯せず、次のエラーになりました。

```text
Unknown command:"RUN_SHELL_COMMAND"
```

更新後の実機では、次の状態を確認しました。

- `FLASHLIGHT_SWITCH`と`MODLELIGHT_SWITCH`マクロは`printer.cfg`に残っていた
- `/home/mks/klipper/klippy/extras/gcode_shell_command.py`も残っていた
- 一方、マクロが参照する`[gcode_shell_command FLASHLIGHT]`と`[gcode_shell_command MODLELIGHT]`セクションが消えていた
- 修復後も、GPIOの応答値は`3 / 3 = ON`、`2 / 2 = OFF`で、`V1.4.1.4`と同じだった

この状態ならKlipper全体や拡張ファイルを再インストールする必要はありません。`printer.cfg`の**自動保存ブロックより前**に、消えた定義を戻します。

```ini
[gcode_shell_command FLASHLIGHT]
command: sh /home/mks/sled2.sh
timeout: 5.
verbose: True

[gcode_shell_command MODLELIGHT]
command: sh /home/mks/sled1.sh
timeout: 5.
verbose: True
```

> [!CAUTION]
> 追加位置は`#*# <---------------------- SAVE_CONFIG ---------------------->`より前にしてください。このブロックより後ろへ通常設定を追記すると、自動保存されたPID値やベッドメッシュが読み込まれず、Klipperが起動エラーになったり、保存済みメッシュをロードできなくなったりします。

変更前に`printer.cfg`をバックアップし、Klipper再起動後に状態が`ready`であること、使用するベッドメッシュが存在することを確認してください。その後`FLASHLIGHT_SWITCH`を2回実行し、点灯と消灯の両方を確認します。

## 先行事例と今回の範囲

次のコミュニティ情報が先に公開されています。

- [2024年3月のドイツ語フォーラム投稿](https://forum.drucktipps3d.de/forum/thread/30746-elegoo-neptune-4-pro-lichter-direkt-beim-starten-aktivieren/?pageNo=2)：Neptune 4 Proで `gpio66_value` と `gpio79_value` の両方を操作
- [`Tsoukan/MyElegooN4Max`](https://github.com/Tsoukan/MyElegooN4Max)：Neptune 4 Max向けの関連LED制御スクリプト
- [2026年のType-C版に関するReddit投稿](https://www.reddit.com/r/ElegooNeptune4/comments/1ue955n/neptune_4_max_observation_light_control/)：最近の個体で欠けている `gcode_shell_command.py` とKIAUH拡張による復旧

今回追加で実機確認した範囲は次のとおりです。

- Neptune 4 Plus Type-C版の本体・液晶ファームウェアを特定
- GPIO 66だけを操作すると一瞬光って消える現象
- 純正画面操作時にGPIO 66/79が同時遷移すること
- Makerbase制御ファイルの応答値 `2=OFF / 3=ON`
- FluiddとMobilerakerから使える単一トグルスクリプト

## 症状

標準の `sled2.sh` や、GPIO 66への直接書込みを試すと、上部LEDは一瞬光るだけで消えました。Klipper側には以下の問題もありました。

- `FLASHLIGHT_SWITCH` マクロは存在する
- マクロが呼ぶ `RUN_SHELL_COMMAND` は `Unknown command` になる
- Klipperの `klippy/extras` に `gcode_shell_command.py` が存在しない

## 本体画面の実測結果

本体画面で上部LEDをONにし、約5秒後にOFFにしながら値を監視しました。

| 操作 | `gpio66_value` | `gpio79_value` | GPIO 66 | GPIO 79 |
|---|---:|---:|---:|---:|
| OFF | `2` | `2` | `0` | `0` |
| ON | `3` | `3` | `1` | `1` |

この個体では、制御ファイルに書いた要求値を純正サービスが次の値へ更新します。

- `1`を書込む：ON要求。処理後は`3`
- `0`を書込む：OFF要求。処理後は`2`

`gpio66_value` だけにON要求を送っても保持されませんでしたが、`gpio79_value` と `gpio66_value` の両方へ送ると、本体画面と同じく点灯状態が保持されました。

## 導入方法

### 1. バックアップ

SSHでプリンターへ入り、既存ファイルを保存します。

```sh
cp -p /home/mks/sled2.sh /home/mks/sled2.sh.backup
cp -p ~/printer_data/config/printer.cfg ~/printer_data/config/printer.cfg.backup
```

### 2. `sled2.sh`を置き換える

[`scripts/sled2.sh`](scripts/sled2.sh) を `/home/mks/sled2.sh` へコピーし、実行権限を設定します。

```sh
chmod 755 /home/mks/sled2.sh
```

### 3. `RUN_SHELL_COMMAND`を利用可能にする

今回のType-C版には、設定マクロが残っている一方で `gcode_shell_command.py` が入っていませんでした。KIAUHの拡張インストーラーを使うか、[KIAUH公式ソース](https://github.com/dw-0/kiauh/tree/master/kiauh/extensions/gcode_shell_cmd)から該当拡張を導入します。

この機能だけのためにKlipper全体を入れ替える必要はありません。変更前に必ずバックアップしてください。

### 4. Klipperマクロを追加する

同等の設定がまだなければ、[`config/gantry-led.cfg`](config/gantry-led.cfg) の内容を `printer.cfg` に追加します。Klipperを再起動し、状態が `ready` であることを確認してください。

FluiddまたはMobilerakerから次を実行します。

```gcode
GANTRY_LED_TOGGLE
```

既存の `FLASHLIGHT_SWITCH` というマクロ名をそのまま利用しても構いません。

## 元に戻す方法

Klipperが設定エラーになった場合はバックアップを戻します。

```sh
cp -p ~/printer_data/config/printer.cfg.backup ~/printer_data/config/printer.cfg
cp -p /home/mks/sled2.sh.backup /home/mks/sled2.sh
```

その後Klipperを再起動します。この手順ではメイン基板MCUや液晶ファームウェアを書き換えません。

## 注意点

- シェルコマンドを実行するマクロには固定コマンドだけを登録し、外部入力をそのまま渡さないでください。
- ファームウェア更新で `sled2.sh` が上書きされたり、制御方式が変わったりする可能性があります。
- 別の基板・ファームウェア世代ではGPIO番号や挙動が異なる可能性があります。
- 初期SSH認証情報などは、本記事では意図的に掲載していません。
- 2ファイル同時制御という着想のクレジットは、上記の先行コミュニティ情報にあります。本記事はType-C版Plusでの検証・補完です。

## ライセンス

本リポジトリで作成したファイルはMIT Licenseです。KIAUHおよび `gcode_shell_command.py` は別プロジェクトであり、それぞれのライセンスに従います。
