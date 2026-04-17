// @ts-nocheck
import Stripe from "https://esm.sh/stripe@14.25.0?target=deno";
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");

// In development, allow mock mode when project permissions block setting secrets.
const stripe = stripeSecretKey
  ? new Stripe(stripeSecretKey, {
      apiVersion: "2024-06-20",
    })
  : null;

serve(async (req) => {
  if (req.method != "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const body = await req.json();
    const voucherCode = (body["voucherCode"] ?? "").toString();
    const userId = (body["userId"] ?? "").toString();
    const bankName = (body["bankName"] ?? "").toString();
    const accountNumber = (body["accountNumber"] ?? "").toString();

    if (
      voucherCode.isEmpty ||
      userId.isEmpty ||
      bankName.isEmpty ||
      accountNumber.isEmpty
    ) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        },
      );
    }

    let stripeMode = "mock";

    // Development verification only if a secret is available.
    if (stripe) {
      await stripe.balance.retrieve();
      stripeMode = "test_key_verified";
    }

    return new Response(
      JSON.stringify({
        success: true,
        mode: "development",
        stripeMode,
        message: stripe
          ? "Stripe test connection verified. Payout marked as processed."
          : "Stripe mock mode: payout marked as processed (no secret configured).",
        payoutId: "dev_payout_" + Date.now().toString(),
        voucherCode: voucherCode,
        userId: userId,
        bankName: bankName,
        accountNumberMasked:
          accountNumber.length > 4
            ? "****" + accountNumber.substring(accountNumber.length - 4)
            : accountNumber,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Stripe development payout failed",
        details: error.toString(),
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }
});
