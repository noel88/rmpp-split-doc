# rmpp-split-doc

Open two documents side by side on a **reMarkable Paper Pro Move**, and keep a
memo notebook attached to any document.

This is a port of the `split_doc` hack from
[asivery/rm-hacks-qmd](https://github.com/asivery/rm-hacks-qmd) to firmware
3.27.x, with a few additions. It runs on
[xovi](https://github.com/asivery/rm-xovi-extensions) and qt-resource-rebuilder.

[한국어 안내는 아래에 있습니다.](#한국어)

> [!WARNING]
> This is unofficial homebrew that patches the reMarkable UI. A mistake can leave
> the tablet in a UI crash loop until you undo it over SSH. Only continue if you
> are comfortable with SSH and with the [recovery steps](#recovery) below.

## Features

All controls live in the document's **Layers** menu.

- **Split document.** Open a second document, or a new notebook, next to the one
  you are reading. Choose overlay or divided layout, change the split ratio, and
  swap which pane is main. You can write in both panes, and each document saves
  on its own.
- **Memo notebook.** The memo button in the *Main doc* section creates a notebook
  named `[Memo] <document name>` in a `Memo` folder at the top of My Files.
  - The first tap opens the create-notebook dialog. After that, a tap opens the
    memo in the split pane.
  - Documents that have a memo get a `📝` tag. The memo opens beside them
    automatically when you open the document.
  - When you move a memo to the trash, the `📝` tag is removed from its document
    within about a second.
- **Quieter zoom indicator.** The zoom level (`x.x`) appears for about 1.5 seconds
  after you change zoom, instead of covering the split boundary the whole time.

## Compatibility

| Device | Firmware | Status |
| --- | --- | --- |
| Paper Pro Move | 3.27.1.0, 3.27.3.0 | Tested |
| Paper Pro (11.8") | 3.27.x | Untested |
| Any | 3.28 and later | **Not supported.** The toolbar library can't be patched there, so the menu does not appear. |
| reMarkable 1 / 2 | — | Not supported |

If your tablet updates itself to an unsupported firmware, the hacks stop loading.
The tablet itself keeps working (see [Firmware updates](#firmware-updates)).

## Install

You need SSH access to the tablet. Turn on developer mode. The root password is
under **Settings → Help → Copyrights and licenses**. Commands below assume a USB
connection (`10.11.99.1`).

### 1. Install xovi and build the hashtab

Follow the *Download Xovi* and *Install Xovi* sections of the upstream
[rmHacks install guide](https://github.com/asivery/rm-hacks-qmd/blob/master/INSTALL.MD).
Use `extensions-aarch64.zip`. Finish with this command on the tablet:

```sh
xovi/rebuild_hashtable
```

Wait for the prompt to come back. It can take a couple of minutes.

### 2. Remove upstream rmHacks, if you installed it

This package includes its own copy of the rmHacks base. If both copies load, the
settings get defined twice and none of the hacks work.

```sh
cd /home/root/xovi/exthome/qt-resource-rebuilder
rm -rf zz_rmhacks.qmd zz_rmHacks.qmd rmHacks
```

### 3. Copy the patches

Download `rmpp-split-doc-v0.1.0.zip` from
[Releases](https://github.com/noel88/rmpp-split-doc/releases) and unzip it. From the
unzipped folder, run:

```sh
scp -r qt-resource-rebuilder/zz_rmhacks.qmd qt-resource-rebuilder/rmHacks \
  root@10.11.99.1:/home/root/xovi/exthome/qt-resource-rebuilder/
```

### 4. Load xovi on every boot

```sh
ssh root@10.11.99.1 'sh -s' < scripts/install-xovi-persist.sh
```

This script:

- Briefly remounts the root filesystem read-write.
- Adds a systemd drop-in that preloads xovi and allows the QML file access the
  memo feature needs.
- Restarts the reMarkable UI.

The screen will go blank for a few seconds. Then open any document and tap
**Layers**. You should see the *Main doc* and *Split doc* sections.

You can turn the split menu off in the rM Hacks settings.

## Firmware updates

A firmware update removes the drop-in, so the tablet boots stock with no hacks.
That state is safe. If the new firmware is still supported, re-enable the hacks
in this order:

1. `xovi/rebuild_hashtable` on the tablet.
2. `ssh root@10.11.99.1 'sh -s' < scripts/install-xovi-persist.sh`

Do not skip step 1. If xovi loads with a hashtab built for a different firmware
version, the UI crash-loops.

## Recovery

A blinking LED or a UI that keeps restarting usually means a patch or hashtab
problem. SSH usually still works while this happens. To boot stock again:

```sh
ssh root@10.11.99.1
mount -o remount,rw /
rm -f /usr/lib/systemd/system/xochitl.service.d/zz-xovi.conf
mount -o remount,ro /
systemctl daemon-reload
systemctl restart xochitl
```

Other things to check:

- **A patch doesn't seem to apply.** Clear the QML cache with
  `rm -rf /home/root/.cache/remarkable/xochitl/qmlcache` and restart.
- **You also use the `webserver-remote` xovi extension.** It can crash-loop when
  xochitl restarts, and it keeps Wi-Fi awake, which drains the battery. If you
  don't need it, move it out of `xovi/extensions.d/`.

## Uninstall

Follow the [recovery](#recovery) steps, then delete the patches:

```sh
rm -rf /home/root/xovi/exthome/qt-resource-rebuilder/zz_rmhacks.qmd \
       /home/root/xovi/exthome/qt-resource-rebuilder/rmHacks
```

Your memos stay as ordinary notebooks in the `Memo` folder.

## What's changed from upstream

- Ported `split_doc` to the 3.27.x DocumentView and MainView:
  - Fixed stale anchors.
  - Made `onOpened` use `REDEFINE`.
  - Removed replica properties that no longer exist.
  - Added the required `notificationQueue`.
  - Made `canSuspend` null-safe.
- Removed the per-document orientation toggle. It conflicted with the rotation
  sensor, so use physical rotation instead.
- Added the memo notebook and the zoom indicator timeout.
- Includes only the rmHacks base and `split_doc`. The other upstream hacks aren't
  included because many of their anchors are stale on 3.27.x, and a failing patch
  rolls back every other patch on the same file.

## Credits

- [asivery](https://github.com/asivery) wrote rmHacks, xovi, qt-resource-rebuilder
  and qmldiff. This project would not exist without them.
- @GreySim wrote the upstream install guide.

MIT licensed. See [LICENSE](LICENSE).

---

## 한국어

**reMarkable Paper Pro Move**에서 문서 두 개를 나란히 띄워 쓰고, 문서마다 메모
노트북을 붙여 쓸 수 있게 해 주는 비공식 패치입니다. asivery의 rmHacks에 있던
`split_doc`을 펌웨어 3.27.x에 맞게 옮기고 기능을 몇 가지 더했습니다.

> [!WARNING]
> 비공식 홈브루입니다. 잘못 설치하면 UI가 계속 재시작될 수 있습니다. 그럴 때는 SSH로
> 되돌려야 하니, SSH 사용과 위의 [Recovery](#recovery) 절차가 익숙할 때만 설치하세요.

- **기능**
  - 문서의 **레이어(Layers)** 메뉴에서 쓸 수 있습니다.
  - 화면 분할: 겹치기·나누기 모드를 고르고 비율을 조절하고 좌우를 바꿀 수 있습니다.
  - 문서별 메모 노트북: `Memo` 폴더에 만들어지고, 메모가 있는 문서에는 `📝` 태그가
    붙습니다. 그 문서를 열면 메모가 자동으로 옆에 열립니다.
  - 줌 배율 표시가 1.5초 뒤에 사라집니다.
- **지원 환경**
  - Paper Pro Move 3.27.1.0과 3.27.3.0에서 테스트했습니다.
  - 3.28 이상은 메뉴 패치가 불가능해서 지원하지 않습니다.
- **설치 순서**
  1. xovi를 설치하고 `xovi/rebuild_hashtable`을 실행합니다.
  2. 기존 rmHacks가 있으면 삭제합니다.
  3. 릴리즈 zip의 `qt-resource-rebuilder/` 안의 파일을 기기로 복사합니다.
  4. `scripts/install-xovi-persist.sh`를 실행합니다.

  명령어는 위의 [Install](#install)을 참고하세요.
- **펌웨어 업데이트 후**
  - 해킹이 꺼진 순정 상태로 부팅됩니다. 이 상태는 안전합니다.
  - 지원 버전이라면 **반드시 `rebuild_hashtable`을 먼저 실행한 뒤** 설치 스크립트를
    다시 실행하세요. 순서를 바꾸면 UI가 계속 재시작됩니다.
