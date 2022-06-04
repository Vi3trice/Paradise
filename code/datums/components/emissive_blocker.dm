/datum/component/emissive_blocker
	var/list/stored_blocker

/datum/component/emissive_blocker/Initialize(_stored_blocker)
	stored_blocker = _stored_blocker
	RegisterSignal(parent, COMSIG_ATOM_UPDATE_ICON_STATE, .proc/update_generic_block)
	RegisterSignal(parent, COMSIG_ATOM_ADD_EMISSIVE_BLOCKER, .proc/add_generic_block)

/// Updates the generic blocker when the icon_state is changed
/datum/component/emissive_blocker/proc/update_generic_block(datum/source)
	var/atom/movable/A = parent
	if(!A.blocks_emissive && stored_blocker)
		A.cut_overlay(stored_blocker)
		stored_blocker = null
		return
	var/mutable_appearance/gen_emissive_blocker = emissive_blocker(A.icon, A.icon_state, alpha = A.alpha, appearance_flags = A.appearance_flags)
	gen_emissive_blocker.dir = A.dir
	if(gen_emissive_blocker != stored_blocker || !A.overlays)
		A.cut_overlay(stored_blocker)
		stored_blocker = gen_emissive_blocker
		A.add_overlay(list(gen_emissive_blocker))

/// Adds the stored blocker if overlays are updated
/datum/component/emissive_blocker/proc/add_generic_block(datum/source)
	var/atom/movable/A = parent
	if(A.blocks_emissive && stored_blocker)
		A.add_overlay(stored_blocker)
