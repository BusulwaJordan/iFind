-- =============================================================================
-- Migration 09: Business creation guardrails
-- =============================================================================
-- Keep public shop creation limited to users with a business-facing role,
-- require enough contact detail for moderation/customer trust, and approve
-- new shops automatically when they pass those rules.

ALTER TABLE public.businesses
    ALTER COLUMN verification_status SET DEFAULT 'pending',
    ALTER COLUMN is_verified SET DEFAULT FALSE;

ALTER TABLE public.businesses
    ADD CONSTRAINT businesses_contact_required
    CHECK (
        phone IS NOT NULL
        AND length(trim(phone)) >= 7
        AND email IS NOT NULL
        AND position('@' IN email) > 1
        AND address IS NOT NULL
        AND length(trim(address)) >= 6
    ) NOT VALID;

CREATE OR REPLACE FUNCTION public.apply_business_auto_verification()
RETURNS TRIGGER AS $$
BEGIN
    IF auth.role() = 'service_role' THEN
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT' THEN
        NEW.is_verified := TRUE;
        NEW.verification_status := 'verified';
    ELSIF TG_OP = 'UPDATE' THEN
        NEW.is_verified := OLD.is_verified;
        NEW.verification_status := OLD.verification_status;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_prevent_business_self_verification
    ON public.businesses;
DROP FUNCTION IF EXISTS public.prevent_business_self_verification();

DROP TRIGGER IF EXISTS trg_apply_business_auto_verification
    ON public.businesses;
CREATE TRIGGER trg_apply_business_auto_verification
    BEFORE INSERT OR UPDATE ON public.businesses
    FOR EACH ROW
    EXECUTE FUNCTION public.apply_business_auto_verification();

DROP POLICY IF EXISTS "Owners can view own businesses" ON public.businesses;
DROP POLICY IF EXISTS "Owners can manage own businesses" ON public.businesses;

CREATE POLICY "Owners can view own businesses"
    ON public.businesses FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Business users can create auto-approved businesses"
    ON public.businesses FOR INSERT
    WITH CHECK (
        auth.uid() = owner_id
        AND is_verified = TRUE
        AND verification_status = 'verified'
        AND EXISTS (
            SELECT 1
            FROM public.users
            WHERE users.id = auth.uid()
              AND users.role IN ('business_owner', 'manager')
        )
    );

CREATE POLICY "Owners can update own businesses"
    ON public.businesses FOR UPDATE
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can delete own businesses"
    ON public.businesses FOR DELETE
    USING (auth.uid() = owner_id);
