package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoadEnv(t *testing.T) {
	path := filepath.Join(t.TempDir(), "env")
	env := "# comment=ignored\n\nCC_A=https://x:443\n  CC_B=\"quoted=value\"\nnot a var\n"
	if err := os.WriteFile(path, []byte(env), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := loadEnv(path); err != nil {
		t.Fatal(err)
	}
	for k, want := range map[string]string{"CC_A": "https://x:443", "CC_B": "quoted=value", "# comment": ""} {
		if got := os.Getenv(k); got != want {
			t.Errorf("%s = %q, want %q", k, got, want)
		}
	}
}
