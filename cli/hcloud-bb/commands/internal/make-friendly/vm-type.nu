use std-rfc/iter
use ../../../util/cli-constants.nu *

export def main [
	locationName: string,
	additionalFields: list<string> = []
]: record -> record {
	let vmType = $in
	let hourlyPrice = (
		$vmType.prices
		| where location == $locationName
		| iter only
		| get price_hourly
		| get gross
		| into float
	)

	$vmType
	| select name architecture memory cpu_type cores ...$additionalFields
	| insert $CURRENCY_PER_HOUR $hourlyPrice
}
