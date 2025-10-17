use std-rfc/iter
use ../../../util/cli-constants.nu *

## TODO(Harper): Delete `cell-path-join`, `only-error`, and `iter only` once https://github.com/nushell/nushell/pull/16886 gets released
def cell-path-join []: list<cell-path> -> cell-path {
    each {|e| try { split cell-path } catch { $e } }
    | flatten
    | into cell-path
}
def only-error [msg: string, meta: record, label: string]: nothing -> error {
  error make {
    msg: $msg,
    label: {
      text: $label,
      span: $meta.span,
    }
  }
}
def "iter only" [
  --optional # Return `null` if there are no elements (does not affect behavior of the optional cell path argument)
  cell_path?: cell-path # The cell path to access within the only element.
]: [table -> any, list -> any] {
  let pipe = {in: $in, meta: (metadata $in)}
  let path = [0 $cell_path] | cell-path-join
  match ($pipe.in | length) {
    0 if $optional => null
    0 => (only-error "expected non-empty table/list" $pipe.meta "empty")
    1 => ($pipe.in | get $path)
    _ => (only-error "expected only one element in table/list" $pipe.meta "has more than one element")
  }
}

export def main [
	locationName: string,
	additionalFields: list<string> = []
]: record -> record {
	let vmType = $in
	let price  = (
		$vmType.prices
		| where location == $locationName
		| iter only --optional
	)

	if $price == null {
		$vmType | to json | print
		error make { msg: $"VM type ($vmType.name) is not supported in location ($locationName)" }
	}

	let hourlyPrice = (
		$price
		| get price_hourly
		| get gross
		| into float
	)

	$vmType
	| select name architecture category memory cpu_type cores ...$additionalFields
	| insert $CURRENCY_PER_HOUR $hourlyPrice
}
