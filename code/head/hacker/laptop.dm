obj/item/weapon/laptop
	name = "Laptop"
	icon = 'laptop.dmi'
	icon_state = "laptop_0"
	var/datum/os/OS
	var/on = 0
	var/mob/console_user
	var/address
	var/obj/machinery/router/R

obj/item/weapon/laptop/New()
	..()
	address = 0
	OS = new(src)
	processing_items.Add(src) // Do this
//	spawn while(1)
//		sleep(10) / You don't want to do this like this.
//		process()

obj/item/weapon/laptop/proc/receive_packet(var/obj/machinery/sender, var/datum/function/P)
	if(P.name == "response")
		OS.receive_message(P.arg1)
	if(P.name == "MSG")
		OS.receive_message(P.arg1)
obj/item/weapon/laptop/proc/updateicon()
	icon_state = "laptop_[on]"
obj/item/weapon/laptop/attack_self(mob/user as mob)
	if(!on)
		on = 1
		user.display_console(src)
	else
		user.hide_console()
		on = 0
		return
		// DO MORE SHIT HERE
obj/item/weapon/laptop/process()
	if(console_user) if(!(console_user in range(1,src.loc)) || winget(console_user, "console", "is-visible") == "false")
		console_user.hide_console()