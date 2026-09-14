# Ultimate Menu for Nenyoo (GTA V Legacy)

This edition runs the YimMenu Legacy script through a Nenyoo API adapter. The bundled `lib/Ultimate_Menu_Legacy.lua` is an unchanged copy of `YimMenu/Ultimate_Menu_Legacy.lua`; the original menu hierarchy and action callbacks remain in one source file. YimMenu tabs, ImGui groups, controls, and popups appear as nested Nenyoo menu lists. Controls that depend on game state are added when their conditions become true.

Copy this folder to `Documents\Nenyoo\scripts\user\UltimateMenu\`, then enable `Ultimate_Menu.lua` from Nenyoo's Scripts menu. Keep the `lib` folder beside the entry script. The script targets GTA V Legacy build 3889 and uses the online menus only after joining GTA Online.

The adapter requires a Nenyoo build exposing `__ny_execute_as_script` and `__ny_request_script_host`. The host request uses Nenyoo's cooperative script-host election and cannot evict a healthy current host. Actions that rely on becoming mission-script host therefore need in-game validation. GTA V Enhanced is outside this edition's scope.

The mock-runtime check in `lib/tests/load_yim_test.lua` covers menu construction, all exposed action and input callbacks, stat and native return bridges, and controls that appear after a game-state change. Run it with Lua 5.4 from the repository root. It does not validate GTA Online results or the visual menu in a running game.
