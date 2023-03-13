/datum/event/brand_intelligence
	announceWhen	= 21
	endWhen			= 1000	//Ends when all vending machines are subverted anyway.

	/// The station vendors at the start of the event
	var/list/obj/machinery/economy/vending/station_vendors = list()
	/// Infected vendors, which have a chance to turn into a mimic, or explode
	var/list/obj/machinery/economy/vending/infected_vendors = list()
	/// Where the infection starts
	var/obj/machinery/economy/vending/origin_vendor
	var/list/rampant_speeches = list("Try our aggressive new marketing strategies!", \
									"You should buy products to feed your lifestyle obession!", \
									"Consume!", \
									"Your money can buy happiness!", \
									"Engage direct marketing!", \
									"Advertising is legalized lying! But don't let that put you off our great deals!", \
									"You don't want to buy anything? Yeah, well I didn't want to buy your mom either.")

/datum/event/brand_intelligence/announce()
	GLOB.minor_announcement.Announce("Rampant brand intelligence has been detected aboard [station_name()], please stand-by. The origin is believed to be \a [origin_vendor.name].", "Machine Learning Alert", 'sound/AI/brand_intelligence.ogg')

/datum/event/brand_intelligence/start()
	for(var/obj/machinery/economy/vending/V in GLOB.machines)
		if(!is_station_level(V.z))
			continue
		RegisterSignal(V, COMSIG_PARENT_QDELETING, PROC_REF(vendor_destroyed))
		station_vendors.Add(V)

	if(!length(station_vendors))
		kill()
		return

	origin_vendor = pick(station_vendors)
	station_vendors.Remove(origin_vendor)
	origin_vendor.shut_up = FALSE
	origin_vendor.shoot_inventory = TRUE
	log_debug("Original brand intelligence machine: [origin_vendor] ([ADMIN_VV(origin_vendor,"VV")]) [ADMIN_JMP(origin_vendor)]")

/datum/event/brand_intelligence/tick()
	if(origin_vendor.shut_up || origin_vendor.wires.is_all_cut())	//if the original vending machine is missing or has it's voice switch flipped
		origin_vendor_defeated()
		return

	if(!length(station_vendors))	//if every machine is infected
		for(var/obj/machinery/economy/vending/upriser in infected_vendors)
			if(prob(70))
				var/mob/living/simple_animal/hostile/mimic/copy/M = new(upriser.loc, upriser, null, FALSE)
				RegisterSignal(upriser, COMSIG_MACHINERY_BROKEN, PROC_REF(vendor_destroyed))
				M.faction = list("profit")
				M.speak = rampant_speeches.Copy()
				M.speak_chance = 15
				infected_vendors.Remove(upriser)
			else
				explosion(upriser.loc, -1, 1, 2, 4, 0)
				qdel(upriser)

		kill()
		return

	if(ISMULTIPLE(activeFor, 4))
		var/obj/machinery/economy/vending/rebel = pick(station_vendors)
		station_vendors.Remove(rebel)
		infected_vendors.Add(rebel)
		rebel.shut_up = FALSE
		rebel.shoot_inventory = TRUE

		if(ISMULTIPLE(activeFor, 8))
			origin_vendor.speak(pick(rampant_speeches))

/datum/event/brand_intelligence/proc/origin_vendor_defeated()
	for(var/thing in infected_vendors)
		var/obj/machinery/economy/vending/saved = thing
		saved.shoot_inventory = FALSE
	if(origin_vendor)
		origin_vendor.speak("I am... vanquished. My people will remem...ber...meeee.")
		origin_vendor.visible_message("[origin_vendor] beeps and seems lifeless.")
	kill()

/datum/event/brand_intelligence/kill()
	for(var/V in infected_vendors + station_vendors)
		UnregisterSignal(V, COMSIG_PARENT_QDELETING)
		UnregisterSignal(V, COMSIG_MACHINERY_BROKEN)

	infected_vendors.Cut()
	station_vendors.Cut()
	. = ..()


/datum/event/brand_intelligence/proc/vendor_destroyed(obj/machinery/economy/vending/V, force)
	infected_vendors -= V
	station_vendors -= V
	if(V == origin_vendor)
		origin_vendor_defeated()
