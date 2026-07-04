class_name BusinessType
extends Resource
## BizTown — foundation for multiple business paths (see HUMAN_DECISIONS.md,
## "multi-business 3D world" direction). Pure DATA, no logic — describes a
## business's identity and Chapter-1-scale starting conditions.
##
## Deliberately NOT a replacement for SimConfig.gd's tuned demand-curve/
## capacity/event formulas — those stay Chapter-1-specific until a second
## business path is actually playable. This resource generalizes only the
## identity layer (name/sign/flavor) and starting-condition numbers, so
## swapping a business's THEME is provably possible without touching the
## tuned simulation math.
##
## Built via property assignment (see BusinessRegistry.gd), not a long
## positional constructor — too easy to silently swap two values in a
## 12-argument call.

var id: String
var display_name: String
var product_name: String
var shop_sign_text: String
var expanded_sign_text: String
var tagline: String
var starting_cash: float
var starting_inventory: int
var product_cost: float
var price_min: float
var price_max: float
var customer_names: Array
