// @ts-nocheck
import Stripe from "https://esm.sh/stripe@14.25.0?target=deno";
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const fallbackStripeSecretKey =
  "sk_test_51SeFjZJ0NvBCcCJetZZw02Tf4Hjz1ZUMyT9S1hMPiENlEBR5ZBT7F3b9l6ylskvJ2lED5qpp9nPVxXVeqOwwhZvV00IxMEImWN";
const stripeSecretKey =
  Deno.env.get("STRIPE_SECRET_KEY") ?? fallbackStripeSecretKey;

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
    const sessionId = (body["sessionId"] ?? "").toString().trim();

    if (sessionId.length === 0) {
      return new Response(JSON.stringify({ error: "sessionId is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Retrieve session from Stripe
    const session = await stripe.checkout.sessions.retrieve(sessionId);

    if (!session) {
      return new Response(JSON.stringify({ error: "Session not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Log session details for debugging
    console.log("Session retrieved:", {
      id: session.id,
      payment_status: session.payment_status,
      payment_intent: session.payment_intent,
      customer_email: session.customer_email,
      custom_fields: session.custom_fields,
    });

    // Determine payment status
    // For FPX: check payment_intent.status since FPX is asynchronous
    // For cards: check session.payment_status
    let paymentStatus = "pending";

    if (session.payment_intent) {
      // Retrieve payment intent for detailed status
      const paymentIntent = await stripe.paymentIntents.retrieve(
        session.payment_intent as string,
      );

      console.log("Payment Intent status:", paymentIntent.status);

      if (paymentIntent.status === "succeeded") {
        paymentStatus = "success";
      } else if (
        paymentIntent.status === "requires_action" ||
        paymentIntent.status === "processing"
      ) {
        paymentStatus = "pending"; // Still processing (FPX)
      } else if (
        paymentIntent.status === "requires_payment_method" ||
        paymentIntent.status === "canceled"
      ) {
        paymentStatus = "failed";
      }
    } else if (session.payment_status === "paid") {
      paymentStatus = "success";
    } else if (session.payment_status === "unpaid") {
      paymentStatus = "pending"; // Changed from "failed" - user might still be paying
    }

    // Extract bank account number from custom fields
    let bankAccount = null;
    if (session.custom_fields && session.custom_fields.length > 0) {
      const bankAccountField = session.custom_fields.find(
        (field: any) => field.key === "bank_account",
      );
      if (bankAccountField && bankAccountField.text) {
        bankAccount = bankAccountField.text.value;
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        sessionId: session.id,
        paymentStatus,
        paymentIntent: session.payment_intent,
        customerEmail: session.customer_email,
        bankAccount: bankAccount,
        metadata: session.metadata || {},
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Failed to verify Stripe session",
        details: error.toString(),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
