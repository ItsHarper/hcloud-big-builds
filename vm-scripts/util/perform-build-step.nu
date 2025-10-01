use ./vm-constants.nu *

const STEP_DURATIONS_CSV_PATH = ($BUILD_LOGS_DIR)/stepDurations.csv
const NEXT_STEP_NUMBER_PATH = ($BUILD_LOGS_DIR)/.nextStepNumber

export def prepare-build-logs-dir []: nothing -> nothing {
	if ($BUILD_LOGS_DIR | path exists) {
		rm -r $BUILD_LOGS_DIR
	}
	mkdir $BUILD_LOGS_DIR
	"Step discription,duration\n" | save $STEP_DURATIONS_CSV_PATH
	1 | save $NEXT_STEP_NUMBER_PATH
}

export def main [stepDesc: string, step: closure]: nothing -> nothing {
	let stepNumber = open $NEXT_STEP_NUMBER_PATH | into int
	let stepLogPath = $"($BUILD_LOGS_DIR)/($stepNumber |  fill --width 4 --character 0 --alignment right) - ($stepDesc).txt"
	$stepNumber + 1 | save -f $NEXT_STEP_NUMBER_PATH

	let header = $"Beginning build step: ($stepDesc)"
	print $"\n\n($header)\n\n"
	$"($header)\n\n" | save $stepLogPath

	let duration: string = (
		timeit {
			do $step err+out>| tee { save --append $stepLogPath }
			null
		}
		| format duration min
	)

	$"($stepDesc),($duration)\n" | save --append $STEP_DURATIONS_CSV_PATH
	print $"Spent ($duration) on build step: ($stepDesc)"
}
