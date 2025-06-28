
;; sBTC-InvoX
;; Invoice Factoring Smart Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-invalid-discount (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-invoice-expired (err u104))
(define-constant err-already-claimed (err u105))

;; Data Variables
(define-data-var last-token-id uint u0)

;; Define invoice token structure
(define-map invoices
    uint
    {
        amount: uint,
        due-date: uint,
        discount-rate: uint,
        original-owner: principal,
        is-claimed: bool
    }
)

;; Define token ownership
(define-map token-owners
    uint
    principal
)

;; SFTs for tracking ownership
;; (impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Read-only functions
(define-read-only (get-owner (token-id uint))
    (ok (map-get? token-owners token-id))
)

(define-read-only (get-invoice (token-id uint))
    (ok (map-get? invoices token-id))
)

(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

;; Calculate discounted amount
(define-read-only (calculate-discounted-amount (amount uint) (discount-rate uint))
    (let
        (
            (discount (* amount discount-rate))
            (discounted-amount (- amount (/ discount u10000)))
        )
        (ok discounted-amount)
    )
)


;; Public functions

(define-constant err-token-owner-exists (err u106))
(define-constant err-invoice-exists (err u107))

;;; Mint new invoice token
(define-public (mint-invoice (amount uint) (due-date uint) (discount-rate uint))
    (let
        (
            (token-id (+ (var-get last-token-id) u1))
        )
        ;; Validate inputs
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (<= discount-rate u10000) err-invalid-discount)
        (asserts! (> due-date block-height) err-invalid-amount)

        ;; Create invoice entry
        (if (map-insert invoices 
            token-id
            {
                amount: amount,
                due-date: due-date,
                discount-rate: discount-rate,
                original-owner: tx-sender,
                is-claimed: false
            })
            ;; If invoice insertion successful
            (if (map-insert token-owners token-id tx-sender)
                ;; If both insertions successful
                (begin
                    (var-set last-token-id token-id)
                    (print {
                        type: "invoice-minted",
                        token-id: token-id,
                        owner: tx-sender,
                        amount: amount
                    })
                    (ok token-id))
                ;; If token owner insertion failed
                (err u106))
            ;; If invoice insertion failed
            (err u107))
    )
)

(define-constant err-transfer-failed (err u108))
;; Transfer invoice token
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (let
        (
            (invoice (unwrap! (map-get? invoices token-id) err-invalid-amount))
            (current-owner (unwrap! (map-get? token-owners token-id) err-not-token-owner))
        )
        ;; Verify ownership and status
        (asserts! (is-eq tx-sender sender) err-not-token-owner)
        (asserts! (is-eq current-owner sender) err-not-token-owner)
        (asserts! (not (get is-claimed invoice)) err-already-claimed)

        ;; Update token ownership
        (if (map-set token-owners token-id recipient)
            (begin
                (print {
                    type: "invoice-transferred",
                    token-id: token-id,
                    from: sender,
                    to: recipient
                })
                (ok true))
            (err u108)) ;; Failed to transfer ownership
    )
)


;; Purchase invoice at discount
(define-public (purchase-invoice (token-id uint))
    (let
        (
            (invoice (unwrap! (map-get? invoices token-id) err-invalid-amount))
            (current-owner (unwrap! (map-get? token-owners token-id) err-not-token-owner))
            (discounted-amount (unwrap! (calculate-discounted-amount (get amount invoice) (get discount-rate invoice)) err-invalid-amount))
        )
        (asserts! (not (get is-claimed invoice)) err-already-claimed)
        (asserts! (< block-height (get due-date invoice)) err-invoice-expired)

        ;; Transfer STX from buyer to current owner
        (try! (stx-transfer? discounted-amount tx-sender current-owner))

        ;; Transfer token ownership
        (try! (transfer token-id current-owner tx-sender))

        (print {
            type: "invoice-purchased",
            token-id: token-id,
            buyer: tx-sender,
            amount: discounted-amount
        })
        (ok true)
    )
)

(define-constant err-claim-update-failed (err u109))
;; Claim invoice payment
(define-public (claim-payment (token-id uint))
    (let
        (
            (invoice (unwrap! (map-get? invoices token-id) err-invalid-amount))
            (current-owner (unwrap! (map-get? token-owners token-id) err-not-token-owner))
        )
        ;; Verify claiming conditions
        (asserts! (is-eq current-owner tx-sender) err-not-token-owner)
        (asserts! (>= block-height (get due-date invoice)) err-invoice-expired)
        (asserts! (not (get is-claimed invoice)) err-already-claimed)

        ;; Transfer full amount from original owner to current token owner
        (match (stx-transfer? (get amount invoice) (get original-owner invoice) current-owner)
            success-response ;; If transfer successful, update invoice status
            (if (map-set invoices token-id (merge invoice { is-claimed: true }))
                (begin
                    (print {
                        type: "invoice-claimed",
                        token-id: token-id,
                        claimer: tx-sender,
                        amount: (get amount invoice)
                    })
                    (ok true))
                (err u109)) ;; Failed to mark invoice as claimed
            error-response ;; Propagate STX transfer error
            (err error-response)) ;; Just pass through the error
    )
)


;; Additional data structures
(define-map invoice-stats
    { year: uint, month: uint }
    {
        total-volume: uint,
        invoice-count: uint,
        average-discount: uint,
        total-claimed: uint
    }
)

(define-map user-stats
    principal
    {
        total-issued: uint,
        total-purchased: uint,
        active-invoices: uint,
        total-claimed: uint
    }
)


;; Read-only functions for stats
(define-read-only (get-monthly-stats (year uint) (month uint))
    (ok (default-to
        {
            total-volume: u0,
            invoice-count: u0,
            average-discount: u0,
            total-claimed: u0
        }
        (map-get? invoice-stats { year: year, month: month })))
)

(define-read-only (get-user-stats (user principal))
    (ok (default-to
        {
            total-issued: u0,
            total-purchased: u0,
            active-invoices: u0,
            total-claimed: u0
        }
        (map-get? user-stats user)))
)