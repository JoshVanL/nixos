package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"time"
)

func main() {
	if _, err := exec.LookPath("xprop"); err != nil {
		fatal(fmt.Errorf("failed to find xprop: %w", err))
	}

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, os.Kill)
	defer cancel()

	// Used to ensure we update the time at least once a minute to cover cases
	// like waking from sleep where the underlying ticker may be out of whack
	// with the system time.
	fallbackTicker := time.NewTicker(time.Second * 60)
	defer fallbackTicker.Stop()

	for {
		now := time.Now().Local()

		xprop(ctx, fmt.Sprintf("%s %d/%.2d/%.2d %.2d:%.2d",
			now.Weekday(), now.Year(), now.Month(), now.Day(), now.Hour(), now.Minute(),
		))

		uni := now.Unix()
		nextMin := time.Unix((uni-uni%60)+60, 0)
		nextMinTicker := time.NewTicker(nextMin.Sub(now))
		select {
		case <-ctx.Done():
			xprop(context.Background(), "X")
			return
		case <-nextMinTicker.C:
		case <-fallbackTicker.C:
		}

		nextMinTicker.Stop()
	}
}

func fatal(err error) {
	fmt.Fprintf(os.Stderr, "error: %s\n", err)
	os.Exit(1)
}

func xprop(ctx context.Context, name string) {
	cmd := exec.CommandContext(ctx, "xprop", "-root", "-set", "WM_NAME", name)
	if err := cmd.Run(); err != nil {
		fatal(fmt.Errorf("failed to run xprop: %w", err))
	}
}
