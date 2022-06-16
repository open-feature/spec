# Tracking Events

## Overview

Tracking Events are events that can be emitted by application developers.

### Definitions

TODO

### Emitting Tracking Events

#### Requirement 5.1.1

> The Client **MUST** have a method for emitting Tracking Events and must accept `event tracking options`

```js
Client client = OpenFeature.getClient();
`
//...

client.trackEvent('onboarding-completed', {
    version: '2022-06-16'
}, {
    trackingKey: 'user1'
});
```
### [Event tracking options](./types.md#event-tracking-options)

Usage might looks something like:

```python
val = client.track_event('my-key', attributes={
    'version': '2022-06-16'
}, evaluation_options={
    'trackingKey': 'user1'
})
```
