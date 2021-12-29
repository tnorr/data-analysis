# A script to tell which competitions filled the fastest after registration for them opened

CREATE TEMPORARY TABLE reg_info1 AS (

# Timestamp of strictly Nth accepted registration:
WITH N AS
(SELECT id, accepted_at Nth_accepted_at
FROM
	(SELECT c.id, c.countryId, c.competitor_limit, r.accepted_at,
		row_number() OVER (PARTITION BY c.id ORDER BY accepted_at) acceptedNo
	FROM Competitions c
	LEFT JOIN registrations r ON c.id = r.competition_id
	WHERE year = 2021 AND use_wca_registration = 1 AND competitor_limit_enabled = 1
		AND accepted_at IS NOT NULL) a
WHERE acceptedNo = competitor_limit)

# List of first N accepted registrations, ignoring those that were deleted before the timestamp from above:
SELECT *
FROM
	(SELECT c.id, c.countryId, c.registration_open, c.competitor_limit, CONCAT(c.base_entry_fee_lowest_denomination/100, ' ', currency_code) entry_fee,
		r.id registration_id, r.created_at, r.accepted_at, r.deleted_at, 
		row_number() OVER (PARTITION BY c.id ORDER BY accepted_at) acceptedNo
	FROM Competitions c
	LEFT JOIN registrations r ON c.id = r.competition_id
    LEFT JOIN N ON c.id = N.id
	WHERE c.year = 2021 AND c.use_wca_registration = 1 AND c.competitor_limit_enabled = 1
		AND r.accepted_at IS NOT NULL AND c.cancelled_at IS NULL
        AND (r.deleted_at IS NULL OR r.deleted_at > N.Nth_accepted_at)) a
WHERE acceptedNo <= competitor_limit
ORDER BY id, acceptedNo
)
;

# Join payment information to these registrations and calculate the registration time:
CREATE TEMPORARY TABLE reg_info2 AS 
(SELECT r.*, p.created_at paid_at, 
	TIMEDIFF(IF(accepted_at < p.created_at, accepted_at, IF(p.created_at is NULL, r.created_at, p.created_at)), r.registration_open) reg_time
    /* Explanation of reg_time: time from when registration opened to when registration was paid for, and if not applicable, to when the registration was created. 
	However, if the registration was accepted but still paid for later, acceptance time is used. */
FROM reg_info1 r
LEFT JOIN registration_payments p ON r.registration_id = p.registration_id
WHERE refunded_registration_payment_id IS NULL)
;

# Finally, select the longest registration time from each competition:
SELECT id competitionId, countryId, competitor_limit, entry_fee, COUNT(paid_at) paid_online, MAX(reg_time) fill_time 
FROM reg_info2
GROUP BY id
ORDER BY fill_time;
