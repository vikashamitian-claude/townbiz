class_name MissionData
## BizTown — Living Business Build: missions as plain data.
## Condition types understood by MissionManager:
##   customers_served_total {value}    — lifetime served ≥ value
##   inventory_at_least {value}        — current stock ≥ value
##   ravi_hired {}                     — Ravi on payroll
##   cash_at_least_on_day {day,value}  — on day `day`, cash ≥ value (checked at day_ended)
##   shop_expanded {}                  — expansion bought (costs real money now)
## `check_on`: which explicit Sim events may complete this mission.

static func chapter_1() -> Array:
	return [
		{
			"id": "opening_day",
			"title": "Opening Day",
			"intro": "Your shop is stocked with 40 soaps. Set a price and open the shutter. The town doesn't know you yet — and no two days are ever the same.",
			"conditions": [ { "type": "customers_served_total", "value": 20 } ],
			"check_on": ["day_ended"],
			"debrief": "Twenty customers found your shop. Some days the street is full, some days it rains — that's business.",
		},
		{
			"id": "restock",
			"title": "Running Out of Stock",
			"intro": "Shelves are emptying. The supplier's price moves every day — watch it, and buy back up to 60 units when the moment feels right.",
			"conditions": [ { "type": "inventory_at_least", "value": 60 } ],
			"check_on": ["inventory_purchased"],
			"debrief": "Stock is money on a shelf. Buy cheap, and it works for you. Buy dear, and it eats your margin.",
		},
		{
			"id": "long_queue",
			"title": "The Long Queue",
			"intro": "You can only serve 25 people a day alone — and every person turned away tells two friends. Ravi is looking for work at ₹100/day.",
			"conditions": [ { "type": "ravi_hired" } ],
			"check_on": ["ravi_hired"],
			"debrief": "Ravi doubles your hands. His wage now leaves your pocket every single day — make him worth it.",
		},
		{
			"id": "month_end",
			"title": "Month-End",
			"intro": "Day 30 is coming. ₹3,000 rent leaves your drawer whether you sold well or not. Reach month-end with the rent paid and your head above water.",
			"conditions": [ { "type": "cash_at_least_on_day", "day": 30, "value": 0.0 } ],
			"check_on": ["day_ended", "month_ended"],
			"debrief": "Rent paid, doors open. Most shops don't survive their first month-end. Yours did.",
		},
		{
			"id": "shop_next_door",
			"title": "The Shop Next Door",
			"intro": "The shop beside yours has closed down. The landlord wants ₹8,000 — real money, from your drawer — to knock the wall through. Bigger shop, bigger bills.",
			"conditions": [ { "type": "shop_expanded" } ],
			"check_on": ["shop_expanded"],
			"debrief": "You put your own profit back into the business. That's the difference between a shopkeeper and a businessman. Chapter 1 complete.",
		},
	]
