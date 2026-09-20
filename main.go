package main

import (
	"log/slog"

	"github.com/komari-monitor/komari/cmd"
	"github.com/komari-monitor/komari/utils"
	logger "github.com/komari-monitor/komari/utils/log"
)

func main() {
	if utils.VersionHash == "unknown" {
		logger.Setup(slog.LevelDebug)
	} else {
		logger.Setup(slog.LevelInfo)
	}

	logger.Infof(
		"server",
		"Komari Monitor %s (edition: %s, upstream: %s, hash: %s)",
		utils.CurrentVersion,
		utils.Edition,
		utils.UpstreamCommit,
		utils.VersionHash,
	)

	cmd.Execute()
}
