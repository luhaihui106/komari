package utils

var (
	// CurrentVersion is the independent version line of this lightweight fork.
	// Release workflows may override it with -ldflags.
	CurrentVersion = "0.1.0"
	VersionHash    = "unknown"

	// Edition distinguishes this fork from the archived upstream distribution.
	Edition = "lightweight-dev"

	// UpstreamCommit records the immutable server baseline used to create the fork.
	UpstreamCommit = "0ca87aafd184ed75f9030ede0902772142af5eec"
)
