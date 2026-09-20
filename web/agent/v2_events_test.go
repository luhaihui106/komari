package agent

import (
	"testing"

	v2 "github.com/komari-monitor/komari/protocol/v2"
)

func TestV2EventCoalesceKeyPreservesPingContract(t *testing.T) {
	event := v2.Event{
		Method: v2.MethodAgentPing,
		Params: v2.PingParams{TaskID: 42, Type: "icmp", Target: "192.0.2.1"},
	}

	if got, want := v2EventCoalesceKey(event), "agent.ping:42"; got != want {
		t.Fatalf("v2EventCoalesceKey() = %q, want %q", got, want)
	}
}

func TestV2EventCoalesceKeyDoesNotCoalesceFileOperations(t *testing.T) {
	event := v2.Event{
		Method: v2.MethodAgentFile,
		Params: v2.FileOperation{RequestID: "request-1", Op: "stat"},
	}

	if got := v2EventCoalesceKey(event); got != "" {
		t.Fatalf("v2EventCoalesceKey() = %q, want no coalescing for file operations", got)
	}
}
