;; Provider Verification Contract
;; Validates and stores healthcare provider information

;; Data Maps
(define-map providers
  { provider-id: principal }
  {
    name: (string-utf8 100),
    specialty: (string-utf8 100),
    license-number: (string-utf8 50),
    is-verified: bool
  }
)

;; Error Codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_REGISTERED u2)
(define-constant ERR_NOT_FOUND u3)

;; Contract Owner
(define-data-var contract-owner principal tx-sender)

;; Read-Only Functions
(define-read-only (get-provider (provider-id principal))
  (map-get? providers { provider-id: provider-id })
)

(define-read-only (is-provider-verified (provider-id principal))
  (default-to false (get is-verified (get-provider provider-id)))
)

;; Public Functions
(define-public (register-provider (name (string-utf8 100)) (specialty (string-utf8 100)) (license-number (string-utf8 50)))
  (let ((provider-id tx-sender))
    (asserts! (is-none (get-provider provider-id)) (err ERR_ALREADY_REGISTERED))

    (map-set providers
      { provider-id: provider-id }
      {
        name: name,
        specialty: specialty,
        license-number: license-number,
        is-verified: false
      }
    )
    (ok true)
  )
)

(define-public (verify-provider (provider-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (asserts! (is-some (get-provider provider-id)) (err ERR_NOT_FOUND))

    (map-set providers
      { provider-id: provider-id }
      (merge (unwrap-panic (get-provider provider-id)) { is-verified: true })
    )
    (ok true)
  )
)

(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
