# Ultimate Menu for Nenyoo (GTA V Legacy)

This edition runs the YimMenu Legacy script through a Nenyoo API adapter. The menu hierarchy and action callbacks come from the YimMenu Legacy source, with its GTA globals and script locals extracted into `lib/game_offsets.lua`. YimMenu tabs, controls, and popups appear as nested Nenyoo menu lists. Informational text and live status appear in a companion panel only while their submenu is open; hover the panel and use the mouse wheel for longer instructions. Controls that depend on game state are added when their conditions become true.

Copy the contents of this folder to `%LOCALAPPDATA%\Nenyoo\Plus\Scripts\User\UltimateMenu\`, then select `Ultimate_Menu.lua` from Nenyoo's Scripts menu to load its page. Keep the `lib` folder beside the entry script. The script targets GTA V Legacy build 3889 and uses the online menus only after joining GTA Online.

When a GTA update changes script addresses, update the named entries in `lib/game_offsets.lua`. The file separates `globals`, `locals`, and script names and keeps dynamic address formulas beside their bases. Feature code should not contain raw global or local addresses.

The adapter requires a Nenyoo build exposing `__ny_execute_as_script` and `__ny_request_script_host`. The host request uses Nenyoo's cooperative script-host election and cannot evict a healthy current host. Actions that rely on becoming mission-script host therefore need in-game validation. GTA V Enhanced is outside this edition's scope.

The mock-runtime check in `lib/tests/load_yim_test.lua` covers menu construction, all exposed action and input callbacks, stat and native return bridges, and controls that appear after a game-state change. Run it with Lua 5.4 from the repository root. It does not validate GTA Online results or the visual menu in a running game.

Follow [TESTING.md](TESTING.md) for the in-game checks and a failure-report template.
