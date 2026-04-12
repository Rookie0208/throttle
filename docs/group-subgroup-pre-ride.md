# Group, Subgroup, and Pre-Ride Notes

This update aligns the group and subgroup flows across the backend and Flutter app.

## What changed

- Group creation and subgroup creation now require an explicit visibility choice instead of forcing a default.
- Public subgroups are visible to all ride members.
- Private subgroups remain member-only.
- Public subgroups are discoverable by all ride members, but subgroup chat and active participation still require subgroup membership.
- Subgroup creation now sends the correct payload shape and returns the created subgroup data without showing a false failure message on successful API responses.
- Subgroup settings now persist:
  - `visibility`
  - `membersCanSendMessages`
  - `membersCanAddMembers`
  - `adminsApproveMembers`
- "Add Members" now prevents duplicate ride invitations and shows `Invited` for users with a pending invite.
- Ride invite candidates are sorted with club friends first, then general friends as fallback.
- Pre-ride info is stored on `ride_groups` so all members see the same data after reload.
- Public subgroup self-join now respects subgroup settings:
  - direct join when approval is not required
  - join request when approval is required
- Subgroup managers can approve or reject pending subgroup join requests.
- Exiting a subgroup removes access to that subgroup chat until the rider is added again.
- Exiting the main ride removes the rider from the ride and its subgroup memberships.

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

## Join and leave behavior

Subgroup behavior:

- `GET /api/v1/rides/{rideUuid}/subgroups` returns discoverable subgroups for the ride
- `POST /api/v1/rides/groups/{groupUuid}/join` joins immediately or creates a join request depending on subgroup settings
- `GET /api/v1/rides/groups/{groupUuid}/join-requests` returns pending join requests for subgroup managers
- `POST /api/v1/rides/groups/{groupUuid}/join-requests/{requestId}/approve` approves a join request
- `POST /api/v1/rides/groups/{groupUuid}/join-requests/{requestId}/reject` rejects a join request
- `DELETE /api/v1/rides/groups/{groupUuid}/leave` removes the current rider from the subgroup

Ride behavior:

- `POST /api/v1/participants/{rideUuid}/leave` removes the current rider from the main ride and from subgroup memberships tied to that ride

Manager restrictions:

- `CAPTAIN`, `ADMIN`, and `CO_CAPTAIN` can create subgroups and manage subgroup requests
- managers cannot leave a ride or subgroup if that would leave the group without a manager
- managers can rename groups from the group info menu

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
