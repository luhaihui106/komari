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
