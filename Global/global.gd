extends Node

var arbitrary_value: int = 0  # Your arbitrary value—tweak initial value as needed
# Optional: Add a function for boosting if you want logic (e.g., caps or events)
func boost_value(amount: int) -> void:
	arbitrary_value += amount
	print("Boosted value to: ", arbitrary_value)  # Debug print; remove later
