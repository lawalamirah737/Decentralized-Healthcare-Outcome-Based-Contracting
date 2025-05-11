;; Treatment Protocol Contract
;; Records agreed medical interventions and protocols

;; Data Maps
(define-map protocols
  { protocol-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 255),
    created-by: principal,
    created-at: uint,
    cohort-id: uint
  }
)

(define-map protocol-steps
  { protocol-id: uint, step-id: uint }
  {
    description: (string-utf8 255),
    expected-outcome: (string-utf8 255),
    duration-days: uint
  }
)

;; Variables
(define-data-var protocol-counter uint u0)
(define-data-var contract-owner principal tx-sender)

;; Error Codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_NOT_FOUND u2)
(define-constant ERR_INVALID_INPUT u3)

;; Read-Only Functions
(define-read-only (get-protocol (protocol-id uint))
  (map-get? protocols { protocol-id: protocol-id })
)

(define-read-only (get-protocol-step (protocol-id uint) (step-id uint))
  (map-get? protocol-steps { protocol-id: protocol-id, step-id: step-id })
)

(define-read-only (get-protocol-count)
  (var-get protocol-counter)
)

;; Public Functions
(define-public (create-protocol (name (string-utf8 100)) (description (string-utf8 255)) (cohort-id uint))
  (let ((new-id (+ (var-get protocol-counter) u1)))
    (var-set protocol-counter new-id)
    (map-set protocols
      { protocol-id: new-id }
      {
        name: name,
        description: description,
        created-by: tx-sender,
        created-at: block-height,
        cohort-id: cohort-id
      }
    )
    (ok new-id)
  )
)

(define-public (add-protocol-step
  (protocol-id uint)
  (step-id uint)
  (description (string-utf8 255))
  (expected-outcome (string-utf8 255))
  (duration-days uint))
  (begin
    (asserts! (is-some (get-protocol protocol-id)) (err ERR_NOT_FOUND))
    (asserts! (or
                (is-eq tx-sender (var-get contract-owner))
                (is-eq tx-sender (get created-by (unwrap-panic (get-protocol protocol-id))))
              )
              (err ERR_UNAUTHORIZED))

    (map-set protocol-steps
      { protocol-id: protocol-id, step-id: step-id }
      {
        description: description,
        expected-outcome: expected-outcome,
        duration-days: duration-days
      }
    )
    (ok true)
  )
)

(define-public (update-protocol-step
  (protocol-id uint)
  (step-id uint)
  (description (string-utf8 255))
  (expected-outcome (string-utf8 255))
  (duration-days uint))
  (begin
    (asserts! (is-some (get-protocol protocol-id)) (err ERR_NOT_FOUND))
    (asserts! (is-some (get-protocol-step protocol-id step-id)) (err ERR_NOT_FOUND))
    (asserts! (or
                (is-eq tx-sender (var-get contract-owner))
                (is-eq tx-sender (get created-by (unwrap-panic (get-protocol protocol-id))))
              )
              (err ERR_UNAUTHORIZED))

    (map-set protocol-steps
      { protocol-id: protocol-id, step-id: step-id }
      {
        description: description,
        expected-outcome: expected-outcome,
        duration-days: duration-days
      }
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
