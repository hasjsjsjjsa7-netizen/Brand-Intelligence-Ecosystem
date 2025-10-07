;; Competitive Intelligence Engine Contract
;; Automated competitor strategy analysis and market positioning insights

;; Constants for error codes and system parameters
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-INVALID-BRAND (err u201))
(define-constant ERR-INVALID-COMPETITOR (err u202))
(define-constant ERR-INVALID-MARKET-SHARE (err u203))
(define-constant ERR-DATA-NOT-FOUND (err u204))
(define-constant ERR-INSUFFICIENT-DATA (err u205))
(define-constant ERR-STRATEGY-EXISTS (err u206))

(define-constant MAX-BRAND-ID-LENGTH u64)
(define-constant MAX-STRATEGY-LENGTH u32)
(define-constant MAX-ANALYSIS-LENGTH u256)
(define-constant MAX-MARKET-SHARE u100)
(define-constant MIN-POSITIONING-SCORE -100)
(define-constant MAX-POSITIONING-SCORE 100)
(define-constant COMPETITIVE-ADVANTAGE-THRESHOLD 25)

;; Competitor data structure
(define-map competitor-data
  { brand-id: (string-ascii 64), competitor-id: (string-ascii 64) }
  {
    market-share: uint,
    positioning-score: int,
    strategy-type: (string-ascii 32),
    competitive-strength: uint,
    last-updated: uint,
    analysis-confidence: uint
  }
)

;; Market positioning analysis
(define-map market-positioning
  { brand-id: (string-ascii 64) }
  {
    current-position: uint,
    market-leadership-score: int,
    competitive-advantage: bool,
    total-market-share: uint,
    positioning-trend: int,
    last-analysis: uint
  }
)

;; Strategic opportunities tracking
(define-map strategic-opportunities
  { brand-id: (string-ascii 64), opportunity-id: uint }
  {
    opportunity-type: (string-ascii 32),
    potential-impact: uint,
    implementation-difficulty: uint,
    market-gap-size: uint,
    competitor-weakness: (string-ascii 64),
    identified-at: uint,
    priority-level: uint
  }
)

;; Competitive insights and analysis
(define-map competitive-insights
  { brand-id: (string-ascii 64), insight-id: uint }
  {
    insight-type: (string-ascii 32),
    description: (string-ascii 256),
    confidence-level: uint,
    actionability-score: uint,
    related-competitors: (list 5 (string-ascii 64)),
    generated-at: uint,
    reviewed: bool
  }
)

;; SWOT analysis data
(define-map swot-analysis
  { brand-id: (string-ascii 64) }
  {
    strengths-count: uint,
    weaknesses-count: uint,
    opportunities-count: uint,
    threats-count: uint,
    overall-score: int,
    last-updated: uint
  }
)

;; System state variables
(define-data-var contract-owner principal tx-sender)
(define-data-var total-analyses uint u0)
(define-data-var total-opportunities-identified uint u0)
(define-data-var total-insights-generated uint u0)
(define-data-var system-active bool true)
(define-data-var next-opportunity-id uint u1)
(define-data-var next-insight-id uint u1)

;; Authorization functions
(define-private (is-authorized (caller principal))
  (is-eq caller (var-get contract-owner))
)

;; Validation functions
(define-private (validate-brand-id (brand-id (string-ascii 64)))
  (and 
    (> (len brand-id) u0)
    (<= (len brand-id) MAX-BRAND-ID-LENGTH)
  )
)

(define-private (validate-market-share (share uint))
  (and (>= share u0) (<= share MAX-MARKET-SHARE))
)

(define-private (validate-positioning-score (score int))
  (and 
    (>= score MIN-POSITIONING-SCORE) 
    (<= score MAX-POSITIONING-SCORE)
  )
)

(define-private (validate-strategy-type (strategy (string-ascii 32)))
  (and 
    (> (len strategy) u0)
    (<= (len strategy) MAX-STRATEGY-LENGTH)
  )
)

;; Market position calculation
(define-private (calculate-market-position 
    (brand-share uint) 
    (total-market uint)
    (competitor-count uint)
  )
  (if (> total-market u0)
    (/ (* brand-share u100) total-market)
    u0
  )
)

;; Competitive advantage detection
(define-private (detect-competitive-advantage 
    (brand-positioning int)
    (avg-competitor-positioning int)
  )
  (> (- brand-positioning avg-competitor-positioning) COMPETITIVE-ADVANTAGE-THRESHOLD)
)

;; Strategic opportunity scoring
(define-private (calculate-opportunity-score 
    (impact uint)
    (difficulty uint)
    (market-gap uint)
  )
  (let 
    (
      (base-score (+ impact market-gap))
      (difficulty-penalty (if (> difficulty u70) u30 u10))
    )
    (if (> base-score difficulty-penalty)
      (- base-score difficulty-penalty)
      u1
    )
  )
)

;; Generate competitive insights
(define-private (generate-insight 
    (brand-id (string-ascii 64))
    (insight-type (string-ascii 32))
    (description (string-ascii 256))
    (confidence uint)
    (competitors (list 5 (string-ascii 64)))
  )
  (let 
    (
      (insight-id (var-get next-insight-id))
      (actionability (if (> confidence u80) u90 (if (> confidence u60) u70 u50)))
    )
    (map-set competitive-insights
      { brand-id: brand-id, insight-id: insight-id }
      {
        insight-type: insight-type,
        description: description,
        confidence-level: confidence,
        actionability-score: actionability,
        related-competitors: competitors,
        generated-at: stacks-block-height,
        reviewed: false
      }
    )
    (var-set next-insight-id (+ insight-id u1))
    (var-set total-insights-generated (+ (var-get total-insights-generated) u1))
    insight-id
  )
)

;; PUBLIC FUNCTIONS

;; Submit competitor analysis data
(define-public (submit-competitor-data
    (brand-id (string-ascii 64))
    (competitor-id (string-ascii 64))
    (market-share uint)
    (positioning-score int)
    (strategy-type (string-ascii 32))
    (competitive-strength uint)
  )
  (begin
    ;; Validate inputs
    (asserts! (var-get system-active) (err u999))
    (asserts! (validate-brand-id brand-id) ERR-INVALID-BRAND)
    (asserts! (validate-brand-id competitor-id) ERR-INVALID-COMPETITOR)
    (asserts! (validate-market-share market-share) ERR-INVALID-MARKET-SHARE)
    (asserts! (validate-positioning-score positioning-score) ERR-INVALID-MARKET-SHARE)
    (asserts! (validate-strategy-type strategy-type) ERR-INVALID-BRAND)
    (asserts! (<= competitive-strength u100) ERR-INVALID-MARKET-SHARE)
    
    ;; Store competitor data
    (map-set competitor-data
      { brand-id: brand-id, competitor-id: competitor-id }
      {
        market-share: market-share,
        positioning-score: positioning-score,
        strategy-type: strategy-type,
        competitive-strength: competitive-strength,
        last-updated: stacks-block-height,
        analysis-confidence: u85
      }
    )
    
    (var-set total-analyses (+ (var-get total-analyses) u1))
    (ok { submitted: true, brand-id: brand-id, competitor-id: competitor-id })
  )
)

;; Analyze market opportunities
(define-public (analyze-opportunities
    (brand-id (string-ascii 64))
    (opportunity-type (string-ascii 32))
    (potential-impact uint)
    (implementation-difficulty uint)
    (market-gap-size uint)
  )
  (begin
    (asserts! (var-get system-active) (err u999))
    (asserts! (validate-brand-id brand-id) ERR-INVALID-BRAND)
    (asserts! (<= potential-impact u100) ERR-INVALID-MARKET-SHARE)
    (asserts! (<= implementation-difficulty u100) ERR-INVALID-MARKET-SHARE)
    (asserts! (<= market-gap-size u100) ERR-INVALID-MARKET-SHARE)
    
    (let 
      (
        (opportunity-id (var-get next-opportunity-id))
        (priority (if (>= (calculate-opportunity-score potential-impact implementation-difficulty market-gap-size) u70) u3
                   (if (>= (calculate-opportunity-score potential-impact implementation-difficulty market-gap-size) u40) u2 u1)))
      )
      
      (map-set strategic-opportunities
        { brand-id: brand-id, opportunity-id: opportunity-id }
        {
          opportunity-type: opportunity-type,
          potential-impact: potential-impact,
          implementation-difficulty: implementation-difficulty,
          market-gap-size: market-gap-size,
          competitor-weakness: "",
          identified-at: stacks-block-height,
          priority-level: priority
        }
      )
      
      (var-set next-opportunity-id (+ opportunity-id u1))
      (var-set total-opportunities-identified (+ (var-get total-opportunities-identified) u1))
      
      ;; Generate related insight
      (let 
        (
          (insight-id (generate-insight 
            brand-id 
            "opportunity-analysis" 
            "Market opportunity identified with strategic potential"
            u75
            (list)
          ))
        )
        (ok { opportunity-id: opportunity-id, insight-generated: insight-id, priority: priority })
      )
    )
  )
)

;; Update market positioning
(define-public (update-market-positioning
    (brand-id (string-ascii 64))
    (current-position uint)
    (leadership-score int)
    (total-market-share uint)
  )
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (validate-brand-id brand-id) ERR-INVALID-BRAND)
    (asserts! (<= current-position u10) ERR-INVALID-MARKET-SHARE)
    (asserts! (validate-positioning-score leadership-score) ERR-INVALID-MARKET-SHARE)
    
    (let 
      (
        (has-advantage (> leadership-score COMPETITIVE-ADVANTAGE-THRESHOLD))
        (trend-score (if has-advantage 1 (if (> leadership-score 0) 0 -1)))
      )
      
      (map-set market-positioning
        { brand-id: brand-id }
        {
          current-position: current-position,
          market-leadership-score: leadership-score,
          competitive-advantage: has-advantage,
          total-market-share: total-market-share,
          positioning-trend: trend-score,
          last-analysis: stacks-block-height
        }
      )
      
      (ok { updated: true, competitive-advantage: has-advantage, trend: trend-score })
    )
  )
)

;; Review competitive insight
(define-public (review-insight (brand-id (string-ascii 64)) (insight-id uint))
  (begin
    (asserts! (is-authorized tx-sender) ERR-NOT-AUTHORIZED)
    (let 
      (
        (insight-data (unwrap! (map-get? competitive-insights { brand-id: brand-id, insight-id: insight-id }) ERR-DATA-NOT-FOUND))
      )
      (asserts! (not (get reviewed insight-data)) (err u207))
      (map-set competitive-insights
        { brand-id: brand-id, insight-id: insight-id }
        (merge insight-data { reviewed: true })
      )
      (ok true)
    )
  )
)

;; READ-ONLY FUNCTIONS

;; Get competitor data
(define-read-only (get-competitor-data (brand-id (string-ascii 64)) (competitor-id (string-ascii 64)))
  (map-get? competitor-data { brand-id: brand-id, competitor-id: competitor-id })
)

;; Get market position
(define-read-only (get-market-position (brand-id (string-ascii 64)))
  (map-get? market-positioning { brand-id: brand-id })
)

;; Get strategic opportunity
(define-read-only (get-strategic-opportunity (brand-id (string-ascii 64)) (opportunity-id uint))
  (map-get? strategic-opportunities { brand-id: brand-id, opportunity-id: opportunity-id })
)

;; Get competitive insight
(define-read-only (get-competitive-insight (brand-id (string-ascii 64)) (insight-id uint))
  (map-get? competitive-insights { brand-id: brand-id, insight-id: insight-id })
)

;; Check if brand has competitive advantage
(define-read-only (has-competitive-advantage (brand-id (string-ascii 64)))
  (match (map-get? market-positioning { brand-id: brand-id })
    position-data (get competitive-advantage position-data)
    false
  )
)

;; Get SWOT analysis
(define-read-only (get-swot-analysis (brand-id (string-ascii 64)))
  (map-get? swot-analysis { brand-id: brand-id })
)

;; Get system statistics
(define-read-only (get-system-statistics)
  {
    total-analyses: (var-get total-analyses),
    total-opportunities: (var-get total-opportunities-identified),
    total-insights: (var-get total-insights-generated),
    system-active: (var-get system-active),
    next-opportunity-id: (var-get next-opportunity-id),
    next-insight-id: (var-get next-insight-id)
  }
)
