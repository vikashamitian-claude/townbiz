class_name SimConfig
## BizTown — Living Business Build: single source of truth for EVERY tunable number.
## To balance the game, edit values HERE and nothing else. (Chapter 1: one soap shop.)

# --- Starting state ---
const STARTING_CASH: float = 10000.0
const STARTING_REPUTATION: float = 50.0
const STARTING_INVENTORY: int = 40

# --- Product (Chapter 1 sells Soap only) ---
const PRODUCT_NAME: String = "Soap"
const PRODUCT_COST: float = 20.0        # baseline unit cost (drifts at runtime)
const COST_MIN: float = 16.0            # supplier cost floor
const COST_MAX: float = 26.0            # supplier cost ceiling
const COST_DRIFT: float = 0.5           # max daily random drift (± this)
const PRICE_MIN: float = 20.0
const PRICE_MAX: float = 55.0
const DEFAULT_PRICE: float = 35.0

# --- Demand curve ---
const BASE_DEMAND: float = 40.0
const FLOOR_PRICE: float = 25.0
const DEMAND_SLOPE: float = 1.12
const MAX_DEMAND: float = 45.0
const REP_BASELINE: float = 50.0
const REP_SHIFT_PER_POINT: float = 0.4

# --- Uncertainty: daily demand noise ---
const NOISE_MIN: float = 0.75
const NOISE_MAX: float = 1.25

# --- Customer mix (fractions of rolled demand) ---
const SHARE_WALK_INS: float = 0.55
const SHARE_BARGAINERS: float = 0.20
# remaining share is covered by regulars (absolute count, see below)
const BARGAIN_CEILING_BASE: float = 32.0   # at REP_BASELINE; shifts with reputation
const REGULAR_CAP: int = 40
const REGULAR_GAIN_CLEAN_DAY: int = 1
const REGULAR_LOSS_ON_TURNAWAY: int = 2

# --- Credit (trust mechanic) ---
const CREDIT_REQUEST_CHANCE: float = 0.15
const CREDIT_QTY_MIN: int = 5
const CREDIT_QTY_MAX: int = 15
const CREDIT_DUE_MIN_DAYS: int = 5
const CREDIT_DUE_MAX_DAYS: int = 10
const CREDIT_RELIABILITY_MIN: float = 0.6
const CREDIT_RELIABILITY_MAX: float = 0.95
const CREDIT_DEFAULT_PAY_FRACTION: float = 0.5
const CREDIT_REFUSE_REP_HIT: float = 0.5
const CREDIT_PAID_REP_GAIN: float = 1.0
const CREDIT_NAMES := [
	"Sharma-ji", "Meena didi", "Raju bhai", "Panda babu", "Gita mausi",
	"Bikash bhaina", "Sunita apa", "Mishra sir", "Lata bou", "Deepak nana",
]

# --- Bulk orders ---
const BULK_QTY_MIN: int = 30
const BULK_QTY_MAX: int = 60
const BULK_MARGIN_MIN: float = 4.0      # offer price = current_unit_cost + margin
const BULK_MARGIN_MAX: float = 8.0
const BULK_DEADLINE_DAYS: int = 2
const BULK_REP_PENALTY: float = 3.0

# --- Service capacity ---
const CAPACITY_SOLO: int = 25
const CAPACITY_WITH_RAVI: int = 50

# --- Player-facing stock decisions (shared by both the 2D and 3D UI) ---
const BUY_QUANTITY: int = 60    # units bought per tap of the Buy button
const LOW_STOCK: int = 18       # inventory at/below this shows the low-stock warning

# --- Costs & stakes ---
const RAVI_WAGE: float = 100.0
const RENT: float = 3000.0
const MONTH_LENGTH_DAYS: int = 30
const EXPANSION_COST: float = 8000.0
const EXPANSION_CAPACITY_MULT: float = 1.5
const EXPANSION_EXTRA_DAILY: float = 50.0

# --- Lender (no game-over; broke = harder path) ---
const LENDER_PRINCIPAL: float = 5000.0
const LENDER_REPAY: float = 6000.0
const LENDER_ROLL_PENALTY: float = 500.0
const LENDER_REP_HIT: float = 10.0

# --- Reputation ---
const REP_GAIN_GOOD_DAY: float = 1.0
const REP_LOSS_PER_LOST: float = 0.3
const REP_MAX_DAILY_DROP: float = 5.0
const REP_MIN: float = 0.0
const REP_MAX: float = 100.0

# --- Day events: weights (relative). Rolled once per day, telegraphed a day ahead. ---
const EVENT_WEIGHTS: Dictionary = {
	"none": 55,
	"festival_rush": 8,
	"heavy_rain": 8,
	"supplier_hike": 7,
	"supplier_deal": 6,
	"competitor_discount": 8,
	"bulk_order_offer": 8,
	"local_holiday": 6,
	"wedding_season": 6,
}

# --- Event effect parameters ---
const FESTIVAL_DEMAND_MULT: float = 1.6
const RAIN_DEMAND_MULT: float = 0.6
const HIKE_COST_DELTA: float = 4.0
const HIKE_DURATION_DAYS: int = 5
const DEAL_COST_DELTA: float = -5.0
const DEAL_DURATION_DAYS: int = 3
const COMPETITOR_DEMAND_MULT: float = 0.75
const COMPETITOR_DURATION_DAYS: int = 3
const HOLIDAY_DEMAND_MULT: float = 0.65      # one-day: shutters half-closed, fewer people out
const WEDDING_DEMAND_MULT: float = 1.35      # multi-day: wedding season, everyone buying soap
const WEDDING_DURATION_DAYS: int = 2

# --- Customer memory: repeat credit customers nudge toward their own history ---
const CREDIT_HISTORY_PAID_BONUS: float = 0.05      # per past on-time repayment
const CREDIT_HISTORY_DEFAULT_PENALTY: float = 0.12 # per past default
# Wider than CREDIT_RELIABILITY_MIN/MAX on purpose: those bound the fresh roll,
# these bound the roll AFTER a repeat customer's history nudges it — a serial
# defaulter must be able to actually read as untrustworthy, not snap back.
const CREDIT_RELIABILITY_HARD_MIN: float = 0.05
const CREDIT_RELIABILITY_HARD_MAX: float = 0.99
