ALTER TABLE exec.workout_unit_performances
    ADD COLUMN client_uuid uuid,
    ADD COLUMN received_at timestamptz NOT NULL DEFAULT now(),
    ADD COLUMN lease_device_id uuid,
    ADD COLUMN lease_epoch integer NOT NULL DEFAULT 1,
    ADD COLUMN applied_seq integer NOT NULL DEFAULT 0,
    ADD COLUMN revision integer NOT NULL DEFAULT 0,
    ADD COLUMN position_exercise_performance_uuid uuid,
    ADD COLUMN position_set_ordinal integer,
    ADD COLUMN position_phase text,
    ADD COLUMN final_seq integer,
    ADD CONSTRAINT workout_performances_client_uuid_unique UNIQUE (client_uuid),
    ADD CONSTRAINT workout_performances_lease_epoch_positive CHECK (lease_epoch > 0),
    ADD CONSTRAINT workout_performances_applied_seq_nonnegative CHECK (applied_seq >= 0),
    ADD CONSTRAINT workout_performances_revision_nonnegative CHECK (revision >= 0),
    ADD CONSTRAINT workout_performances_position_set_nonnegative
        CHECK (position_set_ordinal IS NULL OR position_set_ordinal >= 0),
    ADD CONSTRAINT workout_performances_position_phase_valid
        CHECK (position_phase IS NULL OR position_phase IN ('set', 'exercise_complete')),
    ADD CONSTRAINT workout_performances_final_seq_nonnegative
        CHECK (final_seq IS NULL OR final_seq >= 0);

UPDATE exec.workout_unit_performances
SET client_uuid = gen_random_uuid(),
    lease_device_id = '00000000-0000-4000-8000-000000000000'::uuid
WHERE client_uuid IS NULL;

-- The Execution lifecycle trigger is deferred. Flush its events before the
-- following ALTER TABLE, which PostgreSQL otherwise rejects as ObjectInUse.
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

ALTER TABLE exec.workout_unit_performances
    ALTER COLUMN client_uuid SET NOT NULL,
    ALTER COLUMN lease_device_id SET NOT NULL;

ALTER TABLE exec.exercise_unit_performances
    DROP CONSTRAINT exercise_unit_performances_mode_valid,
    ALTER COLUMN exercise_unit_track_id DROP NOT NULL;

ALTER TABLE exec.exercise_unit_performances
    ADD COLUMN client_uuid uuid,
    ADD COLUMN performed_ordinal integer,
    ADD COLUMN rev integer NOT NULL DEFAULT 0,
    ADD CONSTRAINT exercise_performances_client_uuid_unique UNIQUE (client_uuid),
    ADD CONSTRAINT exercise_performances_performed_ordinal_nonnegative
        CHECK (performed_ordinal IS NULL OR performed_ordinal >= 0),
    ADD CONSTRAINT exercise_performances_rev_nonnegative CHECK (rev >= 0),
    ADD CONSTRAINT exercise_unit_performances_mode_valid CHECK (
        (
            execution_mode IN ('as_prescribed', 'substituted')
            AND prescribed_exercise_unit_id IS NOT NULL
            AND exercise_unit_track_id IS NOT NULL
            AND actual_exercise_id IS NOT NULL
        )
        OR (
            execution_mode IN ('skipped', 'not_performed')
            AND prescribed_exercise_unit_id IS NOT NULL
            AND exercise_unit_track_id IS NOT NULL
            AND actual_exercise_id IS NULL
            AND actual_plan_exercise_variant_id IS NULL
        )
        OR (
            execution_mode = 'additional'
            AND prescribed_exercise_unit_id IS NULL
            AND actual_exercise_id IS NOT NULL
        )
    );

UPDATE exec.exercise_unit_performances
SET performed_ordinal = ordinal,
    client_uuid = gen_random_uuid()
WHERE performed_ordinal IS NULL OR client_uuid IS NULL;

ALTER TABLE exec.exercise_unit_performances
    ALTER COLUMN performed_ordinal SET NOT NULL,
    ALTER COLUMN client_uuid SET NOT NULL;

ALTER TABLE exec.set_performances
    DROP CONSTRAINT set_performances_status_values_valid;

ALTER TABLE exec.set_performances
    ADD COLUMN client_uuid uuid,
    ADD COLUMN rev integer NOT NULL DEFAULT 0,
    ADD COLUMN performed_at timestamptz,
    ADD COLUMN received_at timestamptz NOT NULL DEFAULT now(),
    ADD COLUMN heart_rate_bpm smallint,
    ADD CONSTRAINT set_performances_client_uuid_unique UNIQUE (client_uuid),
    ADD CONSTRAINT set_performances_rev_nonnegative CHECK (rev >= 0),
    ADD CONSTRAINT set_performances_heart_rate_valid
        CHECK (heart_rate_bpm IS NULL OR heart_rate_bpm BETWEEN 25 AND 250);

UPDATE exec.set_performances
SET performed_at = CASE WHEN status = 'performed' THEN recorded_at ELSE performed_at END,
    client_uuid = gen_random_uuid()
WHERE client_uuid IS NULL OR (status = 'performed' AND performed_at IS NULL);

ALTER TABLE exec.set_performances
    ALTER COLUMN client_uuid SET NOT NULL;

ALTER TABLE exec.set_performances
    ADD CONSTRAINT set_performances_status_values_valid CHECK (
        (status = 'performed' AND repetitions IS NOT NULL AND performed_at IS NOT NULL)
        OR (
            status IN ('skipped', 'not_performed')
            AND load_kg IS NULL
            AND repetitions IS NULL
            AND rir IS NULL
            AND heart_rate_bpm IS NULL
        )
    );

CREATE UNIQUE INDEX exercise_performances_actual_order_unique
    ON exec.exercise_unit_performances (workout_unit_performance_id, performed_ordinal);

CREATE UNIQUE INDEX workout_sessions_one_in_progress_per_run
    ON exec.workout_sessions (plan_run_id)
    WHERE status = 'in_progress';

CREATE TABLE exec.mobile_sync_ops (
    workout_unit_performance_id integer NOT NULL
        REFERENCES exec.workout_unit_performances(id) ON DELETE CASCADE,
    lease_epoch integer NOT NULL,
    seq integer NOT NULL,
    op_id uuid NOT NULL,
    client_at timestamptz NOT NULL,
    op_type text NOT NULL,
    payload jsonb NOT NULL,
    result_status text NOT NULL,
    result jsonb NOT NULL,
    applied_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (workout_unit_performance_id, lease_epoch, seq),
    CONSTRAINT mobile_sync_ops_op_id_unique UNIQUE (op_id),
    CONSTRAINT mobile_sync_ops_epoch_positive CHECK (lease_epoch > 0),
    CONSTRAINT mobile_sync_ops_seq_positive CHECK (seq > 0),
    CONSTRAINT mobile_sync_ops_payload_object CHECK (jsonb_typeof(payload) = 'object'),
    CONSTRAINT mobile_sync_ops_result_object CHECK (jsonb_typeof(result) = 'object'),
    CONSTRAINT mobile_sync_ops_result_status_valid
        CHECK (result_status IN ('applied', 'conflict', 'rejected'))
);

CREATE INDEX mobile_sync_ops_by_op_id
    ON exec.mobile_sync_ops (workout_unit_performance_id, op_id);

COMMENT ON TABLE exec.mobile_sync_ops IS
    'Append-only mobile delivery audit/idempotency log. Canonical workout facts remain in normalized performance tables.';
COMMENT ON COLUMN exec.workout_unit_performances.client_uuid IS
    'Stable mobile workout identity; historical rows are backfilled during migration.';
COMMENT ON COLUMN exec.workout_unit_performances.lease_device_id IS
    'Current mobile writer; a device identifier, not authentication.';
COMMENT ON COLUMN exec.exercise_unit_performances.performed_ordinal IS
    'Actual workout order, independent from immutable prescription order.';
COMMENT ON COLUMN exec.set_performances.performed_at IS
    'Client-observed performance time; received_at is server receipt time.';
