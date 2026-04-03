# Group, Subgroup, and Pre-Ride Notes

This update aligns the group and subgroup flows across the backend and Flutter app.

## What changed

- Group creation and subgroup creation now require an explicit visibility choice instead of forcing a default.
- Public subgroups are visible to all ride members.
- Private subgroups remain member-only.
- Subgroup creation now sends the correct payload shape and returns the created subgroup data without showing a false failure message on successful API responses.
- Subgroup settings now persist:
  - `visibility`
  - `membersCanSendMessages`
  - `membersCanAddMembers`
  - `adminsApproveMembers`
- "Add Members" now prevents duplicate ride invitations and shows `Invited` for users with a pending invite.
- Ride invite candidates are sorted with club friends first, then general friends as fallback.
- Pre-ride info is stored on `ride_groups` so all members see the same data after reload.

## ID model

The frontend now treats the IDs differently:

- `rideUuid`: the ride identifier used for ride-level APIs like participants, ride announcements, and subgroup listing
- `uuid`: the group identifier used for subgroup details, subgroup membership, subgroup permissions, and pre-ride info

For main ride groups returned from `/rides/my`, the app normalizes:

- `uuid = groupUuid`
- `rideUuid = ride.uuid`

This avoids mixing ride-level and subgroup-level endpoints.

## Invite behavior

Ride invite candidates come from:

- the rider's friends list
- club members first when the ride is attached to a club
- pending invite state from `ride_invitations`

The UI disables the invite action when an invitation is already pending.

## Pre-ride persistence

Pre-ride info is now stored in the `ride_groups` table so it stays consistent for all users.

Backend endpoints:

- `GET /api/v1/rides/groups/{groupUuid}/pre-ride-info`
- `PUT /api/v1/rides/groups/{groupUuid}/pre-ride-info`

Stored fields:

- `pre_ride_meeting_point`
- `pre_ride_fuel_stops`
- `pre_ride_checkpoints`
- `pre_ride_rules`
- `pre_ride_notes`
- `pre_ride_updated_at`

## Schema note

The `ride_groups` table now needs these additional columns:

- `admins_approve_members`
- `pre_ride_meeting_point`
- `pre_ride_fuel_stops`
- `pre_ride_checkpoints`
- `pre_ride_rules`
- `pre_ride_notes`
- `pre_ride_updated_at`

They have been added to `db/init/01_init_schema.sql`.
