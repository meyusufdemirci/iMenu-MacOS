# TODO

- [ ] Wire up the "Launch at login" preference to real behavior. Today
      `SettingsStore.launchAtLogin` only persists the intent to `UserDefaults`;
      nothing registers the login item. Implement with `SMAppService.mainApp`
      (`ServiceManagement`) — the modern API for the macOS 26.5 target (no helper
      bundle, no deprecated `SMLoginItemSetEnabled`):
    - Add a `LoginItemControlling` protocol (`isEnabled`, `setEnabled(_:) throws`)
      and an `SMAppServiceLoginItem` production impl wrapping
      `SMAppService.mainApp.register()` / `.unregister()` / `.status`. Inject it
      into `SettingsStore` so tests use a spy (mirror the `LogHandler` pattern).
    - In `launchAtLogin`'s `didSet`, call `setEnabled`, map a thrown error to a
      new `AppError.loginItemFailed(String)` case, and log via `AppLogger`
      (`.lifecycle`).
    - On `init`, reconcile the toggle to `loginItem.isEnabled` — System Settings ›
      Login Items is the source of truth (user can disable it there).
    - TDD + add the new `AppError` case's `L10n.Errors` + `Localizable.xcstrings`
      strings.
    - Note: `register()` only succeeds in a signed app run from `/Applications`;
      it throws from Xcode/DerivedData debug builds. Handle `.requiresApproval`
      (optionally `SMAppService.openSystemSettingsLoginItems()`).
- [ ] Publish the project via Homebrew and other package management tools
- [ ] Publish the app in the App Store
- [ ] Market on Reddit, Hacker News, LinkedIn, X, and developer forums
