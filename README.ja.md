# Neptune 4 Plus Type-C版：上部LEDをFluidd / Mobilerakerから制御する

ELEGOO Neptune 4 Plus **Type-C版**の上部ガントリーLEDを、FluiddまたはMobilerakerからON/OFFするための実機検証記録です。

Neptune 4 ProやMax向けにはGPIO 66、またはGPIO 66/79を操作する先行事例があります。本記事は新規発明を主張するものではなく、現行Neptune 4 Plus Type-C版で各制御経路を個別に追試し、このハードウェアではGPIO 79が実質的な制御入力になることを記録したものです。

> [English version](README.md)

## 検証環境

- 機種：ELEGOO Neptune 4 Plus
- ハードウェア：Type-Cツールヘッドケーブル版
- 本体ファームウェア：`V1.4.1.4`
- 液晶ファームウェア：`1.2.22`
- 操作UI：Fluidd / Mobileraker
- 検証日：2026-11-09

旧リボンケーブル版、Neptune 4/4 Pro、Neptune 4 Maxでは未検証です。

## 先行事例と今回の範囲

次のコミュニティ情報が先に公開されています。

- [2024年3月のドイツ語フォーラム投稿](https://forum.drucktipps3d.de/forum/thread/30746-elegoo-neptune-4-pro-lichter-direkt-beim-starten-aktivieren/?pageNo=2)：Neptune 4 Proで `gpio66_value` と `gpio79_value` の両方を操作
- [`Tsoukan/MyElegooN4Max`](https://github.com/Tsoukan/MyElegooN4Max)：Neptune 4 Maxの上部LEDを`gpio66_value`で点灯
- [2026年のType-C版に関するReddit投稿](https://www.reddit.com/r/ElegooNeptune4/comments/1ue955n/neptune_4_max_observation_light_control/)：最近の個体で欠けている `gcode_shell_command.py` とKIAUH拡張による復旧

今回追加で実機確認した範囲は次のとおりです。

- Neptune 4 Plus Type-C版の本体・液晶ファームウェアを特定
- 純正`sled1.sh`（GPIO 79）と`sled2.sh`（GPIO 66）の個別実行結果
- GPIO 79への要求だけで実GPIO 66/79が両方遷移すること
- GPIO 66への要求だけでは、要求ファイルが受理されても実GPIOが点灯しないこと
- Makerbase制御ファイルの応答値 `2=OFF / 3=ON`
- FluiddとMobilerakerから使える単一トグルスクリプト

## 症状

標準の`sled2.sh`はGPIO 66だけへ要求を書きます。このType-C版では要求値が受理されても実GPIO 66/79は点灯せず、上部LEDを保持できませんでした。一方、標準の`sled1.sh`が使うGPIO 79へ要求すると、実GPIO 66/79が両方切り替わり、上部LEDの状態が保持されました。純正のマクロ名・説明と、このハードウェアでの実際の制御経路は一致していません。

Klipper側には以下の問題もありました。

- `FLASHLIGHT_SWITCH` マクロは存在する
- マクロが呼ぶ `RUN_SHELL_COMMAND` は `Unknown command` になる
- Klipperの `klippy/extras` に `gcode_shell_command.py` が存在しない

## 制御経路の実測結果

消灯状態から純正スクリプトを個別に実行し、Makerbase要求ファイルと実GPIOを監視しました。

| 操作 | `gpio66_value` | `gpio79_value` | 実GPIO 66 | 実GPIO 79 | 上部LED |
|---|---:|---:|---:|---:|---|
| 初期消灯 | `2` | `2` | `0` | `0` | OFF |
| 純正`sled1.sh`（79） | `2` | `3` | `1` | `1` | ON |
| 純正`sled2.sh`（66） | `3` | `2` | `0` | `0` | OFF |

この個体では、制御ファイルに書いた要求値を純正サービスが次の値へ更新します。

- `1`を書込む：ON要求。処理後は`3`
- `0`を書込む：OFF要求。処理後は`2`

GPIO 79への要求だけで実GPIO 66/79が連動するため、本リポジトリのトグルスクリプトは`gpio79_value`だけを操作します。既存の`FLASHLIGHT_SWITCH`名を維持するため、ファイル名は`sled2.sh`のままにしています。純正`MODLELIGHT_SWITCH`もGPIO 79を使うため、このType-C版では同じ上部LED動作になります。

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

### 5. 明示的なON/OFFと印刷への連動（任意）

遠隔操作では現在状態に依存するトグルより、ON/OFFを明示する方が安全です。
[`scripts/gantry-led-on.sh`](scripts/gantry-led-on.sh)と[`scripts/gantry-led-off.sh`](scripts/gantry-led-off.sh)を`/home/mks/`へコピーし、実行権限を設定します。

```sh
chmod 755 /home/mks/gantry-led-on.sh /home/mks/gantry-led-off.sh
```

[`config/gantry-led-control.cfg`](config/gantry-led-control.cfg)を`~/printer_data/config/`へコピーし、`printer.cfg`の通常設定部分に次を追加します。

```ini
[include gantry-led-control.cfg]
```

これによりFluiddとMobilerakerから`GANTRY_LED_ON`と`GANTRY_LED_OFF`を直接実行できます。印刷中だけ自動点灯する場合は、既存の各マクロへ次の1行を追加します。

- `PRINT_START`の先頭：`GANTRY_LED_ON`
- `PRINT_END`のヒーター・ファン停止後：`GANTRY_LED_OFF`
- `CANCEL_PRINT`のヒーター・ファン停止後：`GANTRY_LED_OFF`

既存の`PRINT_START`、`PRINT_END`、`CANCEL_PRINT`を別定義で置き換えず、純正マクロの処理内へ1行ずつ追加してください。変更後はKlipperを再起動し、状態が`ready`であることを確認します。

## 元に戻す方法

Klipperが設定エラーになった場合はバックアップを戻します。

```sh
cp -p ~/printer_data/config/printer.cfg.backup ~/printer_data/config/printer.cfg
cp -p /home/mks/sled2.sh.backup /home/mks/sled2.sh
```

その後Klipperを再起動します。この手順ではメイン基板MCUや液晶ファームウェアを書き換えません。

## V1.4.1.5へ更新した場合

同じ実機を`V1.4.1.4`から`V1.4.1.5`へ更新したところ、Fluiddから`FLASHLIGHT_SWITCH`を実行しても点灯せず、次のエラーになりました。

```text
Unknown command:"RUN_SHELL_COMMAND"
```

更新後の実機では、次の状態を確認しました。

- `FLASHLIGHT_SWITCH`と`MODLELIGHT_SWITCH`マクロは`printer.cfg`に残っていた
- `/home/mks/klipper/klippy/extras/gcode_shell_command.py`も残っていた
- 一方、マクロが参照する`[gcode_shell_command FLASHLIGHT]`と`[gcode_shell_command MODLELIGHT]`セクションが消えていた
- 修復後も、GPIO 79へのON要求は`gpio79_value=3`となり、実GPIO 66/79が両方`1`になる挙動は`V1.4.1.4`と同じだった

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

## 注意点

- シェルコマンドを実行するマクロには固定コマンドだけを登録し、外部入力をそのまま渡さないでください。
- このType-C版では`FLASHLIGHT_SWITCH`と`MODLELIGHT_SWITCH`が実質的に同じライトを切り替えます。独立した2系統としては動作しません。
- ファームウェア更新で `sled2.sh` が上書きされたり、制御方式が変わったりする可能性があります。
- 別の基板・ファームウェア世代ではGPIO番号や挙動が異なる可能性があります。
- 初期SSH認証情報などは、本記事では意図的に掲載していません。
- GPIO 66および66/79制御の先行事例へのクレジットは、上記のコミュニティ情報にあります。本記事はType-C版Plusで各経路を分離して検証した結果です。

## ライセンス

本リポジトリで作成したファイルはMIT Licenseです。KIAUHおよび `gcode_shell_command.py` は別プロジェクトであり、それぞれのライセンスに従います。
