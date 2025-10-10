(define-constant ERR_PART_NOT_FOUND (err u110))
(define-constant ERR_VEHICLE_NOT_FOUND (err u101))
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_WARRANTY (err u111))
(define-constant ERR_ALREADY_CLAIMED (err u112))

(define-map WarrantyParts
  { part-id: uint }
  {
    vehicle-id: (string-ascii 20),
    part-name: (string-ascii 60),
    manufacturer: (string-ascii 40),
    installation-block: uint,
    installation-mileage: uint,
    warranty-duration-blocks: uint,
    warranty-duration-miles: uint,
    part-cost: uint,
    installed-by: (string-ascii 50),
    serial-number: (string-ascii 30)
  }
)

(define-map WarrantyClaims
  { claim-id: uint }
  {
    part-id: uint,
    claim-date: uint,
    claim-amount: uint,
    failure-description: (string-ascii 150),
    approved: bool,
    processed: bool
  }
)

(define-data-var part-counter uint u0)
(define-data-var claim-counter uint u0)
(define-data-var target-vehicle (string-ascii 20) "")

(define-public (register-warranty-part
  (vehicle-id (string-ascii 20))
  (part-name (string-ascii 60))
  (manufacturer (string-ascii 40))
  (installation-mileage uint)
  (warranty-blocks uint)
  (warranty-miles uint)
  (part-cost uint)
  (installed-by (string-ascii 50))
  (serial-number (string-ascii 30)))
  (let (
    (vehicle (unwrap! (contract-call? .Clarity-Based-Fleet-Maintenance-Ledger get-vehicle vehicle-id) ERR_VEHICLE_NOT_FOUND))
    (new-part-id (+ (var-get part-counter) u1))
  )
    (asserts! (> warranty-blocks u0) ERR_INVALID_WARRANTY)
    (asserts! (> part-cost u0) ERR_INVALID_WARRANTY)
    (map-set WarrantyParts
      { part-id: new-part-id }
      {
        vehicle-id: vehicle-id,
        part-name: part-name,
        manufacturer: manufacturer,
        installation-block: stacks-block-height,
        installation-mileage: installation-mileage,
        warranty-duration-blocks: warranty-blocks,
        warranty-duration-miles: warranty-miles,
        part-cost: part-cost,
        installed-by: installed-by,
        serial-number: serial-number
      }
    )
    (var-set part-counter new-part-id)
    (ok new-part-id)
  )
)

(define-read-only (check-warranty-status (part-id uint))
  (match (map-get? WarrantyParts { part-id: part-id })
    part
    (let (
      (blocks-elapsed (- stacks-block-height (get installation-block part)))
      (blocks-remaining (if (> (get warranty-duration-blocks part) blocks-elapsed) 
                          (- (get warranty-duration-blocks part) blocks-elapsed) u0))
      (warranty-active (< blocks-elapsed (get warranty-duration-blocks part)))
    )
      (some {
        warranty-active: warranty-active,
        blocks-remaining: blocks-remaining,
        expiration-block: (+ (get installation-block part) (get warranty-duration-blocks part)),
        miles-covered: (get warranty-duration-miles part)
      })
    )
    none
  )
)

(define-public (file-warranty-claim
  (part-id uint)
  (failure-description (string-ascii 150))
  (claim-amount uint))
  (let (
    (part (unwrap! (map-get? WarrantyParts { part-id: part-id }) ERR_PART_NOT_FOUND))
    (warranty-status (unwrap! (check-warranty-status part-id) ERR_PART_NOT_FOUND))
    (new-claim-id (+ (var-get claim-counter) u1))
  )
    (asserts! (get warranty-active warranty-status) ERR_INVALID_WARRANTY)
    (asserts! (<= claim-amount (get part-cost part)) ERR_INVALID_WARRANTY)
    (map-set WarrantyClaims
      { claim-id: new-claim-id }
      {
        part-id: part-id,
        claim-date: stacks-block-height,
        claim-amount: claim-amount,
        failure-description: failure-description,
        approved: false,
        processed: false
      }
    )
    (var-set claim-counter new-claim-id)
    (ok new-claim-id)
  )
)

(define-public (get-vehicle-warranty-parts (vehicle-id (string-ascii 20)))
  (ok (filter-warranty-parts vehicle-id (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)))
)

(define-private (filter-warranty-parts (vid (string-ascii 20)) (part-ids (list 20 uint)))
  (begin
    (var-set target-vehicle vid)
    (fold check-part-vehicle part-ids (list))
  )
)

(define-private (check-part-vehicle (part-id uint) (parts (list 20 uint)))
  (match (map-get? WarrantyParts { part-id: part-id })
    part 
    (if (is-eq (get vehicle-id part) (var-get target-vehicle))
      (unwrap-panic (as-max-len? (append parts part-id) u20))
      parts)
    parts
  )
)

(define-read-only (get-warranty-part (part-id uint))
  (map-get? WarrantyParts { part-id: part-id })
)

(define-read-only (get-warranty-claim (claim-id uint))
  (map-get? WarrantyClaims { claim-id: claim-id })
)

(define-read-only (calculate-warranty-savings (vehicle-id (string-ascii 20)))
  (ok (fold sum-approved-claims (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) u0))
)

(define-private (sum-approved-claims (claim-id uint) (total uint))
  (match (map-get? WarrantyClaims { claim-id: claim-id })
    claim (if (get approved claim) (+ total (get claim-amount claim)) total)
    total
  )
)
