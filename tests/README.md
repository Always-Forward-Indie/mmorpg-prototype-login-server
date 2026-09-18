# Login unit tests (gtest)

Same pattern as chunk/game `tests/`: one file per unit (`test_<name>.cpp`),
built as `unit_tests` by the normal server build.

## Run (from inside the dev container)

```bash
ctest --test-dir /usr/src/app/build --output-on-failure
```

## Add a test

1. Create `tests/test_<name>.cpp` with `TEST`/`TEST_F` cases.
2. Append the file plus the needed `../src/**/*.cpp` to `tests/CMakeLists.txt`
   (`AccountManager.cpp` needs `PkgConfig::libpqxx` + `OpenSSL::Crypto`,
   already linked in `tests/CMakeLists.txt`).
3. DB-backed paths (`registerAccount` past validation, `Authenticator`) cannot
   run without PostgreSQL: test the pure parts (`validateRegistration`,
   `hashPassword`) here, the rest via bots/contract tests.

## Rules

- Unit-test pure logic only (validation, hashing, queues). Anything needing
  live DB or sockets belongs to contract tests (`Tests/Contract`) or bots
  (`Tools/Bots`), not here.
- `tests/` is mounted into the container but ignored by `watch_and_run.sh`,
  so editing tests never restarts the server.
