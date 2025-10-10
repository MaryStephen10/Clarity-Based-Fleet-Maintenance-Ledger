(define-constant ERR_INVALID_FUEL_AMOUNT (err u106))
(define-constant ERR_INVALID_FUEL_PRICE (err u107))
(define-constant ERR_VEHICLE_NOT_FOUND (err u101))
(define-constant ERR_INVALID_MILEAGE (err u102))

(define-map FuelRecords
  { fuel-id: uint }
  {
    vehicle-id: (string-ascii 20),
    gallons-purchased: uint,
    cost-per-gallon: uint,
    total-cost: uint,
    odometer-reading: uint,
    station-location: (string-ascii 50),
    purchase-block: uint
  }
)

(define-data-var fuel-counter uint u0)

(define-public (log-fuel-purchase
  (vehicle-id (string-ascii 20))
  (gallons-purchased uint)
  (cost-per-gallon uint)
  (odometer-reading uint)
  (station-location (string-ascii 50)))
  (let (
    (vehicle (unwrap! (contract-call? .Clarity-Based-Fleet-Maintenance-Ledger get-vehicle vehicle-id) ERR_VEHICLE_NOT_FOUND))
    (new-fuel-id (+ (var-get fuel-counter) u1))
    (total-cost (* gallons-purchased cost-per-gallon))
  )
    (asserts! (> gallons-purchased u0) ERR_INVALID_FUEL_AMOUNT)
    (asserts! (> cost-per-gallon u0) ERR_INVALID_FUEL_PRICE)
    (asserts! (>= odometer-reading (get current-mileage vehicle)) ERR_INVALID_MILEAGE)
    (map-set FuelRecords
      { fuel-id: new-fuel-id }
      {
        vehicle-id: vehicle-id,
        gallons-purchased: gallons-purchased,
        cost-per-gallon: cost-per-gallon,
        total-cost: total-cost,
        odometer-reading: odometer-reading,
        station-location: station-location,
        purchase-block: stacks-block-height
      }
    )
    (var-set fuel-counter new-fuel-id)
    (ok new-fuel-id)
  )
)

(define-read-only (get-fuel-record (fuel-id uint))
  (map-get? FuelRecords { fuel-id: fuel-id })
)

(define-read-only (calculate-mpg (current-fuel-id uint) (previous-fuel-id uint))
  (match (map-get? FuelRecords { fuel-id: current-fuel-id })
    current-record
    (match (map-get? FuelRecords { fuel-id: previous-fuel-id })
      previous-record
      (let (
        (miles-driven (- (get odometer-reading current-record) (get odometer-reading previous-record)))
        (gallons-used (get gallons-purchased current-record))
      )
        (if (and (> gallons-used u0) (> miles-driven u0))
          (some (/ miles-driven gallons-used))
          none
        )
      )
      none
    )
    none
  )
)

(define-read-only (get-fuel-efficiency-score (vehicle-id (string-ascii 20)))
  (let ((total-cost (get-total-fuel-cost vehicle-id)))
    (if (> total-cost u0)
      (some (/ u100000 total-cost))
      none
    )
  )
)

(define-read-only (get-total-fuel-cost (vehicle-id (string-ascii 20)))
  (fold sum-fuel-costs (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) u0)
)

(define-private (sum-fuel-costs (fuel-id uint) (total uint))
  (match (map-get? FuelRecords { fuel-id: fuel-id })
    record total
    total
  )
)
