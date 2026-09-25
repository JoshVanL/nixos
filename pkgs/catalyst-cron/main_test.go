package main

import (
	"testing"
	"time"
)

func TestNextRun(t *testing.T) {
	loc, err := time.LoadLocation("America/Sao_Paulo")
	if err != nil {
		t.Fatal(err)
	}
	orig := time.Local
	time.Local = loc
	t.Cleanup(func() { time.Local = orig })

	// 2026-09-25 15:30 UTC is 12:30 in Sao Paulo (UTC-3).
	now := time.Date(2026, 9, 25, 15, 30, 0, 0, time.UTC)

	for spec, want := range map[string]time.Time{
		"0 13 * * *":                       time.Date(2026, 9, 25, 16, 0, 0, 0, time.UTC),
		"0 12 * * *":                       time.Date(2026, 9, 26, 15, 0, 0, 0, time.UTC),
		"0 0 * * 1":                        time.Date(2026, 9, 28, 3, 0, 0, 0, time.UTC),
		"CRON_TZ=Europe/London 0 13 * * *": time.Date(2026, 9, 26, 12, 0, 0, 0, time.UTC),
	} {
		got, err := nextRun(spec, now)
		if err != nil {
			t.Fatalf("%s: %v", spec, err)
		}
		if !got.Equal(want) {
			t.Errorf("%s: got %s, want %s", spec, got, want)
		}
	}

	if _, err := nextRun("not a cron", now); err == nil {
		t.Error("expected error for invalid spec")
	}
}
