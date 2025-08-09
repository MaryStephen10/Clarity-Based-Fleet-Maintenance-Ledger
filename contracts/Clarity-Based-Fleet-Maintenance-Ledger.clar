(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_VEHICLE_NOT_FOUND (err u101))
(define-constant ERR_INVALID_MILEAGE (err u102))
(define-constant ERR_INVALID_COST (err u103))
(define-constant ERR_VEHICLE_EXISTS (err u104))

(define-constant ERR_ALERT_NOT_FOUND (err u105))
(define-constant CRITICAL_THRESHOLD u500)
(define-constant WARNING_THRESHOLD u1000)

(define-map Vehicles
  { vehicle-id: (string-ascii 20) }
  {
    owner: principal,
    make: (string-ascii 30),
    model: (string-ascii 30),
    year: uint,
    vin: (string-ascii 17),
    current-mileage: uint,
    registration-block: uint,
    active: bool
  }
)

(define-map MaintenanceRecords
  { record-id: uint }
  {
    vehicle-id: (string-ascii 20),
    maintenance-type: (string-ascii 50),
    description: (string-ascii 200),
    cost: uint,
    mileage-at-service: uint,
    service-date: uint,
    technician: (string-ascii 50),
    next-service-due: uint,
    parts-replaced: (string-ascii 100)
  }
)

(define-map FleetManagers
  { manager: principal }
  { authorized: bool, fleet-name: (string-ascii 50) }
)

(define-data-var record-counter uint u0)

(define-read-only (get-vehicle (vehicle-id (string-ascii 20)))
  (map-get? Vehicles { vehicle-id: vehicle-id })
)

(define-read-only (get-maintenance-record (record-id uint))
  (map-get? MaintenanceRecords { record-id: record-id })
)

(define-read-only (is-fleet-manager (manager principal))
  (default-to false (get authorized (map-get? FleetManagers { manager: manager })))
)

(define-read-only (get-vehicle-maintenance-count (vehicle-id (string-ascii 20)))
  (fold count-maintenance-records (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20) u0)
)

(define-private (count-maintenance-records (record-id uint) (count uint))
  (match (map-get? MaintenanceRecords { record-id: record-id })
    record (if (is-eq (get vehicle-id record) "temp") (+ count u1) count)
    count
  )
)

(define-public (register-fleet-manager (manager principal) (fleet-name (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (ok (map-set FleetManagers
      { manager: manager }
      { authorized: true, fleet-name: fleet-name }
    ))
  )
)

(define-public (register-vehicle 
  (vehicle-id (string-ascii 20))
  (make (string-ascii 30))
  (model (string-ascii 30))
  (year uint)
  (vin (string-ascii 17))
  (initial-mileage uint))
  (begin
    (asserts! (is-fleet-manager tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (map-get? Vehicles { vehicle-id: vehicle-id })) ERR_VEHICLE_EXISTS)
    (ok (map-set Vehicles
      { vehicle-id: vehicle-id }
      {
        owner: tx-sender,
        make: make,
        model: model,
        year: year,
        vin: vin,
        current-mileage: initial-mileage,
        registration-block: stacks-block-height,
        active: true
      }
    ))
  )
)

(define-public (log-maintenance
  (vehicle-id (string-ascii 20))
  (maintenance-type (string-ascii 50))
  (description (string-ascii 200))
  (cost uint)
  (mileage-at-service uint)
  (technician (string-ascii 50))
  (next-service-due uint)
  (parts-replaced (string-ascii 100)))
  (let (
    (vehicle (unwrap! (map-get? Vehicles { vehicle-id: vehicle-id }) ERR_VEHICLE_NOT_FOUND))
    (new-record-id (+ (var-get record-counter) u1))
  )
    (asserts! (or (is-eq tx-sender (get owner vehicle)) (is-fleet-manager tx-sender)) ERR_NOT_AUTHORIZED)
    (asserts! (> cost u0) ERR_INVALID_COST)
    (asserts! (>= mileage-at-service (get current-mileage vehicle)) ERR_INVALID_MILEAGE)
    (map-set Vehicles
      { vehicle-id: vehicle-id }
      (merge vehicle { current-mileage: mileage-at-service })
    )
    (map-set MaintenanceRecords
      { record-id: new-record-id }
      {
        vehicle-id: vehicle-id,
        maintenance-type: maintenance-type,
        description: description,
        cost: cost,
        mileage-at-service: mileage-at-service,
        service-date: stacks-block-height,
        technician: technician,
        next-service-due: next-service-due,
        parts-replaced: parts-replaced
      }
    )
    (var-set record-counter new-record-id)
    (ok new-record-id)
  )
)

(define-public (update-mileage (vehicle-id (string-ascii 20)) (new-mileage uint))
  (let ((vehicle (unwrap! (map-get? Vehicles { vehicle-id: vehicle-id }) ERR_VEHICLE_NOT_FOUND)))
    (asserts! (or (is-eq tx-sender (get owner vehicle)) (is-fleet-manager tx-sender)) ERR_NOT_AUTHORIZED)
    (asserts! (> new-mileage (get current-mileage vehicle)) ERR_INVALID_MILEAGE)
    (ok (map-set Vehicles
      { vehicle-id: vehicle-id }
      (merge vehicle { current-mileage: new-mileage })
    ))
  )
)

(define-public (deactivate-vehicle (vehicle-id (string-ascii 20)))
  (let ((vehicle (unwrap! (map-get? Vehicles { vehicle-id: vehicle-id }) ERR_VEHICLE_NOT_FOUND)))
    (asserts! (or (is-eq tx-sender (get owner vehicle)) (is-fleet-manager tx-sender)) ERR_NOT_AUTHORIZED)
    (ok (map-set Vehicles
      { vehicle-id: vehicle-id }
      (merge vehicle { active: false })
    ))
  )
)

(define-read-only (get-vehicle-value-estimate (vehicle-id (string-ascii 20)))
  (match (map-get? Vehicles { vehicle-id: vehicle-id })
    vehicle
    (let (
      (age (- u2024 (get year vehicle)))
      (mileage (get current-mileage vehicle))
      (base-value u25000)
    )
      (some (- base-value (+ (* age u1000) (/ mileage u10))))
    )
    none
  )
)

(define-read-only (get-total-maintenance-cost (vehicle-id (string-ascii 20)))
  (fold sum-maintenance-costs (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20) u0)
)

(define-private (sum-maintenance-costs (record-id uint) (total uint))
  (match (map-get? MaintenanceRecords { record-id: record-id })
    record (+ total (get cost record))
    total
  )
)

(define-read-only (get-contract-info)
  {
    owner: CONTRACT_OWNER,
    total-vehicles: u0,
    total-maintenance-records: (var-get record-counter),
    contract-block: stacks-block-height
  }
)


(define-map MaintenanceAlerts
  { alert-id: uint }
  {
    vehicle-id: (string-ascii 20),
    alert-type: (string-ascii 30),
    severity: (string-ascii 10),
    message: (string-ascii 150),
    blocks-overdue: uint,
    mileage-overdue: uint,
    created-block: uint,
    acknowledged: bool
  }
)

(define-data-var alert-counter uint u0)

(define-public (get-vehicle-alerts (vehicle-id (string-ascii 20)))
  (ok (filter-vehicle-alerts vehicle-id (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)))
)

(define-data-var current-target-vehicle (string-ascii 20) "")

(define-private (filter-vehicle-alerts (target-vehicle (string-ascii 20)) (alert-ids (list 20 uint)))
  (begin
    (var-set current-target-vehicle target-vehicle)
    (fold check-vehicle-alert-helper alert-ids (list))
  )
)

(define-private (check-vehicle-alert-helper (alert-id uint) (alerts (list 20 uint)))
  (match (map-get? MaintenanceAlerts { alert-id: alert-id })
    alert 
    (if (and (is-eq (get vehicle-id alert) (var-get current-target-vehicle)) (not (get acknowledged alert)))
      (unwrap-panic (as-max-len? (append alerts alert-id) u20))
      alerts)
    alerts
  )
)

(define-public (check-maintenance-due (vehicle-id (string-ascii 20)))
  (match (map-get? Vehicles { vehicle-id: vehicle-id })
    vehicle
    (let (
      (current-block stacks-block-height)
      (current-mileage (get current-mileage vehicle))
      (last-service-block (get-last-service-block vehicle-id))
      (next-service-mileage (get-next-service-mileage vehicle-id))
    )
      (ok (some {
        blocks-since-service: (- current-block last-service-block),
        mileage-until-service: (if (> next-service-mileage current-mileage) 
                                 (- next-service-mileage current-mileage) u0),
        maintenance-overdue: (> current-mileage next-service-mileage),
        severity: (if (> current-mileage (+ next-service-mileage CRITICAL_THRESHOLD)) 
                    "critical" 
                    (if (> current-mileage (+ next-service-mileage WARNING_THRESHOLD)) "warning" "normal"))
      }))
    )
    (ok none)
  )
)

(define-data-var current-vehicle-target (string-ascii 20) "")

(define-private (get-last-service-block (vehicle-id (string-ascii 20)))
  (begin
    (var-set current-vehicle-target vehicle-id)
    (fold find-latest-service-helper (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20) u0)
  )
)

(define-private (find-latest-service-helper (record-id uint) (latest-block uint))
  (match (map-get? MaintenanceRecords { record-id: record-id })
    record 
    (if (and (is-eq (get vehicle-id record) (var-get current-vehicle-target)) (> (get service-date record) latest-block)) 
      (get service-date record) 
      latest-block)
    latest-block
  )
)

(define-private (get-next-service-mileage (vehicle-id (string-ascii 20)))
  (begin
    (var-set current-vehicle-target vehicle-id)
    (fold find-next-service-helper (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20) u999999)
  )
)

(define-private (find-next-service-helper (record-id uint) (earliest-due uint))
  (match (map-get? MaintenanceRecords { record-id: record-id })
    record 
    (if (and (is-eq (get vehicle-id record) (var-get current-vehicle-target)) (< (get next-service-due record) earliest-due)) 
      (get next-service-due record) 
      earliest-due)
    earliest-due
  )
)

(define-public (generate-alert 
  (vehicle-id (string-ascii 20))
  (alert-type (string-ascii 30))
  (message (string-ascii 150)))
  (let (
    (vehicle (unwrap! (map-get? Vehicles { vehicle-id: vehicle-id }) ERR_VEHICLE_NOT_FOUND))
    (maintenance-response (unwrap! (check-maintenance-due vehicle-id) ERR_VEHICLE_NOT_FOUND))
    (maintenance-status (unwrap! maintenance-response ERR_VEHICLE_NOT_FOUND))
    (new-alert-id (+ (var-get alert-counter) u1))
  )
    (asserts! (or (is-eq tx-sender (get owner vehicle)) (is-fleet-manager tx-sender)) ERR_NOT_AUTHORIZED)
    (map-set MaintenanceAlerts
      { alert-id: new-alert-id }
      {
        vehicle-id: vehicle-id,
        alert-type: alert-type,
        severity: (get severity maintenance-status),
        message: message,
        blocks-overdue: (get blocks-since-service maintenance-status),
        mileage-overdue: (if (get maintenance-overdue maintenance-status) 
                          (get mileage-until-service maintenance-status) u0),
        created-block: stacks-block-height,
        acknowledged: false
      }
    )
    (var-set alert-counter new-alert-id)
    (ok new-alert-id)
  )
)

(define-public (acknowledge-alert (alert-id uint))
  (let ((alert (unwrap! (map-get? MaintenanceAlerts { alert-id: alert-id }) ERR_ALERT_NOT_FOUND)))
    (asserts! (is-fleet-manager tx-sender) ERR_NOT_AUTHORIZED)
    (ok (map-set MaintenanceAlerts
      { alert-id: alert-id }
      (merge alert { acknowledged: true })
    ))
  )
)