// @ts-nocheck
import Stripe from "https://esm.sh/stripe@14.25.0?target=deno";
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const fallbackStripeSecretKey =
  "sk_test_51SeFjZJ0NvBCcCJetZZw02Tf4Hjz1ZUMyT9S1hMPiENlEBR5ZBT7F3b9l6ylskvJ2lED5qpp9nPVxXVeqOwwhZvV00IxMEImWN";
const stripeSecretKey =
  Deno.env.get("STRIPE_SECRET_KEY") ?? fallbackStripeSecretKey;
const fallbackSuccessUrl = "https://example.com/stripe/success";
const fallbackCancelUrl = "https://example.com/stripe/cancel";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const stripe = new Stripe(stripeSecretKey, {
    apiVersion: "2024-06-20",
  });

  try {
    const body = await req.json();
    const itemId = (body["itemId"] ?? "").toString().trim();
    const userId = (body["userId"] ?? "").toString().trim();
    const merchantName = (body["merchantName"] ?? "RecycleGo")
      .toString()
      .trim();
    const itemName = (body["itemName"] ?? "Recyclable Item").toString().trim();
    const currency = (body["currency"] ?? "myr")
      .toString()
      .trim()
      .toLowerCase();
    const amountInCents = Number(body["amountInCents"] ?? 0);
    const requestedPaymentMethod = (body["paymentMethodType"] ?? "fpx")
      .toString()
      .trim()
      .toLowerCase();
    const paymentMethodType =
      requestedPaymentMethod === "card" ? "card" : "fpx";

    if (itemId.length === 0 || userId.length === 0) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (!Number.isFinite(amountInCents) || amountInCents <= 0) {
      return new Response(JSON.stringify({ error: "Invalid amountInCents" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (paymentMethodType === "fpx" && currency !== "myr") {
      return new Response(
        JSON.stringify({ error: "FPX checkout requires MYR currency" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const successUrl = (
      body["successUrl"] ??
      Deno.env.get("STRIPE_SUCCESS_URL") ??
      fallbackSuccessUrl
    ).toString();

    const cancelUrl = (
      body["cancelUrl"] ??
      Deno.env.get("STRIPE_CANCEL_URL") ??
      fallbackCancelUrl
    ).toString();

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      payment_method_types: [paymentMethodType],
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency,
            unit_amount: Math.trunc(amountInCents),
            product_data: {
              name: itemName,
              description: `Item ID: ${itemId} | Merchant: ${merchantName}`,
            },
          },
        },
      ],
      metadata: {
        itemId,
        userId,
        merchantName,
      },
      success_url: successUrl,
      cancel_url: cancelUrl,
    });

    if (!session.url) {
      throw new Error("Stripe did not return checkout URL");
    }

    return new Response(
      JSON.stringify({
        success: true,
        checkoutUrl: session.url,
        sessionId: session.id,
        paymentMethodType,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Failed to create Stripe checkout session",
        details: error.toString(),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
