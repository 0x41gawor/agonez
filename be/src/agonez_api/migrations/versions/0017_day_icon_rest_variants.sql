-- More ways to mark a rest day: a bed, a battery and a pair of Zs beside the moon.
-- Enum values are added in their own migration because PostgreSQL does not allow a
-- value added by ALTER TYPE to be used by constraints in the same transaction.
ALTER TYPE plans.day_icon ADD VALUE IF NOT EXISTS 'bed';
ALTER TYPE plans.day_icon ADD VALUE IF NOT EXISTS 'recharge';
ALTER TYPE plans.day_icon ADD VALUE IF NOT EXISTS 'sleep';
