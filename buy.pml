mtype = {M1..M32}; // This is a simplification.  Some messages contain
                   // data, amounts, money... We will get to that later.
chan BtoJ = [1] of {byte}; // Buyer to Judge message channel
chan JtoB = [1] of {byte}; // Judge to Buyer
chan StoJ = [1] of {byte}; // Seller to Judge
chan JtoS = [1] of {byte}; // Judge to Seller

init { Buyer(); Seller(); Judge(); }  // Start our modeling with just one of each.

proctype Buyer() {
  // First, a human shopper discovers product, seller, terms;
  // downloads Buyer app, selects product, seller, terms within Buyer app. Then...
  // The person might renegotiate terms here, but let's assume those are by now fixed.

  // So now the buyer likes the description and terms and trusts the protocol and
  // now sends the details to ask a judge to carry out the BUY protocol with seller.
  BtoJ!BUY,seller,terms; // Buyer: M2 I OFFERtoBUY product according to DESC
                     // at PRICE plus TAX plus COSTTOSHIP at SCHEDULE subject to JUDGE and
                     // PROTOCOL

  JtoB?terms; // Judge: M4 Seller, Buyer do you agree to terms;
  // Objection, this is pro forma!  terms are already agreed!
  // But the judge needs the evidence, and Buyer app must affirm that the
  // humans agreed explicitly and so as to become conclusive evidence of
  // their participation in the contract

  if
  :: BtoJ!rejectTerms; JtoS?CancelOrderNotAccepted; quit;
  // Buyer: M5 rejects terms (then Judge says Cancel order to S & B)

  :: BtoJ!AcceptTerms; // Buyer: M7 I accept terms
  fi

  JtoB?DemandAmount; assert(AmountCorrect); // Buyer: M9 sends AMOUNT
  BtoJ!SendingAmount // Buyer: M12 sends AMOUNT
  // Wait here until shipment arrives (outside the protocol).
  BtoJ!RecievedShipment;                  // Buyer: M15 Judge: Received shipment
  BtoJ!ShipmentSatisfactoryReleasePayment
    // Buyer: M16 Judge: Purchase meets expectations.  Release payment.
}

proctype Seller() {
  // Seller publishes product/service terms & protocol, awaits buyer engagement.
  JtoS?terms; // Judge: M4 Seller, do you agree to terms
  if
  :: StoJ!rejectTerms; JtoB?CancelOrderNotAccepted; quit;
     // Seller: M5 I reject terms (then Judge says Cancel order to S & B)

  :: StoJ!AcceptTerms;// Seller: M6 I accept terms
  fi

  StoJ!FOBShipReceipt; // Seller: M14 Shipment receipt.

  JtoS?BuyerHappy;
  JtoS?SendingAmount; // Judge: M17 Seller: Buyer happy, sends AMOUNT.
}

proctype Judge() { // Judge is intermediary, escrow holder and adjudicator.
  // Startup initialization.  Know terms, seller, buyer.
  // Judge:  M3 I accept to carry out the judge role with S and B under PROTOCOL

  // Terms includes:
  //    product/svc, price, ship method & cost, tax, schedule,
  //    judge, protocol, parties, return process, adjudication process

  both
  :: JtoB!terms; // Judge: M4 Seller, Buyer do you agree to terms
  :: JtoS!terms; // Judge: M4 Seller, Buyer do you agree to terms
  htob

  both
  :: BtoJ?AcceptTerms; // Buyer: M7 I accept terms
  :: StoJ?AcceptTerms;// Seller: M6 I accept terms
  htob

  JtoB!DemandAmount;  // Judge: M8 Buyer: send TOTAL PRICE

  // Judge: M10 partial payments not accepted, you owe AMOUNT, please send it.
  BtoJ?RecvAmount;
  while
  :: !AmountCorrect -> JtoB!DemandDueAmount;
  :: else           -> continue;
  elihw

  if // Judge: M11 Timeout, returns AMOUNT to Buyer, cancels order with Seller
  :: timeout -> JtoS!CancelOrderTimedOut; JtoB!CancelOrderTimedOut; JtoB!ReturningAmount
  :: else ->
         BtoJ?SendingAmount;  // Buyer: M12 sends AMOUNT
         JtoS!ObligationInitiated; // Judge: M13 Seller: Buyer has deposited
                            // full amount into escrow.  You are obligated
                            // to deliver per SHIPMETHOD on SCHEDULE.
  fi

  BtoJ?RecievedShipment;                  // Buyer: M15 Judge: Received shipment

  // Buyer: M16 Judge: Purchase meets expectations.  Release payment.
  if
  :: BtoJ?ShipmentSatisfactoryReleasePayment ->
     JtoS!BuyerHappy;
     JtoS!SendingAmount; // Judge: M17 Seller: Buyer happy, sends AMOUNT.
  fi
}
</PRE>

