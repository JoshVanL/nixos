// Package xnotify sends desktop notifications via notify-send, working from
// systemd user units where DBUS_SESSION_BUS_ADDRESS may be unset.
package xnotify

import (
	"fmt"
	"os"
	"os/exec"
)

// Send fires a desktop notification. Failures are non-fatal by design: a
// headless or console session simply drops the notification.
func Send(urgency, summary, body string) {
	cmd := exec.Command("notify-send", "--app-name=cdgo", "--urgency="+urgency, summary, body)
	cmd.Env = os.Environ()
	if os.Getenv("DBUS_SESSION_BUS_ADDRESS") == "" {
		cmd.Env = append(cmd.Env,
			fmt.Sprintf("DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%d/bus", os.Getuid()))
	}
	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, ">> warning: notify-send: %v\n", err)
	}
}
