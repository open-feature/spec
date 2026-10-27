package after_resolution

import rego.v1

sections := {"evaluation", "flag_metadata", "provider_metadata"}
recommendations := {"required", "conditionally_required", "recommended", "opt_in"}
attribute_fields := {"section", "source", "notes", "footnote", "recommendation"}
event_fields := {"source_headings", "footnotes"}

finding(id, event, message) := {
    "id": id,
    "level": "violation",
    "signal_type": "log",
    "signal_name": event.name,
    "message": message,
}

deny contains finding("openfeature_unknown_section", event, message) if {
    some event in input.refinements.events
    some attr in event.attributes
    section := attr.annotations.openfeature.section
    not section in sections
    message := sprintf("Unknown OpenFeature section %v on %s.", [section, attr.key])
}

deny contains finding("openfeature_unknown_recommendation", event, message) if {
    some event in input.refinements.events
    some attr in event.attributes
    recommendation := attr.annotations.openfeature.recommendation
    not recommendation in recommendations
    message := sprintf("Unknown documentation recommendation %v on %s.", [recommendation, attr.key])
}

deny contains finding("openfeature_unknown_attribute_annotation", event, message) if {
    some event in input.refinements.events
    some attr in event.attributes
    some field in object.keys(attr.annotations.openfeature)
    not field in attribute_fields
    message := sprintf("Unknown OpenFeature annotation %s on %s.", [field, attr.key])
}

deny contains finding("openfeature_unknown_event_annotation", event, message) if {
    some event in input.refinements.events
    some field in object.keys(event.annotations.openfeature)
    not field in event_fields
    message := sprintf("Unknown OpenFeature event annotation %s.", [field])
}

deny contains finding("openfeature_missing_footnote", event, message) if {
    some event in input.refinements.events
    some attr in event.attributes
    id := attr.annotations.openfeature.footnote
    not id in {footnote.id | some footnote in event.annotations.openfeature.footnotes}
    message := sprintf("Undefined footnote %v on %s.", [id, attr.key])
}

deny contains finding("openfeature_duplicate_footnote", event, message) if {
    some event in input.refinements.events
    some footnote in event.annotations.openfeature.footnotes
    count([other | some other in event.annotations.openfeature.footnotes; other.id == footnote.id]) > 1
    message := sprintf("Duplicate footnote id %v.", [footnote.id])
}

deny contains finding("openfeature_invalid_footnote", event, message) if {
    some event in input.refinements.events
    some footnote in event.annotations.openfeature.footnotes
    not valid_footnote(footnote)
    message := sprintf("Footnotes need a positive integer id and non-empty text: %v.", [footnote])
}

valid_footnote(footnote) if {
    is_number(footnote.id)
    footnote.id > 0
    floor(footnote.id) == footnote.id
    is_string(footnote.text)
    trim_space(footnote.text) != ""
}

deny contains finding("openfeature_invalid_text", event, message) if {
    some event in input.refinements.events
    some attr in event.attributes
    some field in {"source", "notes"}
    value := attr.annotations.openfeature[field]
    not is_string(value)
    message := sprintf("OpenFeature %s must be text on %s.", [field, attr.key])
}

deny contains finding("openfeature_missing_heading", event, message) if {
    some event in input.refinements.events
    event.annotations.openfeature
    some section in sections
    not valid_heading(event, section)
    message := sprintf("Missing or invalid heading for %s.", [section])
}

valid_heading(event, section) if {
    heading := event.annotations.openfeature.source_headings[section]
    is_string(heading)
    trim_space(heading) != ""
}

deny contains finding("openfeature_unknown_heading", event, message) if {
    some event in input.refinements.events
    some section in object.keys(event.annotations.openfeature.source_headings)
    not section in sections
    message := sprintf("Unknown OpenFeature table heading %s.", [section])
}
