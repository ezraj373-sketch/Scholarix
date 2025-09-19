;; title: academic-registry
;; version: 1.0.0
;; summary: Academic Registry for Scholarix - Student Exam and Grade Management
;; description: Manages student registration, exam scores, and academic qualification for scholarship lottery eligibility

;; constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_STUDENT_NOT_FOUND (err u101))
(define-constant ERR_STUDENT_EXISTS (err u102))
(define-constant ERR_INVALID_SCORE (err u103))
(define-constant ERR_INVALID_SUBJECT (err u104))
(define-constant ERR_INSTITUTION_NOT_AUTHORIZED (err u105))
(define-constant ERR_INVALID_GPA (err u106))
(define-constant ERR_EXAM_NOT_FOUND (err u107))
(define-constant ERR_ALREADY_QUALIFIED (err u108))

(define-constant CONTRACT_OWNER tx-sender)
(define-constant MIN_PASSING_SCORE u60) ;; Minimum 60% to pass
(define-constant MAX_SCORE u100)
(define-constant MIN_GPA u250) ;; Minimum 2.5 GPA (scaled by 100)
(define-constant MAX_SUBJECTS u10)

;; Subject constants
(define-constant SUBJECT_MATH u1)
(define-constant SUBJECT_SCIENCE u2)
(define-constant SUBJECT_ENGLISH u3)
(define-constant SUBJECT_HISTORY u4)
(define-constant SUBJECT_PHYSICS u5)
(define-constant SUBJECT_CHEMISTRY u6)
(define-constant SUBJECT_BIOLOGY u7)
(define-constant SUBJECT_LITERATURE u8)
(define-constant SUBJECT_ECONOMICS u9)
(define-constant SUBJECT_COMPUTER_SCIENCE u10)

;; data vars
(define-data-var student-counter uint u0)
(define-data-var exam-session-counter uint u0)
(define-data-var system-enabled bool true)
(define-data-var minimum-subjects-required uint u3)

;; data maps
(define-map students
  { student-id: uint }
  {
    student-address: principal,
    full-name: (string-ascii 100),
    institution: (string-ascii 100),
    registration-date: uint,
    is-verified: bool,
    total-exams-taken: uint,
    current-gpa: uint,
    is-scholarship-eligible: bool
  }
)

(define-map student-addresses
  { address: principal }
  { student-id: uint }
)

(define-map exam-scores
  { student-id: uint, subject: uint, session: uint }
  {
    score: uint,
    exam-date: uint,
    verified-by: principal,
    is-final: bool,
    weight: uint
  }
)

(define-map authorized-institutions
  { institution: principal }
  {
    is-authorized: bool,
    institution-name: (string-ascii 100),
    authorized-date: uint,
    total-students: uint
  }
)

(define-map subject-requirements
  { subject: uint }
  {
    minimum-score: uint,
    is-required: bool,
    weight-factor: uint,
    subject-name: (string-ascii 50)
  }
)

(define-map exam-sessions
  { session-id: uint }
  {
    session-name: (string-ascii 100),
    start-date: uint,
    end-date: uint,
    is-active: bool,
    total-participants: uint
  }
)

(define-map student-qualification-status
  { student-id: uint }
  {
    subjects-passed: (list 10 uint),
    subjects-failed: (list 10 uint),
    overall-average: uint,
    qualification-date: (optional uint),
    is-qualified: bool
  }
)

;; private functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER)
)

(define-private (is-authorized-institution (institution principal))
  (default-to false
    (get is-authorized (map-get? authorized-institutions { institution: institution }))
  )
)

(define-private (is-valid-subject (subject uint))
  (and (>= subject SUBJECT_MATH) (<= subject SUBJECT_COMPUTER_SCIENCE))
)

(define-private (is-valid-score (score uint))
  (and (>= score u0) (<= score MAX_SCORE))
)

(define-private (calculate-gpa (student-id uint))
  (let
    (
      (student-data (unwrap! (map-get? students { student-id: student-id }) u0))
    )
    ;; Simplified GPA calculation - in real implementation would iterate through all subjects
    ;; For now, return a basic calculation based on exam count and average performance
    (let
      (
        (total-exams (get total-exams-taken student-data))
      )
      (if (> total-exams u0)
        u300 ;; Default 3.0 GPA for demo
        u0
      )
    )
  )
)

(define-private (increment-student-counter)
  (let ((current-counter (var-get student-counter)))
    (var-set student-counter (+ current-counter u1))
    current-counter
  )
)

(define-private (increment-exam-session-counter)
  (let ((current-counter (var-get exam-session-counter)))
    (var-set exam-session-counter (+ current-counter u1))
    current-counter
  )
)

(define-private (update-qualification-status (student-id uint))
  (let
    (
      (gpa (calculate-gpa student-id))
      (student-data (unwrap! (map-get? students { student-id: student-id }) false))
    )
    ;; Check if student meets minimum requirements
    (let
      (
        (is-qualified (and (>= gpa MIN_GPA) (>= (get total-exams-taken student-data) (var-get minimum-subjects-required))))
      )
      (map-set student-qualification-status
        { student-id: student-id }
        {
          subjects-passed: (list),
          subjects-failed: (list),
          overall-average: gpa,
          qualification-date: (if is-qualified (some stacks-block-height) none),
          is-qualified: is-qualified
        }
      )
      
      ;; Update student record
      (map-set students
        { student-id: student-id }
        (merge student-data
          {
            current-gpa: gpa,
            is-scholarship-eligible: is-qualified
          }
        )
      )
      
      is-qualified
    )
  )
)

;; public functions
(define-public (authorize-institution (institution principal) (institution-name (string-ascii 100)))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (map-set authorized-institutions
      { institution: institution }
      {
        is-authorized: true,
        institution-name: institution-name,
        authorized-date: stacks-block-height,
        total-students: u0
      }
    )
    (ok true)
  )
)

(define-public (register-student (full-name (string-ascii 100)) (institution (string-ascii 100)))
  (let
    (
      (student-id (increment-student-counter))
    )
    (asserts! (var-get system-enabled) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? student-addresses { address: tx-sender })) ERR_STUDENT_EXISTS)
    
    ;; Create student record
    (map-set students
      { student-id: student-id }
      {
        student-address: tx-sender,
        full-name: full-name,
        institution: institution,
        registration-date: stacks-block-height,
        is-verified: false,
        total-exams-taken: u0,
        current-gpa: u0,
        is-scholarship-eligible: false
      }
    )
    
    ;; Create address mapping
    (map-set student-addresses
      { address: tx-sender }
      { student-id: student-id }
    )
    
    (ok student-id)
  )
)

(define-public (submit-exam-score (student-id uint) (subject uint) (session uint) (score uint))
  (begin
    (asserts! (is-authorized-institution tx-sender) ERR_INSTITUTION_NOT_AUTHORIZED)
    (asserts! (is-some (map-get? students { student-id: student-id })) ERR_STUDENT_NOT_FOUND)
    (asserts! (is-valid-subject subject) ERR_INVALID_SUBJECT)
    (asserts! (is-valid-score score) ERR_INVALID_SCORE)
    
    ;; Record exam score
    (map-set exam-scores
      { student-id: student-id, subject: subject, session: session }
      {
        score: score,
        exam-date: stacks-block-height,
        verified-by: tx-sender,
        is-final: true,
        weight: u1
      }
    )
    
    ;; Update student exam count
    (let
      (
        (student-data (unwrap! (map-get? students { student-id: student-id }) ERR_STUDENT_NOT_FOUND))
      )
      (map-set students
        { student-id: student-id }
        (merge student-data
          { total-exams-taken: (+ (get total-exams-taken student-data) u1) }
        )
      )
    )
    
    ;; Update qualification status
    (update-qualification-status student-id)
    
    (ok true)
  )
)

(define-public (verify-student (student-id uint))
  (let
    (
      (student-data (unwrap! (map-get? students { student-id: student-id }) ERR_STUDENT_NOT_FOUND))
    )
    (asserts! (is-authorized-institution tx-sender) ERR_INSTITUTION_NOT_AUTHORIZED)
    
    (map-set students
      { student-id: student-id }
      (merge student-data { is-verified: true })
    )
    
    (ok true)
  )
)

(define-public (create-exam-session (session-name (string-ascii 100)) (duration-blocks uint))
  (let
    (
      (session-id (increment-exam-session-counter))
      (end-date (+ stacks-block-height duration-blocks))
    )
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    
    (map-set exam-sessions
      { session-id: session-id }
      {
        session-name: session-name,
        start-date: stacks-block-height,
        end-date: end-date,
        is-active: true,
        total-participants: u0
      }
    )
    
    (ok session-id)
  )
)

(define-public (set-subject-requirements (subject uint) (minimum-score uint) (is-required bool))
  (begin
    (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
    (asserts! (is-valid-subject subject) ERR_INVALID_SUBJECT)
    
    (map-set subject-requirements
      { subject: subject }
      {
        minimum-score: minimum-score,
        is-required: is-required,
        weight-factor: u1,
        subject-name: "Subject"
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
(define-read-only (get-student-info (student-id uint))
  (map-get? students { student-id: student-id })
)

(define-read-only (get-student-by-address (address principal))
  (match (map-get? student-addresses { address: address })
    address-data (get-student-info (get student-id address-data))
    none
  )
)

(define-read-only (get-exam-score (student-id uint) (subject uint) (session uint))
  (map-get? exam-scores { student-id: student-id, subject: subject, session: session })
)

(define-read-only (get-qualification-status (student-id uint))
  (map-get? student-qualification-status { student-id: student-id })
)

(define-read-only (is-student-qualified (student-id uint))
  (match (get-qualification-status student-id)
    status (get is-qualified status)
    false
  )
)

(define-read-only (get-institution-info (institution principal))
  (map-get? authorized-institutions { institution: institution })
)

(define-read-only (get-subject-requirements-info (subject uint))
  (map-get? subject-requirements { subject: subject })
)

(define-read-only (get-exam-session (session-id uint))
  (map-get? exam-sessions { session-id: session-id })
)

(define-read-only (get-student-counter)
  (var-get student-counter)
)

(define-read-only (get-system-stats)
  {
    total-students: (var-get student-counter),
    total-exam-sessions: (var-get exam-session-counter),
    minimum-subjects-required: (var-get minimum-subjects-required),
    system-enabled: (var-get system-enabled),
    current-block: stacks-block-height
  }
)

(define-read-only (get-student-academic-summary (student-id uint))
  (match (get-student-info student-id)
    student
    (match (get-qualification-status student-id)
      qualification
      {
        student-id: student-id,
        full-name: (get full-name student),
        institution: (get institution student),
        total-exams: (get total-exams-taken student),
        current-gpa: (get current-gpa student),
        is-eligible: (get is-scholarship-eligible student),
        is-verified: (get is-verified student),
        qualification-date: (get qualification-date qualification)
      }
      {
        student-id: student-id,
        full-name: (get full-name student),
        institution: (get institution student),
        total-exams: (get total-exams-taken student),
        current-gpa: (get current-gpa student),
        is-eligible: (get is-scholarship-eligible student),
        is-verified: (get is-verified student),
        qualification-date: none
      }
    )
    {
      student-id: u0,
      full-name: "",
      institution: "",
      total-exams: u0,
      current-gpa: u0,
      is-eligible: false,
      is-verified: false,
      qualification-date: none
    }
  )
)

(define-read-only (get-contract-owner)
  CONTRACT_OWNER
)
