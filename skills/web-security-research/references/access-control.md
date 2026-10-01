# Access Control Research

## Horizontal Authorization

Use controlled accounts when appropriate:

Account A = active test account
Account B = separate controlled account

Determine whether Account A can improperly access Account B's
resources.

Review:

- read
- update
- delete
- sharing
- ownership
- security settings
- account settings

## Vertical Authorization

Where authorized test roles exist, compare:

lower privilege
vs
higher privilege

Determine whether functionality intended for the higher privilege is
available to the lower privilege.

## Verification

Do not rely only on HTTP status.

Verify the affected resource and resulting application state.
