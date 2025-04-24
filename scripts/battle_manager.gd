extends Node

const SMALL_CARD_SCALE = 0.8
const CARD_MOVE_SPEED = 0.2
const STARTING_HEALTH = 20
const BATTLE_POS_OFFSET = 25

var battle_timer
var empty_basic_card_slots = []
var opponent_cards_on_battlefield = []
var player_cards_on_battlefield = []
var player_cards_attacked_this_turn = []
var player_health
var opponent_health
var is_opponent_turn = false
var player_is_attacking = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	empty_basic_card_slots.append($"../CardSlots/OpponentCardSlot2")
	empty_basic_card_slots.append($"../CardSlots/OpponentCardSlot3")
	empty_basic_card_slots.append($"../CardSlots/OpponentCardSlot4")
	empty_basic_card_slots.append($"../CardSlots/OpponentCardSlot5")
	empty_basic_card_slots.append($"../CardSlots/OpponentCardSlot6")
	empty_basic_card_slots.append($"../CardSlots/OpponentCardSlot7")
	
	player_health = STARTING_HEALTH
	$"../PlayerHealth".text = str(player_health)
	opponent_health = STARTING_HEALTH
	$"../OpponentHealth".text = str(opponent_health)

func _on_end_turn_button_pressed() -> void:
	is_opponent_turn = true
	$"../CardManager".unselect_selected_basic()
	player_cards_attacked_this_turn = []
	opponent_turn()
	
	
func opponent_turn():
	$"../EndTurnButton".disabled = true
	$"../EndTurnButton".visible = false
	
	# wait a moment
	await wait(1.0)
	
	if $"../OpponentDeck".opponent_deck.size() != 0:
		$"../OpponentDeck".draw_card()
		# wait a moment
		battle_timer.start()
		await battle_timer.timeout
	
	# check if free slots, if no end turn
	if empty_basic_card_slots.size() != 0:
		await try_play_card()
	
	if (opponent_cards_on_battlefield.size() != 0):
		var enemy_cards_to_attack = opponent_cards_on_battlefield.duplicate()
		for card in enemy_cards_to_attack:
			if player_cards_on_battlefield.size() == 0:
				# direct attack commander
				await direct_attack(card, "Opponent")
			else:
				var card_to_attack = player_cards_on_battlefield.pick_random()
				await attack(card, card_to_attack, "Opponent")
				
	
	# end turn
	end_opponent_turn()

func direct_attack(attacking_card, attacker):
	var new_pos_y
	if attacker == "Opponent":
		new_pos_y = 1080
	else:
		player_is_attacking = true
		$"../EndTurnButton".disabled = true
		new_pos_y = 0
		player_cards_attacked_this_turn.append(attacking_card)
	
	var new_pos = Vector2(attacking_card.position.x, new_pos_y)
	
	attacking_card.z_index = 5
	
	print("direct attack")
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	
	if attacker == "Opponent":
		#damage player
		player_health = max(player_health - attacking_card.attack, 0)
		$"../PlayerHealth".text = str(player_health)
	else:
		# damage opponent
		opponent_health = max(opponent_health - attacking_card.attack, 0)
		$"../OpponentHealth".text = str(opponent_health)
		
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_in_slot.position, CARD_MOVE_SPEED)
	attacking_card.z_index = 0
	await wait(1.0)
	
	if attacker == "Player":
		player_is_attacking = false
		$"../EndTurnButton".disabled = false
	
	
func attack(attacking_card, defending_card, attacker):
	if attacker == "Player":
		$"../EndTurnButton".disabled = true
		player_is_attacking = true
		player_cards_attacked_this_turn.append(attacking_card)
		$"../CardManager".selected_basic = null
	attacking_card.z_index = 5
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_POS_OFFSET)
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_in_slot.position, CARD_MOVE_SPEED)
	
	# deal damage to cards
	defending_card.health = max(0, defending_card.health - attacking_card.attack)
	defending_card.get_node("Health").text = str(defending_card.health)
	attacking_card.health = max(0, attacking_card.health - defending_card.attack)
	attacking_card.get_node("Health").text = str(attacking_card.health)
	
	await wait(1.0)
	attacking_card.z_index = 0
	
	var card_was_destroyed = false
	
	# destroy dead cards
	if attacking_card.health == 0:
		card_was_destroyed = true
		destroy_card(attacking_card, attacker)
	if defending_card.health == 0:
		card_was_destroyed = true
		if attacker == "Player":
			destroy_card(defending_card, "Opponent")
		else:
			destroy_card(defending_card, "Player")
		
	if card_was_destroyed:
		await wait(1.0)
		
	if attacker == "Player":
		$"../EndTurnButton".disabled = false
		player_is_attacking = false
		
func destroy_card(card, card_owner):
	# remove card from field
	# update all containers
	var new_pos
	if card_owner == "Player":
		card.defeated = true
		card.get_node("Area2D/CollisionShape2D").disabled = true
		new_pos = $"../PlayerDiscard".position
		if card in player_cards_on_battlefield:
			player_cards_on_battlefield.erase(card)
		card.card_in_slot.get_node("Area2D/CollisionShape2D").disabled = false
	else:
		new_pos = $"../OpponentDiscard".position
		if card in opponent_cards_on_battlefield:
			opponent_cards_on_battlefield.erase(card)
	
	card.card_in_slot.card_in_slot = false
	card.card_in_slot = null
	
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, CARD_MOVE_SPEED)
	
func enemy_card_selected(defending_card):
	var attacking_card = $"../CardManager".selected_basic
	if attacking_card and defending_card in opponent_cards_on_battlefield and !player_is_attacking:
		$"../CardManager".selected_basic = null
		attack(attacking_card, defending_card, "Player")
		

func try_play_card():
	# play a card
	var opponent_hand = $"../OpponentHand".opponent_hand
	if opponent_hand.size() == 0:
		end_opponent_turn()
		return
	var random_empty_basic_card_slot = empty_basic_card_slots.pick_random()
	empty_basic_card_slots.erase(random_empty_basic_card_slot)
	# temporary, play card with highest attack
	var card_with_highest_attack = opponent_hand[0]
	for card in opponent_hand:
		if card.attack > card_with_highest_attack.attack:
			card_with_highest_attack = card
	
	var tween = get_tree().create_tween()
	tween.tween_property(card_with_highest_attack, "position", random_empty_basic_card_slot.position, CARD_MOVE_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(card_with_highest_attack, "scale", Vector2(SMALL_CARD_SCALE, SMALL_CARD_SCALE), CARD_MOVE_SPEED)
	card_with_highest_attack.get_node("AnimationPlayer").play("card_flip")
	
	# remove card from opp hand
	$"../OpponentHand".remove_card_from_hand(card_with_highest_attack)
	card_with_highest_attack.card_in_slot = random_empty_basic_card_slot
	opponent_cards_on_battlefield.append(card_with_highest_attack)
	
	await wait(1.0)
	

	
func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout

func end_opponent_turn():
	# reset player deck draw and turn
	$"../Deck".reset_draw()
	$"../CardManager".reset_played_basic()
	is_opponent_turn = false
	$"../EndTurnButton".disabled = false
	$"../EndTurnButton".visible = true
