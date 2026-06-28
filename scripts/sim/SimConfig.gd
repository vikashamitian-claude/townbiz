class_name SimConfig
## BizTown — Sprint 1: Business Simulation Engine
## Single source of truth for every tunable Chapter 1 number.
## To balance the game, edit values HERE and nothing else.
## (Chapter 1 = "Save My First Shop", one product: Soap. No other businesses yet.)

# --- Starting state ---
const STARTING_CASH: float = 10000.0
const STARTING_REPUTATION: float = 50.0
const STARTING_INVENTORY: int = 40

# --- Product (Chapter 1 sells Soap only) ---
const PRODUCT_NAME: String = "Soap"
const PRODUCT_COST: float = 20.0        # cost you pay per unit of stock
const PRICE_MIN: float = 20.0           # margin-dial lower bound
const PRICE_MAX: float = 55.0           # margin-dial upper bound
const DEFAULT_PRICE: float = 35.0

# --- Demand curve ---
# Demand falls as price rises. Higher reputation shifts the curve RIGHT
# (customers tolerate higher prices) — i.e. reputation = pricing power.
const BASE_DEMAND: float = 40.0         # customers/day at FLOOR_PRICE & REP_BASELINE
const FLOOR_PRICE: float = 25.0         # price at which BASE_DEMAND applies
const DEMAND_SLOPE: float = 1.12        # customers lost per Rs above the adjusted floor
const MAX_DEMAND: float = 45.0          # cap so very low prices don't explode demand
const REP_BASELINE: float = 50.0        # reputation level with zero pricing-power shift
const REP_SHIFT_PER_POINT: float = 0.4  # Rs of extra price tolerated per reputation point

# --- Service capacity (this is what makes "Hire Ravi" matter) ---
const CAPACITY_SOLO: int = 25           # customers/day you can serve alone
const CAPACITY_WITH_RAVI: int = 50      # ...with Ravi helping

# --- Costs ---
const RAVI_WAGE: float = 100.0          # per day, once hired (a recurring daily cost)
const RENT: float = 3000.0              # per month (charged at Month-End)
const MONTH_LENGTH_DAYS: int = 30       # days between Month-End rent charges (timing reference only)

# --- Reputation modifiers (kept gentle; profit is NEVER punished) ---
const REP_GAIN_GOOD_DAY: float = 1.0    # served everyone, turned no one away
const REP_LOSS_PER_LOST: float = 0.3    # per customer turned away (long queue / stockout)
const REP_MAX_DAILY_DROP: float = 5.0   # cap on reputation lost in a single day
const REP_MIN: float = 0.0
const REP_MAX: float = 100.0
