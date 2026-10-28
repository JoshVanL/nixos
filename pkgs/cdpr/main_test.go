package main

import (
	"fmt"
	"testing"
)

func TestParsePR(t *testing.T) {
	for arg, want := range map[string]string{
		"https://github.com/dapr/kit/pull/173":               "dapr/kit#173",
		"https://github.com/dapr/kit/pull/173/files":         "dapr/kit#173",
		"https://github.com/dapr/kit/pull/173#discussion_r1": "dapr/kit#173",
		"https://github.com/dapr/kit/pull/173?w=1":           "dapr/kit#173",
		"https://github.com/dapr/go-sdk.x/pull/9":            "dapr/go-sdk.x#9",

		"dapr/kit#173": "dapr/kit#173",

		"https://github.com/dapr/kit/pull/173abc": "",
		"https://github.com/dapr/kit/issues/173":  "",
		"https://gitlab.com/dapr/kit/pull/173":    "",
		"https://github.com/dapr/../pull/173":     "",
		"../kit#173":                              "",
		"dapr/kit#":                               "",
		"dapr/kit":                                "",
		"":                                        "",
	} {
		owner, repo, n, err := parsePR(arg)
		got := ""
		if err == nil {
			got = fmt.Sprintf("%s/%s#%d", owner, repo, n)
		}
		if got != want {
			t.Errorf("%q: got %q (err %v), want %q", arg, got, err, want)
		}
	}
}
