;; Real-Time Sentiment Analysis Contract
;; Multi-platform social listening with predictive brand crisis detection

;; Constants for error codes and system limits
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-BRAND (err u101))
(define-constant ERR-INVALID-SENTIMENT (err u102))
(define-constant ERR-INVALID-PLATFORM (err u103))
(define-constant ERR-DATA-NOT-FOUND (err u104))
(define-constant ERR-CRISIS-THRESHOLD-EXCEEDED (err u105))

(define-constant MAX-BRAND-ID-LENGTH u64)
(define-constant MAX-PLATFORM-LENGTH u32)
(define-constant MAX-DATA-SOURCE-LENGTH u128)
(define-constant CRISIS-THRESHOLD -50)
(define-constant MIN-CONFIDENCE-LEVEL u0)
(define-constant MAX-CONFIDENCE-LEVEL u100)

;; Data structure for sentiment data
(define-map sentiment-data
  { brand-id: (string-ascii 64), timestamp: uint }
  {
    platform: (string-ascii 32),
    sentiment-score: int,
    confidence-level: uint,
    data-source: (string-ascii 128),
    stacks-block-height: uint
  }
)

;; Track current sentiment scores by brand
(define-map current-sentiment-scores
  { brand-id: (string-ascii 64) }
  {
    latest-score: int,
    average-score: int,
    total-entries: uint,
    last-updated: uint,
    crisis-flag: bool
  }
)

;; Historical sentiment tracking for trend analysis
(define-map sentiment-history
  { brand-id: (string-ascii 64), period: uint }
  {
    average-sentiment: int,
    entry-count: uint,
    volatility-score: uint,
    platforms-tracked: (list 10 (string-ascii 32))
  }
)

;; Crisis detection log
(define-map crisis-alerts
  { brand-id: (string-ascii 64), alert-id: uint }
  {
    triggered-at: uint,
    severity-level: uint,
    trigger-score: int,
    platform: (string-ascii 32),
    resolved: bool
  }
)

;; Data variables for system state
(define-data-var contract-owner principal tx-sender)
(define-data-var total-submissions uint u0)
(define-data-var total-brands-tracked uint u0)
(define-data-var crisis-alert-counter uint u0)
(define-data-var system-active bool true)

;; Authorization check
(define-private (is-authorized (caller principal))
  (is-eq caller (var-get contract-owner))
)

;; Validate input parameters
(define-private (validate-brand-id (brand-id (string-ascii 64)))
  (and 
    (> (len brand-id) u0)
    (<= (len brand-id) MAX-BRAND-ID-LENGTH)
  )
)

(define-private (validate-sentiment-score (score int))
  (and (>= score -100) (<= score 100))
)

(define-private (validate-confidence-level (confidence uint))
  (and 
    (>= confidence MIN-CONFIDENCE-LEVEL) 
    (<= confidence MAX-CONFIDENCE-LEVEL)
  )
)

(define-private (validate-platform (platform (string-ascii 32)))
  (and 
    (> (len platform) u0)
    (<= (len platform) MAX-PLATFORM-LENGTH)
  )
)

;; Calculate running average sentiment
(define-private (calculate-average-sentiment 
    (current-avg int) 
    (total-entries uint) 
    (new-score int)
  )
  (if (is-eq total-entries u0)
    new-score
    (/ (+ (* current-avg (to-int total-entries)) new-score) (to-int (+ total-entries u1)))
  )
)

;; Crisis detection logic
(define-private (detect-crisis-conditions (brand-id (string-ascii 64)) (sentiment-score int))
  (let 
    (
      (current-data (default-to 
        { latest-score: 0, average-score: 0, total-entries: u0, last-updated: u0, crisis-flag: false }
        (map-get? current-sentiment-scores { brand-id: brand-id })
      ))
    )
    (or 
      (< sentiment-score CRISIS-THRESHOLD)
      (and 
        (> (get total-entries current-data) u5)
        (< (get average-score current-data) (- CRISIS-THRESHOLD 20))
      )
    )
  )
)

;; Trigger crisis alert
(define-private (trigger-crisis-alert 
    (brand-id (string-ascii 64)) 
    (score int) 
    (platform (string-ascii 32))
  )
  (let 
    (
      (alert-id (+ (var-get crisis-alert-counter) u1))
      (severity (if (< score (- CRISIS-THRESHOLD 25)) u3 
                  (if (< score (- CRISIS-THRESHOLD 10)) u2 u1)))
    )
    (map-set crisis-alerts 
      { brand-id: brand-id, alert-id: alert-id }
      {
        triggered-at: stacks-block-height,
        severity-level: severity,
        trigger-score: score,
        platform: platform,
        resolved: false
      }
    )
    (var-set crisis-alert-counter alert-id)
    (ok alert-id)
  )
)

;; PUBLIC FUNCTIONS

;; Submit new sentiment data
(define-public (submit-sentiment-data 
    (brand-id (string-ascii 64))
    (platform (string-ascii 32))
    (sentiment-score int)
    (confidence-level uint)
    (data-source (string-ascii 128))
  )
  (begin
    ;; Validate all inputs
    (asserts! (var-get system-active) (err u999))
    (asserts! (validate-brand-id brand-id) ERR-INVALID-BRAND)
    (asserts! (validate-platform platform) ERR-INVALID-PLATFORM)
    (asserts! (validate-sentiment-score sentiment-score) ERR-INVALID-SENTIMENT)
    (asserts! (validate-confidence-level confidence-level) ERR-INVALID-PLATFORM)
    
    (let 
      (
        (timestamp stacks-block-height)
        (current-data (default-to 
          { latest-score: 0, average-score: 0, total-entries: u0, last-updated: u0, crisis-flag: false }
          (map-get? current-sentiment-scores { brand-id: brand-id })
        ))
        (new-average (calculate-average-sentiment 
          (get average-score current-data) 
          (get total-entries current-data) 
          sentiment-score
        ))
        (is-crisis (detect-crisis-conditions brand-id sentiment-score))
      )
      
      ;; Store the sentiment data
      (map-set sentiment-data
        { brand-id: brand-id, timestamp: timestamp }
        {
          platform: platform,
          sentiment-score: sentiment-score,
          confidence-level: confidence-level,
          data-source: data-source,
          stacks-block-height: timestamp
        }
      )
      
      ;; Update current sentiment scores
      (map-set current-sentiment-scores
        { brand-id: brand-id }
        {
          latest-score: sentiment-score,
          average-score: new-average,
          total-entries: (+ (get total-entries current-data) u1),
          last-updated: timestamp,
          crisis-flag: is-crisis
        }
      )
      
      ;; Trigger crisis alert if needed
      (if is-crisis
        (let 
          (
            (alert-result (trigger-crisis-alert brand-id sentiment-score platform))
          )
          (var-set total-submissions (+ (var-get total-submissions) u1))
          (ok { submitted: true, crisis-alert: (unwrap-panic alert-result) })
        )
        (begin 
          (var-set total-submissions (+ (var-get total-submissions) u1))
          (ok { submitted: true, crisis-alert: u0 })
        )
      )
    )
  )
)

;; Resolve crisis alert
(define-public (resolve-crisis-alert (brand-id (string-ascii 64)) (alert-id uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (let 
      (
        (alert-data (unwrap! (map-get? crisis-alerts { brand-id: brand-id, alert-id: alert-id }) ERR-DATA-NOT-FOUND))
      )
      (asserts! (not (get resolved alert-data)) (err u106))
      (map-set crisis-alerts
        { brand-id: brand-id, alert-id: alert-id }
        (merge alert-data { resolved: true })
      )
      (ok true)
    )
  )
)

;; READ-ONLY FUNCTIONS

;; Get current sentiment score for a brand
(define-read-only (get-sentiment-score (brand-id (string-ascii 64)))
  (map-get? current-sentiment-scores { brand-id: brand-id })
)

;; Get specific sentiment data entry
(define-read-only (get-sentiment-data (brand-id (string-ascii 64)) (timestamp uint))
  (map-get? sentiment-data { brand-id: brand-id, timestamp: timestamp })
)

;; Check if brand is in crisis state
(define-read-only (is-brand-in-crisis (brand-id (string-ascii 64)))
  (match (map-get? current-sentiment-scores { brand-id: brand-id })
    data (get crisis-flag data)
    false
  )
)

;; Get crisis alert details
(define-read-only (get-crisis-alert (brand-id (string-ascii 64)) (alert-id uint))
  (map-get? crisis-alerts { brand-id: brand-id, alert-id: alert-id })
)

;; Get system statistics
(define-read-only (get-system-stats)
  {
    total-submissions: (var-get total-submissions),
    total-brands-tracked: (var-get total-brands-tracked),
    total-crisis-alerts: (var-get crisis-alert-counter),
    system-active: (var-get system-active),
    contract-owner: (var-get contract-owner)
  }
)
