use std-rfc/iter

print ""
print "run.nu"
print "------\n"

# Verify that we're running in Google Cloud, so we don't have to worry
# too much about accidentally fucking up someone's everyday setup
let googleMetadataFlavor = (
	http --full metadata.google.internal
	| get headers
	| get response
	| where name == "Metadata-Flavor" and value == "Google"
	| iter only 
)
