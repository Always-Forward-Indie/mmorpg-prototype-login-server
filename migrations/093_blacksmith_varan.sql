-- 093_blacksmith_varan.sql
-- Only blacksmith NPCs repair (openRepairShop rejects other types with
-- not_a_blacksmith). Varan (id 1, Varan village smith) becomes the
-- blacksmith; he keeps his vendor stock (openVendorShop is not type-gated).
UPDATE public.npc SET npc_type = 4 WHERE id = 1;
