# Dapr: integration tests

When working on dapr (dapr/dapr or forks) and running integration tests, ALWAYS pre-build the binaries into a session-unique directory and pass their paths via env vars. NEVER let the test framework build them itself.

Why: if `DAPR_INTEGRATION_<NAME>_PATH` is unset, the framework (`tests/integration/framework/binary/binary.go`) builds each binary to the shared path `$TMPDIR/dapr_integration_tests/<name>`. Two Claude sessions running at the same time (on different branches or worktrees) will overwrite each other's binaries there, causing tests to silently run against the wrong code.

How to apply, before any `go test ./tests/integration/...` run:

1. Build all binaries into a directory unique to this session (e.g. the session scratchpad dir), from the repo root with `CGO_ENABLED=0`:
   - `daprd`, `placement`, `sentry`, `operator`, `injector`, `scheduler`: `CGO_ENABLED=0 go build -tags=allcomponents -o "$BIN_DIR/<name>" ./cmd/<name>`
   - `helmtemplate`: `cd tests/integration/framework/binary/helpers && CGO_ENABLED=0 go build -C helmtemplate -o "$BIN_DIR/helmtemplate" .`
2. Export the corresponding env vars for the test run: `DAPR_INTEGRATION_DAPRD_PATH`, `DAPR_INTEGRATION_PLACEMENT_PATH`, `DAPR_INTEGRATION_SENTRY_PATH`, `DAPR_INTEGRATION_OPERATOR_PATH`, `DAPR_INTEGRATION_INJECTOR_PATH`, `DAPR_INTEGRATION_SCHEDULER_PATH`, `DAPR_INTEGRATION_HELMTEMPLATE_PATH`, each pointing at the binary built in step 1.
3. Only build the subset a test actually needs if the full set is unnecessary, but every binary the test uses must come from the session-unique dir with its env var set.
4. After code changes, rebuild the affected binaries before re-running tests; the framework will not rebuild them when the env vars are set.
