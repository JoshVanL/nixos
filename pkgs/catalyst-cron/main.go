// catalyst-cron runs systemd units on a cron schedule, using Dapr workflows
// hosted on Diagrid Catalyst in place of systemd timers.
package main

import (
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/dapr/durabletask-go/workflow"
	"github.com/dapr/go-sdk/client"

	"github.com/joshvanl/catalyst-cron/internal/job"
	"github.com/joshvanl/catalyst-cron/internal/workflows"
)

func main() {
	configPath := flag.String("config", "", "path to JSON list of jobs")
	flag.Parse()

	jobs, err := job.Load(*configPath)
	if err != nil {
		log.Fatal(err)
	}

	host, err := os.Hostname()
	if err != nil {
		log.Fatal(err)
	}

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	wf, err := client.NewWorkflowClient()
	if err != nil {
		log.Fatal(err)
	}

	r := workflow.NewRegistry()
	if err := workflows.Register(r); err != nil {
		log.Fatal(err)
	}
	if err := wf.StartWorker(ctx, r); err != nil {
		log.Fatal(err)
	}

	for _, j := range jobs {
		if err := workflows.Ensure(ctx, wf, host+"-"+j.Name, j); err != nil {
			log.Fatalf("job %s: %v", j.Name, err)
		}
	}

	<-ctx.Done()
}
