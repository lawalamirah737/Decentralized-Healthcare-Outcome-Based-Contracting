;; Patient Cohort Contract
;; Manages groups of patients for outcome measurement

;; Data Maps
(define-map cohorts
  { cohort-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 255),
    created-by: principal,
    created-at: uint
  }
)

(define-map cohort-patients
  { cohort-id: uint, patient-id: principal }
  { joined-at: uint }
)

;; Variables
(define-data-var cohort-counter uint u0)
(define-data-var contract-owner principal tx-sender)

;; Error Codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_NOT_FOUND u2)
(define-constant ERR_ALREADY_EXISTS u3)

;; Read-Only Functions
(define-read-only (get-cohort (cohort-id uint))
  (map-get? cohorts { cohort-id: cohort-id })
)

(define-read-only (is-patient-in-cohort (cohort-id uint) (patient-id principal))
  (is-some (map-get? cohort-patients { cohort-id: cohort-id, patient-id: patient-id }))
)

(define-read-only (get-cohort-count)
  (var-get cohort-counter)
)

;; Public Functions
(define-public (create-cohort (name (string-utf8 100)) (description (string-utf8 255)))
  (let ((new-id (+ (var-get cohort-counter) u1)))
    (var-set cohort-counter new-id)
    (map-set cohorts
      { cohort-id: new-id }
      {
        name: name,
        description: description,
        created-by: tx-sender,
        created-at: block-height
      }
    )
    (ok new-id)
  )
)

(define-public (add-patient-to-cohort (cohort-id uint) (patient-id principal))
  (begin
    (asserts! (is-some (get-cohort cohort-id)) (err ERR_NOT_FOUND))
    (asserts! (or
                (is-eq tx-sender (var-get contract-owner))
                (is-eq tx-sender (get created-by (unwrap-panic (get-cohort cohort-id))))
              )
              (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? cohort-patients { cohort-id: cohort-id, patient-id: patient-id })) (err ERR_ALREADY_EXISTS))

    (map-set cohort-patients
      { cohort-id: cohort-id, patient-id: patient-id }
      { joined-at: block-height }
    )
    (ok true)
  )
)

(define-public (remove-patient-from-cohort (cohort-id uint) (patient-id principal))
  (begin
    (asserts! (is-some (get-cohort cohort-id)) (err ERR_NOT_FOUND))
    (asserts! (or
                (is-eq tx-sender (var-get contract-owner))
                (is-eq tx-sender (get created-by (unwrap-panic (get-cohort cohort-id))))
              )
              (err ERR_UNAUTHORIZED))
    (asserts! (is-some (map-get? cohort-patients { cohort-id: cohort-id, patient-id: patient-id })) (err ERR_NOT_FOUND))

    (map-delete cohort-patients { cohort-id: cohort-id, patient-id: patient-id })
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
