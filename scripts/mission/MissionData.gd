class_name MissionData
## BizTown — Sprint 2: Chapter 1 missions as plain DATA.
## The Mission Engine only READS this list. To add or change a mission, edit here —
## no code changes needed. (Chapter 1 only: "Save My First Shop".)
##
## Each mission:
##   id          unique key
##   title       short name
##   description the situation (felt)
##   objective   what to do (shown to the player)
##   condition   { type, value } — checked against GameState (see MissionManager)
##   reward      { cash?, reputation?, unlock?, message? } — all optional
##   next        id of the following mission ("" = end of chapter)
##
## Supported condition types:
##   cash_at_least, inventory_at_most, inventory_at_least, reputation_at_least,
##   ravi_hired, shop_expanded, day_at_least, customers_served_at_least

static func chapter_1() -> Array:
	return [
		{
			"id": "opening_day",
			"title": "Opening Day",
			"description": "Nobody knows your shop yet. Open the doors and make your first sales.",
			"objective": "Set your price and serve your first 20 customers.",
			"condition": { "type": "customers_served_at_least", "value": 20 },
			"reward": { "message": "Your shop is officially open for business!" },
			"next": "running_out_of_stock",
		},
		{
			"id": "running_out_of_stock",
			"title": "Running Out of Stock",
			"description": "Soap is flying off the shelf and you are nearly empty.",
			"objective": "Restock to at least 60 units before customers leave.",
			"condition": { "type": "inventory_at_least", "value": 60 },
			"reward": { "message": "Shelves full again. Customers stay happy." },
			"next": "the_long_queue",
		},
		{
			"id": "the_long_queue",
			"title": "The Long Queue",
			"description": "There are more customers than you can serve alone.",
			"objective": "Hire Ravi to handle the crowd.",
			"condition": { "type": "ravi_hired", "value": true },
			"reward": { "reputation": 5.0, "message": "Ravi joins the shop. It now runs beyond just you." },
			"next": "month_end",
		},
		{
			"id": "month_end",
			"title": "Month-End",
			"description": "Rent and wages are due. Can your shop survive its first month?",
			"objective": "Keep trading until Month-End (day %d)." % SimConfig.MONTH_LENGTH_DAYS,
			"condition": { "type": "day_at_least", "value": SimConfig.MONTH_LENGTH_DAYS },
			"reward": { "message": "You survived your first month in business." },
			"next": "the_shop_next_door",
		},
		{
			"id": "the_shop_next_door",
			"title": "The Shop Next Door",
			"description": "The shop next door is available. Doubling your space takes real money.",
			"objective": "Make the call: expand into the shop next door.",
			"condition": { "type": "shop_expanded", "value": true },
			"reward": { "unlock": "bigger_shop", "message": "You built your first successful business!" },
			"next": "",
		},
	]
