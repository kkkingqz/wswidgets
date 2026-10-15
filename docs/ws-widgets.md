# wswidgets

Один Quickshell runtime, общие контейнеры QML и один GNOME adapter.
`catalog.nix` описывает все виджеты проекта; хост включает нужные по ID
в порядке кнопок на панели. GNOME extension `workstation-widgets@local`
размещает прозрачное окно под кнопкой и только после этого разрешает
анимацию. Одновременно открыт один popup и любое число самостоятельных окон.

## Установка

Flake отдаёт модуль Home Manager `homeManagerModules.default`:

```nix
inputs.wswidgets = {
  url = "github:kkkingqz/wswidgets";
  inputs.nixpkgs.follows = "nixpkgs";
};
# в modules конфигурации Home Manager:
imports = [ inputs.wswidgets.homeManagerModules.default ];
programs.wswidgets = {
  enable = true;
  widgets = [ "example" "compact" ];
  # qmlCheckout = "/home/user/Projects/wswidgets";
};
```

Модуль устанавливает `ws-widgets`, создаёт manifest/runtime JSON в
`~/.local/share/wsconfig/widgets/`, QML в
`~/.config/quickshell/workstation-widgets` (из store или, с `qmlCheckout`,
ссылкой на `quickshell/` checkout), файлы extension в
`~/.local/share/gnome-shell/extensions/workstation-widgets@local` и user service
`workstation-widgets.service`. Включение extension (`enabled-extensions`)
остаётся владельцу списка расширений: UUID — `programs.wswidgets.extensionUuid`.
При первой установке и после изменения кода extension нужен новый вход в GNOME.
Неизвестный ID в `widgets` останавливает сборку со списком доступных.

Runtime запускается вместе с graphical-session.target только в GNOME Wayland
(`ExecCondition`: `XDG_CURRENT_DESKTOP` с GNOME, `WAYLAND_DISPLAY`, нет
`gamescope-session-plus` — сессии Steam Game Mode), останавливается с
сессией и ограничивает частоту рестартов. Quickshell и Mesa
из nixpkgs потребителя (`inputs.nixpkgs.follows`) находятся в отдельном closure; launcher задаёт EGL
vendor только для своего процесса. Qt получает scale из Wayland. Дополнительный
`QT_SCALE_FACTOR` не нужен.

## Команды

```console
ws-widgets start
ws-widgets stop
ws-widgets restart
ws-widgets status
ws-widgets check --json
ws-widgets check --tsv
ws-widgets toggle example
ws-widgets show compact
ws-widgets hide compact
ws-widgets hide-all
journalctl --user -u workstation-widgets.service -b
```

Обычное закрытие соединения (ответ CLI, перезагрузка расширения) не пишется в журнал:
сервис запускается с `--log-rules quickshell.io.socket.warning=false`. Обрыв adapter
виден в состоянии (`adapter.connected`, `lastError`) и в `ws-widgets check`.

status и check читают состояние. show/toggle/hide обращаются к уже запущенному
runtime и возвращают отказ без подключённого adapter, а также для неизвестного,
выключенного или сломанного ID.
Принятый show означает начало handshake, а не завершение анимации. Повторное
нажатие, Esc, кнопка «Закрыть», внешний клик, потеря фокуса, overview, смена
workspace и блокировка закрывают окно.
Эти правила относятся к popup. Самостоятельное окно остаётся открытым при
потере фокуса, внешнем клике, overview и смене workspace; закрывается обычной
кнопкой окна, Esc, собственным requestClose или командой hide/toggle.

check проверяет доставку, активность сервиса, protocol/PID, доступность
компонентов, активность extension и соединение adapter. Отсутствие активной
GUI-сессии или ещё не загруженный adapter отмечаются явно. Проверка не
подтверждает визуальное размещение; для него существует live checklist.

## Добавление виджета

Создать `quickshell/widgets/my-widget/Widget.qml`:

```qml
import QtQuick
import QtQuick.Controls
import "../../controls" as Ui
Item {
    required property QtObject context
    implicitHeight: 160
    Column {
        width: parent.width
        spacing: 16
        Ui.Label { text: "Мой виджет" }
        Ui.Button { text: "Закрыть"; onClicked: context.requestClose() }
    }
}
```

Добавить в `catalog.nix`:

```nix
{
  id = "my-widget";
  label = "Мой виджет";
  iconName = "starred-symbolic";
  component = "widgets/my-widget/Widget.qml";
  unloadOnClose = false;
  width = 360;
  height = 240;
  panelPosition = "right";
}
```

и включить ID в `programs.wswidgets.widgets` хоста: порядок списка задаёт
порядок кнопок.

Для отдельного перемещаемого окна добавить в его запись каталога:

```nix
presentation = "window";
width = 640; height = 480;
minimumWidth = 320; minimumHeight = 240;
```

По умолчанию `presentation = "popup"`, поэтому существующие виджеты сохраняют
поведение. Для `window` width/height задают начальный размер клиентской области
в логических пикселях, minimumWidth/minimumHeight — минимальный. Минимумы по
умолчанию min(160,width)/min(120,height); они должны быть положительными целыми
и не превышать начальный размер. Максимальный размер ограничивает оконная
система. Она же выбирает положение. Стандартные декорации Qt/оконной системы
предоставляют заголовок для перемещения, края для изменения размера и кнопки
закрытия, сворачивания и разворачивания. На GNOME Wayland рамку рисует Qt;
её оформление может отличаться от GTK. Только popup получает FramelessWindowHint.

Содержимое остаётся тем же Item с context. contentWidth/contentHeight следуют
фактической доступной области окна; размер не привязан к кнопке панели.
Перетаскивание не вызывает повторного размещения. Новый размер сохраняется
между закрытием и открытием в рамках одного runtime, сбрасывается при его
перезапуске. Положение на диск не сохраняется. Несколько окон не закрывают
друг друга и могут работать вместе с popup. GNOME активирует окно, сохраняя
обычный тип, участие в переключателе окон и штатные эффекты. Для будущих DE
оконный host не использует API GNOME; новый adapter всё ещё нужен для панели,
темы и handshake. Отключение adapter закрывает и popup, и обычные окна.

WidgetHost выбирает PopupWidgetHost или WindowWidgetHost; общий WidgetContent
отвечает за lazy loading, unloadOnClose, context и изоляцию ошибок QML.

Применить `home-manager switch`: новый manifest меняет unit и перезапускает runtime,
а extension перечитывает кнопки после изменения runtime/manifest JSON.
При изменениях кода самого extension нужна доставка и новый вход в GNOME.
Runtime не следит за файлами QML (`settings.watchFiles: false`): с
`qmlCheckout` конфигурация — symlink в checkout, и смена ветки перезагружала
бы его на лету без сокета. После правки QML в checkout перезапустить его
явно: `ws-widgets restart`. QML из store перезапускает runtime при switch сам
(`X-Restart-Triggers`).
В GNOME 50 `ReloadExtension` через D-Bus не работает, а disable/enable
использует уже импортированный JS-модуль. Это следует из
[реализации Shell D-Bus](https://github.com/GNOME/gnome-shell/blob/50.1/js/ui/shellDBus.js)
и [менеджера расширений](https://github.com/GNOME/gnome-shell/blob/50.1/js/ui/extensionSystem.js).
Для нового содержимого extension менять не требуется.

При автоматизированном disable/enable нужно дождаться состояния `INACTIVE`
в `gnome-extensions info workstation-widgets@local` перед enable. EOF сокета
означает закрытие adapter, но менеджер GNOME ещё может завершать выключение
и повторное включение других расширений. Немедленный enable в этот момент
может оставить `Enabled: Yes`, `State: INACTIVE`. Для восстановления отключить
расширение, дождаться `INACTIVE` и включить снова.
Каталог проверяет уникальные ID, положительные целые размеры и безопасный
относительный путь существующего компонента. `enabled = false` убирает кнопку.

Widget — Item с обязательным context. Контекст содержит widgetId,
contentWidth/contentHeight, devicePixelRatio, phase, background, foreground,
mutedForeground, font и requestClose(). Фон контейнера и цвета текста берутся из
фактического оформления меню GNOME, включая светлую/тёмную и пользовательскую
Shell theme. Adapter передаёт палитру при подключении и изменении стиля;
открытые окна обновляются без повторного открытия и без периодического опроса.
Содержимое использует context.foreground для основного текста и
context.mutedForeground для второстепенного.
Для надписей использовать `Ui.Label`: семейство, базовый размер, насыщенность
и наклон приходят от DE-адаптера из шрифта меню. `fontScale` (по умолчанию 1)
задаёт размер относительно системного, например 1.5 для заголовка. Шрифт
следует изменениям темы и системного размера без повторного открытия окна.
Для произвольного `Text` доступен `font: context.font`. Без данных адаптера
используется шрифт приложения Qt. Размеры передаются в логических пикселях;
дробная точность сохраняется, дополнительное умножение на scale не требуется.
Для кнопок использовать общий `controls/Button.qml` (`Ui.Button`). Он сохраняет
стандартные text/icon/Action/checkable и управление с клавиатуры. Оформление
приходит от DE-адаптера: GNOME экспортирует вычисленные цвета состояний, фокус,
шрифт и размеры кнопки Shell. Наведение и нажатие обрабатываются локально;
адаптер передаёт весь набор только при подключении или изменении темы.
Без такого набора используются активная и отключённая палитры Qt и шрифт
приложения. Компонент и контракт темы не зависят от GNOME; другие адаптеры могут
передавать те же параметры. Размеры контракта — логические пиксели, scale Qt
применяется один раз. GNOME-адаптер размещения пока единственный реализованный.
Простые фон/рамка и кольцо фокуса поддержаны; CSS-изображения, сложные градиенты
и асимметричные рамки пользовательской темы этим компонентом не воспроизводятся.
Компонент загружается при первом открытии и сохраняется после закрытия.
`unloadOnClose = true` в каталоге выгружает содержимое после закрытия; следующее
открытие загрузит его заново. По умолчанию false, чтобы повторное открытие было быстрым.
Ошибка компонента меняет значок кнопки на предупреждение и сообщает причину
через GNOME notification; другие виджеты продолжают работать.
Содержимое задаёт implicitHeight для прокрутки и не создаёт собственное окно.
Для popup размеры width/height каталога задают всю панель в логических пикселях: padding
16 внутри, прозрачное поле 12 снаружи, radius 16. Surface = panel + 24;
content = panel − 32. Example: panel 420×580, surface 444×604, content 388×548.
Compact: panel 320×240, surface 344×264, content 288×208.
При scale 1.5 панели занимают 630×870 и 480×360 физических пикселей.

При маленькой рабочей области adapter уменьшает popup перед раскрытием.
ScrollView сохраняет доступ к содержимому. Размер поверхности не анимируется;
анимируются clipping и opacity за 300 мс с мягким разгоном и замедлением.
Повторный клик закрывает панель; смена направления продолжает переход с
текущего раскрытия. Прозрачные поля и ещё скрытая часть
имеют пустой input region. Если GNOME отключает анимации, переход мгновенный.

Для popup GNOME adapter определяет внешние клики через reactive picking Mutter: скрытая
область, прозрачные поля и округлённые углы пропускают клик и закрывают виджет.
Внешний клик во время preparing отменяет запрос размещения.
Для popup adapter отправляет `placed` только после проверки геометрии и фактического
получения фокуса Mutter. До этого окно остаётся в preparing, поэтому потеря
фокуса старого окна при переключении не закрывает новое. Если фокус не получен,
срабатывает существующий таймаут размещения. Время клика используется только
для соответствующего открытия; закрытие и отмена очищают его.
Для window adapter ждёт отображения проверенного окна и отправляет `placed`
после однократного запроса активации; получение фокуса не требуется, поэтому
несколько окон могут открываться одновременно.
До подключения adapter поверхность не отображается. Adapter через InjectionManager
подавляет `_shouldAnimateActor` только для проверенного PID runtime и
зарегистрированного ID popup; это исключает наложение анимации Shell на QML.
При отключении adapter восстанавливает метод. Этот внутренний API проверен
по исходникам Shell 50.1; его работу в GUI проверяет live checklist.

## Контракт и восстановление

Runtime слушает `$XDG_RUNTIME_DIR/workstation-widgets/control.sock`.
Systemd создаёт каталог с правами 0700, а UMask=0077 сервиса создаёт сокет
с правами 0700. Сокет доступен только текущему UID: клиенты отклоняют каталог
и сокет с любыми битами group/other. CLI и Gio дополнительно проверяют права
и UID сервера (SO_PEERCRED/Gio credentials); PID snapshot должен совпадать с
PID peer. Quickshell сам пересоздаёт сокет, оставшийся после падения.

Протокол — JSON-строки с protocolVersion 2. Первое сообщение: hello с ролью
adapter или cli. Единственный adapter получает snapshot при подключении и
после изменения состояния. Новый adapter вытесняет старый. Команды adapter:
toggle, hideAll, hidePopups, placed, placementFailed, setGeometry, setAnimations, setTheme.
CLI отправляет одну команду status/show/hide/toggle/hideAll и получает ответ;
Quickshell процессы для команд и подписки больше не запускаются.
Ответы связаны с запросами через seq; requestId относится к размещению окна.

Фазы popup: closed → preparing → opening → open → closing → closed.
Фазы window: closed → preparing → open → closed, с анимацией оконной системы.
selectedId/pendingId относятся только к popup; состояние окон независимо.
hidePopups используется для автоматического закрытия popup, hideAll — для всех.
requestId отсекает устаревшие ответы, revision упорядочивает события instance.
На размещение даётся 2 секунды: одноразовый таймер ближайшего дедлайна.
В штатном простое нет периодических таймеров ни для IPC, ни для модели.
Обрыв adapter немедленно закрывает окна и записывает lastError. Повторное
подключение очищает эту ошибку. Без adapter show/toggle отклоняются.
После рестарта runtime все окна закрыты; adapter подключается с паузами
250/500/1000/2000 мс, проверяет новый PID. Отключение extension закрывает
соединение и отменяет чтение, запись, запросы и переподключение.

Отключение: `ws-widgets stop` и отключить extension через GNOME Extensions.
Постоянное удаление: `programs.wswidgets.enable = false`, убрать UUID из
`enabled-extensions` и применить `home-manager switch`: Home Manager удаляет
свои файлы (QML, JSON, extension, service, `ws-widgets`).
С `qmlCheckout` перед переключением checkout на ветку с другим QML
остановить runtime или сразу выполнить `ws-widgets restart`.

## Проверки разработки

```console
nix flake check --print-build-logs
nix build .#runtime
gjs -m tests/run-tests.js
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tests/check-qml.py ./result/bin/qs-widgets
```

Проверить изменения Nix-части в установленной конфигурации, не публикуя их:
`home-manager switch --flake … --override-input wswidgets path:$HOME/Projects/wswidgets`
(в wsconfig: `ws switch --override-input …`).

Wayland smoke без GNOME-кнопок:

```console
nix build .#checks.x86_64-linux.manifest -o /tmp/widgets-manifest
python3 tests/check-runtime.py --runtime ./result/bin/qs-widgets \
  --manifest /tmp/widgets-manifest --wayland
```

Тест использует временную конфигурацию, вручную подтверждает placement и
завершает только собственные процессы. Его результат не заменяет проверку
GNOME extension под кнопками. Фактическая матрица —
`tests/live-checklist.md` (хэши коммитов в нём — из истории wsconfig, где
проект жил до 2026-10-13). Поддерживаемая Shell version сейчас 50;
Hyprland adapter не реализован.
