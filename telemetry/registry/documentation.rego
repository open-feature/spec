package after_resolution

import rego.v1

sections := {"evaluation", "flag_metadata", "provider_metadata"}
attribute_fields := {"section", "source", "notes"}
event_fields := {"source_headings"}

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
