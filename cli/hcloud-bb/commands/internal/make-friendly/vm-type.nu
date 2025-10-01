use std-rfc/iter
use ../../../util/cli-constants.nu *

export def main [locationName: string]: record -> record {
	let vmType = $in
	let hourlyPrice = (
		$vmType.prices
		| where location == $locationName
		| iter only
		| get price_hourly
		| get gross
		| into float
		| $"€ ($in)"
	)

	$vmType
	| select name cpu_type cores memory
	| insert "price/hr" $hourlyPrice
}
