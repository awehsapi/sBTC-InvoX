
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

