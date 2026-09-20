package utils

import (
	"regexp"
	"testing"
)

func TestForkBuildIdentity(t *testing.T) {
	if matched, _ := regexp.MatchString(`^\d+\.\d+\.\d+$`, ForkVersion); !matched {
		t.Fatalf("ForkVersion %q must be numeric semver", ForkVersion)
	}
	if Edition == "" {
		t.Fatal("Edition must not be empty")
	}
	if matched, _ := regexp.MatchString(`^[0-9a-f]{40}$`, UpstreamCommit); !matched {
		t.Fatalf("UpstreamCommit %q must be a full Git commit SHA", UpstreamCommit)
	}
}
