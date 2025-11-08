(define-constant ERR_VEHICLE_NOT_FOUND (err u101))
(define-constant ERR_INSUFFICIENT_DATA (err u120))
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_PARAMETERS (err u121))

(define-constant HEALTH_SCORE_MULTIPLIER u1000)
(define-constant MAX_HEALTH_SCORE u10000)
(define-constant CRITICAL_HEALTH_THRESHOLD u3000)
(define-constant WARNING_HEALTH_THRESHOLD u6000)

(define-map VehicleHealthScores
  { vehicle-id: (string-ascii 20) }
  {
    health-score: uint,
    risk-level: (string-ascii 10),
    last-calculated: uint,
    total-services: uint,
    avg-service-interval: uint,
    failure-probability: uint
  }
)

(define-map PredictiveInsights
  { insight-id: uint }
  {
    vehicle-id: (string-ascii 20),
    predicted-failure-block: uint,
    predicted-failure-mileage: uint,
    recommended-action: (string-ascii 100),
    confidence-score: uint,
    insight-block: uint
  }
)

(define-data-var insight-counter uint u0)

(define-read-only (calculate-health-score (vehicle-id (string-ascii 20)))
  (match (contract-call? .Clarity-Based-Fleet-Maintenance-Ledger get-vehicle vehicle-id)
    vehicle
    (let (
      (current-mileage (get current-mileage vehicle))
      (vehicle-age (- stacks-block-height (get registration-block vehicle)))
      (total-maintenance (contract-call? .Clarity-Based-Fleet-Maintenance-Ledger get-total-maintenance-cost vehicle-id))
      (mileage-factor (if (> current-mileage u0) (/ MAX_HEALTH_SCORE (/ current-mileage u1000)) MAX_HEALTH_SCORE))
      (age-factor (if (> vehicle-age u0) (/ MAX_HEALTH_SCORE (/ vehicle-age u100)) MAX_HEALTH_SCORE))
      (maintenance-factor (if (> total-maintenance u0) (/ MAX_HEALTH_SCORE (/ total-maintenance u10)) MAX_HEALTH_SCORE))
      (raw-score (/ (+ (+ mileage-factor age-factor) maintenance-factor) u3))
      (health-score (if (> raw-score MAX_HEALTH_SCORE) MAX_HEALTH_SCORE raw-score))
      (risk-level (if (< health-score CRITICAL_HEALTH_THRESHOLD) "critical" 
                    (if (< health-score WARNING_HEALTH_THRESHOLD) "warning" "good")))
    )
      (ok {
        health-score: health-score,
        risk-level: risk-level,
        mileage-impact: mileage-factor,
        age-impact: age-factor,
        maintenance-impact: maintenance-factor
      })
    )
    ERR_VEHICLE_NOT_FOUND
  )
)

(define-public (predict-next-failure (vehicle-id (string-ascii 20)) (projected-miles uint))
  (match (contract-call? .Clarity-Based-Fleet-Maintenance-Ledger get-vehicle vehicle-id)
    vehicle
    (let (
      (health-data (unwrap! (calculate-health-score vehicle-id) ERR_INSUFFICIENT_DATA))
      (current-mileage (get current-mileage vehicle))
      (health-score (get health-score health-data))
      (failure-probability (- u100 (/ (* health-score u100) MAX_HEALTH_SCORE)))
      (estimated-blocks (/ (* projected-miles u10) u1))
      (predicted-failure-block (+ stacks-block-height estimated-blocks))
      (predicted-mileage (+ current-mileage projected-miles))
      (confidence (if (< health-score CRITICAL_HEALTH_THRESHOLD) u85 
                    (if (< health-score WARNING_HEALTH_THRESHOLD) u60 u35)))
      (recommendation (if (< health-score CRITICAL_HEALTH_THRESHOLD) "Immediate inspection required - high failure risk detected"
                        (if (< health-score WARNING_HEALTH_THRESHOLD) "Schedule preventive maintenance within 500 miles"
                          "Continue normal operation - monitor regularly")))
      (new-insight-id (+ (var-get insight-counter) u1))
    )
      (map-set PredictiveInsights
        { insight-id: new-insight-id }
        {
          vehicle-id: vehicle-id,
          predicted-failure-block: predicted-failure-block,
          predicted-failure-mileage: predicted-mileage,
          recommended-action: recommendation,
          confidence-score: confidence,
          insight-block: stacks-block-height
        }
      )
      (var-set insight-counter new-insight-id)
      (ok {
        insight-id: new-insight-id,
        failure-probability: failure-probability,
        predicted-failure-block: predicted-failure-block,
        confidence: confidence,
        recommended-action: recommendation
      })
    )
    ERR_VEHICLE_NOT_FOUND
  )
)

(define-read-only (get-predictive-insight (insight-id uint))
  (map-get? PredictiveInsights { insight-id: insight-id })
)

(define-read-only (get-health-score-record (vehicle-id (string-ascii 20)))
  (map-get? VehicleHealthScores { vehicle-id: vehicle-id })
)
