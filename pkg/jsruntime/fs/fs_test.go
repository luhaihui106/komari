package fs

import (
	"testing"

	"github.com/dop251/goja"
)

func TestFSModeTreatsEncodingStringAsOptions(t *testing.T) {
	vm := goja.New()
	if got := fsMode(vm.ToValue("utf8"), 0o666); got != 0o666 {
		t.Fatalf("fsMode(utf8) = %04o, want 0666", got)
	}
	if got := fsMode(vm.ToValue("600"), 0o666); got != 0o600 {
		t.Fatalf("fsMode(600) = %04o, want 0600", got)
	}
}
