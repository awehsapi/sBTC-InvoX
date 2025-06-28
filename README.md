
# sBTC-InvoX - Invoice Factoring Smart Contract

This smart contract allows businesses to tokenize invoices as NFTs (non-fungible tokens), sell them to investors at a discount, and enable the new token holder to claim the full invoice amount once the due date is reached. The contract facilitates invoice creation, sale, transfer, and claim settlement in a decentralized and trustless way on the Stacks blockchain.

---

## 🔧 Features

* ✅ Mint NFTs representing invoices
* ✅ Apply and manage custom discount rates
* ✅ Sell invoices to investors in exchange for STX
* ✅ Enable investors to claim full payment after the due date
* ✅ Transfer invoice ownership
* ✅ Track monthly and per-user statistics

---

## 📚 Table of Contents

* [How It Works](#how-it-works)
* [Smart Contract Overview](#smart-contract-overview)
* [Public Functions](#public-functions)
* [Read-Only Functions](#read-only-functions)
* [Data Structures](#data-structures)
* [Error Codes](#error-codes)
* [Deployment](#deployment)
* [License](#license)

---

## 🔄 How It Works

1. **Minting Invoices**: Businesses mint invoices with a face value, due date, and a discount rate.
2. **Selling Invoices**: Buyers can purchase these invoices at a discounted price before the due date.
3. **Ownership Transfer**: The token representing the invoice is transferred to the buyer.
4. **Claiming Payments**: After the due date, the buyer can claim the full invoice amount from the original issuer.

---

## 🧠 Smart Contract Overview

This contract uses:

* **NFT-like tokenization**: Each invoice is represented as a unique token.
* **STX transfers**: To handle buying and payment claiming.
* **Statistics tracking**: To provide insights into platform usage and performance.

---

## 🔓 Public Functions

### `mint-invoice (amount uint, due-date uint, discount-rate uint)`

Mint a new invoice token.

* `amount`: Face value of the invoice.
* `due-date`: Block height when payment is due.
* `discount-rate`: Basis points (e.g., 500 = 5.00%).

📤 Emits:

```clojure
{
  type: "invoice-minted",
  token-id: <uint>,
  owner: <principal>,
  amount: <uint>
}
```

---

### `purchase-invoice (token-id uint)`

Purchase an invoice NFT at its discounted value.

📤 Emits:

```clojure
{
  type: "invoice-purchased",
  token-id: <uint>,
  buyer: <principal>,
  amount: <uint>
}
```

---

### `transfer (token-id uint, sender principal, recipient principal)`

Manually transfer an invoice to another address.

📤 Emits:

```clojure
{
  type: "invoice-transferred",
  token-id: <uint>,
  from: <principal>,
  to: <principal>
}
```

---

### `claim-payment (token-id uint)`

After due date, the current owner can claim the full invoice amount from the original issuer.

📤 Emits:

```clojure
{
  type: "invoice-claimed",
  token-id: <uint>,
  claimer: <principal>,
  amount: <uint>
}
```

---

## 📖 Read-Only Functions

### `get-owner (token-id uint)`

Returns the owner of a specific invoice token.

### `get-invoice (token-id uint)`

Returns invoice details for a token.

### `get-last-token-id`

Returns the last minted token ID.

### `calculate-discounted-amount (amount uint, discount-rate uint)`

Returns the amount the buyer will pay based on the discount.

### `get-monthly-stats (year uint, month uint)`

Returns volume, invoice count, and other stats for the given month.

### `get-user-stats (user principal)`

Returns a user's statistics (issued, purchased, claimed, etc.).

---

## 🗂️ Data Structures

### `invoices (map)`

Stores invoice data by token ID:

```clojure
{
  amount: uint,
  due-date: uint,
  discount-rate: uint,
  original-owner: principal,
  is-claimed: bool
}
```

### `token-owners (map)`

Tracks ownership of each token.

### `invoice-stats (map)`

Tracks monthly statistics:

```clojure
{
  total-volume: uint,
  invoice-count: uint,
  average-discount: uint,
  total-claimed: uint
}
```

### `user-stats (map)`

Per-user statistics:

```clojure
{
  total-issued: uint,
  total-purchased: uint,
  active-invoices: uint,
  total-claimed: uint
}
```

---

## ⚠️ Error Codes

| Code | Description                   |
| ---- | ----------------------------- |
| 100  | Owner-only access             |
| 101  | Not token owner               |
| 102  | Invalid discount              |
| 103  | Invalid amount                |
| 104  | Invoice expired               |
| 105  | Invoice already claimed       |
| 106  | Token owner exists            |
| 107  | Invoice already exists        |
| 108  | Transfer failed               |
| 109  | Failed to update claim status |

---

## 🚀 Deployment

To deploy this Clarity contract:

1. Install [Clarinet](https://docs.stacks.co/docs/clarity/clarinet).
2. Save the contract as `contracts/invoice-factoring.clar`.
3. Run:

```bash
clarinet check
clarinet test
clarinet deploy
```

---

## ⚖️ License

MIT License. You are free to use, modify, and distribute this smart contract as long as proper attribution is given.

---
