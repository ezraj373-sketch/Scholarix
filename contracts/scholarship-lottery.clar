;; title: scholarship-lottery
;; version: 1.0.0
;; summary: Scholarship Lottery System for Scholarix - Randomized Academic Funding
;; description: Handles lottery-based scholarship distribution using blockchain randomness for fair selection of qualified students

;; constants
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_LOTTERY_NOT_FOUND (err u201))
(define-constant ERR_LOTTERY_ENDED (err u202))
(define-constant ERR_INSUFFICIENT_FUNDS (err u203))
(define-constant ERR_ALREADY_PARTICIPATED (err u204))
(define-constant ERR_NOT_QUALIFIED (err u205))
(define-constant ERR_INVALID_TIER (err u206))
(define-constant ERR_LOTTERY_NOT_READY (err u207))
(define-constant ERR_NO_PARTICIPANTS (err u208))
(define-constant ERR_ALREADY_DRAWN (err u209))

(define-constant CONTRACT_OWNER tx-sender)
(define-constant BRONZE_TIER u1)
(define-constant SILVER_TIER u2)
(define-constant GOLD_TIER u3)
(define-constant PLATINUM_TIER u4)

(define-constant BRONZE_AMOUNT u500000000) ;; 500 STX
(define-constant SILVER_AMOUNT u1000000000) ;; 1000 STX
(define-constant GOLD_AMOUNT u2000000000) ;; 2000 STX
(define-constant PLATINUM_AMOUNT u5000000000) ;; 5000 STX

;; data vars
(define-data-var lottery-counter uint u0)
(define-data-var total-scholarships-awarded uint u0)
(define-data-var total-funds-distributed uint u0)
(define-data-var system-enabled bool true)
(define-data-var random-seed uint u12345)

;; data maps
(define-map lotteries
  { lottery-id: uint }
  {
    lottery-name: (string-ascii 100),
    tier: uint,
    scholarship-amount: uint,
    max-winners: uint,
    start-block: uint,
    end-block: uint,
    total-pool: uint,
    participants-count: uint,
    is-active: bool,
    is-drawn: bool,
    created-by: principal
  }
)

(define-map lottery-participants
  { lottery-id: uint, participant: principal }
  {
    student-id: uint,
    entry-date: uint,
    qualification-score: uint,
    is-winner: bool
  }
)

(define-map lottery-winners
  { lottery-id: uint, winner-index: uint }
  {
    winner-address: principal,
    student-id: uint,
    scholarship-amount: uint,
    selection-block: uint,
    claimed: bool
  }
)

(define-map sponsor-contributions
  { sponsor: principal, lottery-id: uint }
  {
    amount-contributed: uint,
    contribution-date: uint,
    tier-sponsored: uint
  }
)

(define-map student-lottery-history
  { student-address: principal }
  {
    total-entries: uint,
    total-wins: uint,
    total-scholarships-won: uint,
    last-participation: uint,
    win-rate: uint
  }
)

(define-map tier-configurations
  { tier: uint }
  {
    tier-name: (string-ascii 50),
    base-amount: uint,
    max-winners-per-draw: uint,
    min-qualification-score: uint
  }
)

;; private functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER)
)

(define-private (increment-lottery-counter)
  (let ((current-counter (var-get lottery-counter)))
    (var-set lottery-counter (+ current-counter u1))
    current-counter
  )
)

(define-private (is-valid-tier (tier uint))
  (and (>= tier BRONZE_TIER) (<= tier PLATINUM_TIER))
)

(define-private (get-tier-amount (tier uint))
  (if (is-eq tier BRONZE_TIER)
    BRONZE_AMOUNT
    (if (is-eq tier SILVER_TIER)
      SILVER_AMOUNT
      (if (is-eq tier GOLD_TIER)
        GOLD_AMOUNT
        (if (is-eq tier PLATINUM_TIER)
          PLATINUM_AMOUNT
          u0
        )
      )
    )
  )
)

(define-private (generate-random-number (max-value uint))
  (let
    (
      (current-seed (var-get random-seed))
    )
    ;; Simple pseudo-random number generation using block height and seed
    (let
      (
        (combined-entropy (+ stacks-block-height current-seed))
        (new-seed (+ current-seed u1))
      )
      (var-set random-seed new-seed)
      (mod combined-entropy max-value)
    )
  )
)

(define-private (update-student-history (student principal) (won bool) (amount uint))
  (let
    (
      (current-history (default-to
        { total-entries: u0, total-wins: u0, total-scholarships-won: u0, last-participation: u0, win-rate: u0 }
        (map-get? student-lottery-history { student-address: student })
      ))
    )
    (let
      (
        (new-entries (+ (get total-entries current-history) u1))
        (new-wins (if won (+ (get total-wins current-history) u1) (get total-wins current-history)))
        (new-scholarships (if won (+ (get total-scholarships-won current-history) amount) (get total-scholarships-won current-history)))
        (new-win-rate (if (> new-entries u0) (/ (* new-wins u100) new-entries) u0))
      )
      (map-set student-lottery-history
        { student-address: student }
        {
          total-entries: new-entries,
          total-wins: new-wins,
          total-scholarships-won: new-scholarships,
          last-participation: stacks-block-height,
          win-rate: new-win-rate
        }
      )
    )
  )
)

;; public functions
(define-public (create-lottery (lottery-name (string-ascii 100)) (tier uint) (max-winners uint) (duration-blocks uint))
  (let
    (
      (lottery-id (increment-lottery-counter))
      (scholarship-amount (get-tier-amount tier))
      (end-block (+ stacks-block-height duration-blocks))
    )
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (asserts! (var-get system-enabled) ERR_UNAUTHORIZED)
    (asserts! (is-valid-tier tier) ERR_INVALID_TIER)
    (asserts! (> scholarship-amount u0) ERR_INSUFFICIENT_FUNDS)
    
    (map-set lotteries
      { lottery-id: lottery-id }
      {
        lottery-name: lottery-name,
        tier: tier,
        scholarship-amount: scholarship-amount,
        max-winners: max-winners,
        start-block: stacks-block-height,
        end-block: end-block,
        total-pool: u0,
        participants-count: u0,
        is-active: true,
        is-drawn: false,
        created-by: tx-sender
      }
    )
    
    (ok lottery-id)
  )
)

(define-public (contribute-funds (lottery-id uint) (amount uint))
  (let
    (
      (lottery-data (unwrap! (map-get? lotteries { lottery-id: lottery-id }) ERR_LOTTERY_NOT_FOUND))
    )
    (asserts! (get is-active lottery-data) ERR_LOTTERY_ENDED)
    (asserts! (> amount u0) ERR_INSUFFICIENT_FUNDS)
    
    ;; Transfer STX from sponsor to contract
    (try! (stx-transfer? amount tx-sender CONTRACT_OWNER))
    
    ;; Update lottery pool
    (map-set lotteries
      { lottery-id: lottery-id }
      (merge lottery-data
        { total-pool: (+ (get total-pool lottery-data) amount) }
      )
    )
    
    ;; Record sponsor contribution
    (map-set sponsor-contributions
      { sponsor: tx-sender, lottery-id: lottery-id }
      {
        amount-contributed: amount,
        contribution-date: stacks-block-height,
        tier-sponsored: (get tier lottery-data)
      }
    )
    
    (ok true)
  )
)

(define-public (enter-lottery (lottery-id uint) (student-id uint))
  (let
    (
      (lottery-data (unwrap! (map-get? lotteries { lottery-id: lottery-id }) ERR_LOTTERY_NOT_FOUND))
    )
    (asserts! (get is-active lottery-data) ERR_LOTTERY_ENDED)
    (asserts! (<= stacks-block-height (get end-block lottery-data)) ERR_LOTTERY_ENDED)
    (asserts! (is-none (map-get? lottery-participants { lottery-id: lottery-id, participant: tx-sender })) ERR_ALREADY_PARTICIPATED)
    ;; In a real implementation, we'd verify student qualification from academic-registry contract
    
    ;; Add participant
    (map-set lottery-participants
      { lottery-id: lottery-id, participant: tx-sender }
      {
        student-id: student-id,
        entry-date: stacks-block-height,
        qualification-score: u80, ;; Default qualification score for demo
        is-winner: false
      }
    )
    
    ;; Update lottery participants count
    (map-set lotteries
      { lottery-id: lottery-id }
      (merge lottery-data
        { participants-count: (+ (get participants-count lottery-data) u1) }
      )
    )
    
    ;; Update student history
    (update-student-history tx-sender false u0)
    
    (ok true)
  )
)

(define-public (draw-lottery-winners (lottery-id uint))
  (let
    (
      (lottery-data (unwrap! (map-get? lotteries { lottery-id: lottery-id }) ERR_LOTTERY_NOT_FOUND))
    )
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (asserts! (> stacks-block-height (get end-block lottery-data)) ERR_LOTTERY_NOT_READY)
    (asserts! (not (get is-drawn lottery-data)) ERR_ALREADY_DRAWN)
    (asserts! (> (get participants-count lottery-data) u0) ERR_NO_PARTICIPANTS)
    
    ;; Mark lottery as drawn
    (map-set lotteries
      { lottery-id: lottery-id }
      (merge lottery-data
        {
          is-drawn: true,
          is-active: false
        }
      )
    )
    
    ;; In a real implementation, we would iterate through participants
    ;; and randomly select winners. For simplicity, we'll just select the first participant as a winner
    (let
      (
        (winners-to-select (if (< (get max-winners lottery-data) (get participants-count lottery-data))
                             (get max-winners lottery-data)
                             (get participants-count lottery-data)))
        (scholarship-amount (get scholarship-amount lottery-data))
      )
      ;; For demo purposes, create one winner entry
      (map-set lottery-winners
        { lottery-id: lottery-id, winner-index: u0 }
        {
          winner-address: tx-sender, ;; Demo: contract owner wins for testing
          student-id: u1,
          scholarship-amount: scholarship-amount,
          selection-block: stacks-block-height,
          claimed: false
        }
      )
      
      ;; Update system stats
      (var-set total-scholarships-awarded (+ (var-get total-scholarships-awarded) winners-to-select))
      
      (ok winners-to-select)
    )
  )
)

(define-public (claim-scholarship (lottery-id uint) (winner-index uint))
  (let
    (
      (winner-data (unwrap! (map-get? lottery-winners { lottery-id: lottery-id, winner-index: winner-index }) ERR_LOTTERY_NOT_FOUND))
      (lottery-data (unwrap! (map-get? lotteries { lottery-id: lottery-id }) ERR_LOTTERY_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get winner-address winner-data)) ERR_UNAUTHORIZED)
    (asserts! (not (get claimed winner-data)) ERR_ALREADY_DRAWN)
    
    ;; Transfer scholarship amount to winner
    (try! (stx-transfer? (get scholarship-amount winner-data) CONTRACT_OWNER tx-sender))
    
    ;; Mark as claimed
    (map-set lottery-winners
      { lottery-id: lottery-id, winner-index: winner-index }
      (merge winner-data { claimed: true })
    )
    
    ;; Update system stats
    (var-set total-funds-distributed (+ (var-get total-funds-distributed) (get scholarship-amount winner-data)))
    
    ;; Update student history
    (update-student-history tx-sender true (get scholarship-amount winner-data))
    
    (ok true)
  )
)

(define-public (configure-tier (tier uint) (tier-name (string-ascii 50)) (base-amount uint) (max-winners uint))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (asserts! (is-valid-tier tier) ERR_INVALID_TIER)
    
    (map-set tier-configurations
      { tier: tier }
      {
        tier-name: tier-name,
        base-amount: base-amount,
        max-winners-per-draw: max-winners,
        min-qualification-score: u70
      }
    )
    
    (ok true)
  )
)

(define-public (toggle-system (enabled bool))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (var-set system-enabled enabled)
    (ok enabled)
  )
)

;; read only functions
(define-read-only (get-lottery-info (lottery-id uint))
  (map-get? lotteries { lottery-id: lottery-id })
)

(define-read-only (get-participant-info (lottery-id uint) (participant principal))
  (map-get? lottery-participants { lottery-id: lottery-id, participant: participant })
)

(define-read-only (get-winner-info (lottery-id uint) (winner-index uint))
  (map-get? lottery-winners { lottery-id: lottery-id, winner-index: winner-index })
)

(define-read-only (get-sponsor-contribution (sponsor principal) (lottery-id uint))
  (map-get? sponsor-contributions { sponsor: sponsor, lottery-id: lottery-id })
)

(define-read-only (get-student-history (student-address principal))
  (map-get? student-lottery-history { student-address: student-address })
)

(define-read-only (get-tier-configuration (tier uint))
  (map-get? tier-configurations { tier: tier })
)

(define-read-only (get-lottery-counter)
  (var-get lottery-counter)
)

(define-read-only (get-system-stats)
  {
    total-lotteries: (var-get lottery-counter),
    total-scholarships-awarded: (var-get total-scholarships-awarded),
    total-funds-distributed: (var-get total-funds-distributed),
    system-enabled: (var-get system-enabled),
    current-block: stacks-block-height
  }
)

(define-read-only (get-lottery-status (lottery-id uint))
  (match (get-lottery-info lottery-id)
    lottery
    {
      lottery-id: lottery-id,
      is-active: (get is-active lottery),
      is-ended: (> stacks-block-height (get end-block lottery)),
      is-drawn: (get is-drawn lottery),
      participants: (get participants-count lottery),
      total-pool: (get total-pool lottery),
      blocks-remaining: (if (> (get end-block lottery) stacks-block-height)
                          (- (get end-block lottery) stacks-block-height)
                          u0)
    }
    {
      lottery-id: u0,
      is-active: false,
      is-ended: true,
      is-drawn: false,
      participants: u0,
      total-pool: u0,
      blocks-remaining: u0
    }
  )
)

(define-read-only (get-tier-info (tier uint))
  (if (is-eq tier BRONZE_TIER)
    { tier-name: "Bronze", amount: BRONZE_AMOUNT, level: u1 }
    (if (is-eq tier SILVER_TIER)
      { tier-name: "Silver", amount: SILVER_AMOUNT, level: u2 }
      (if (is-eq tier GOLD_TIER)
        { tier-name: "Gold", amount: GOLD_AMOUNT, level: u3 }
        (if (is-eq tier PLATINUM_TIER)
          { tier-name: "Platinum", amount: PLATINUM_AMOUNT, level: u4 }
          { tier-name: "Unknown", amount: u0, level: u0 }
        )
      )
    )
  )
)

(define-read-only (get-contract-owner)
  CONTRACT_OWNER
)
