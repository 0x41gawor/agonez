-- Enum values are committed separately because PostgreSQL does not allow a value
-- added by ALTER TYPE to be used by constraints in the same transaction.
ALTER TYPE exec.exercise_execution_mode ADD VALUE IF NOT EXISTS 'not_performed';
ALTER TYPE exec.performed_set_status ADD VALUE IF NOT EXISTS 'not_performed';
