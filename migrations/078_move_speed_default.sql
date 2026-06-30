-- 078_move_speed_default.sql
-- Increase base move_speed from 7.0 to 8.0 for both classes.
-- Base world speed: 8.0 × 40 = 320 units/s (was 7.0 × 40 = 280 units/s).

UPDATE public.class_stat_formula SET base_value = 8.00 WHERE attribute_id = 18;
