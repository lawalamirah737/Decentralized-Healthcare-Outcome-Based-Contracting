;; Outcome Measurement Contract
;; Tracks health results and metrics

;; Data Maps
(define-map metrics
  { metric-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 255),
    created-by: principal,
    created-at: uint,
    protocol-id: uint,
    target-value: int,
    weight: uint
  }
)

(define-map patient-outcomes
  { patient-id: principal, metric-id: uint }
  {
    value: int,
    recorded-at: uint,
    recorded-by: principal
  }
)

;; Variables
(define-data-var metric-counter uint u0)
(define-data-var contract-owner principal tx-sender)

;; Error Codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_NOT_FOUND u2)
(define-constant ERR_INVALID_INPUT u3)

;; Read-Only Functions
(define-read-only (get-metric (metric-id uint))
  (map-get? metrics { metric-id: metric-id })
)

(define-read-only (get-patient-outcome (patient-id principal) (metric-id uint))
  (map-get? patient-outcomes { patient-id: patient-id, metric-id: metric-id })
)

(define-read-only (get-metric-count)
  (var-get metric-counter)
)

;; Public Functions
(define-public (create-metric
  (name (string-utf8 100))
  (description (string-utf8 255))
  (protocol-id uint)
  (target-value int)
  (weight uint))
  (let ((new-id (+ (var-get metric-counter) u1)))
    (var-set metric-counter new-id)
    (map-set metrics
      { metric-id: new-id }
      {
        name: name,
        description: description,
        created-by: tx-sender,
        created-at: block-height,
        protocol-id: protocol-id,
        target-value: target-value,
        weight: weight
      }
    )
    (ok new-id)
  )
)

(define-public (record-outcome (patient-id principal) (metric-id uint) (value int))
  (begin
    (asserts! (is-some (get-metric metric-id)) (err ERR_NOT_FOUND))

    (map-set patient-outcomes
      { patient-id: patient-id, metric-id: metric-id }
      {
        value: value,
        recorded-at: block-height,
        recorded-by: tx-sender
      }
    )
    (ok true)
  )
)

(define-public (update-metric
  (metric-id uint)
  (name (string-utf8 100))
  (description (string-utf8 255))
  (target-value int)
  (weight uint))
  (begin
    (asserts! (is-some (get-metric metric-id)) (err ERR_NOT_FOUND))
    (asserts! (or
                (is-eq tx-sender (var-get contract-owner))
                (is-eq tx-sender (get created-by (unwrap-panic (get-metric metric-id))))
              )
              (err ERR_UNAUTHORIZED))

    (let ((existing-metric (unwrap-panic (get-metric metric-id))))
      (map-set metrics
        { metric-id: metric-id }
        (merge existing-metric {
          name: name,
          description: description,
          target-value: target-value,
          weight: weight
        })
      )
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
