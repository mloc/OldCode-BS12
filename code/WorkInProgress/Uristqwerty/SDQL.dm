
//Structured Datum Query Language. Basically SQL meets BYOND objects.

//Note: For use in BS12, need text_starts_with proc, and to modify the action on select to use BS12's object edit command(s).

/client/verb/SDQL_query(query_text as message)
	var/list/whitespace = list(" ", "\n", "\t")

	var/i
	var/word = ""
	var/len = length(query_text)
	var/list/query_list = list()

	for(i = 1, i <= len, i++)
		var/char = copytext(query_text, i, i + 1)

		if(char in whitespace)
			if(word != "")
				query_list += word
				word = ""

		else if(char == "'")
			if(word != "")
				var/j = i
				for(j, j <= len && !(copytext(query_text, j, j + 1) in whitespace), j++)
					word += copytext(query_text, j, j + 1)

				usr << "Unexpected ' in \"[word]\", in query \"[query_text]\". Please check your syntax and try again."
				return

			for(i++, i <= len, i++)
				char = copytext(query_text, i, i + 1)
				if(char == "'")
					if(copytext(query_text, i + 1, i + 2) == "'")
						word += "'"
						i++
					else
						break
				else
					word += char

			query_list += "'[word]'"
			word = ""

		else if(char == ",")
			if(word != "")
				query_list += word
				word = ""

			query_list += char


		else if(0)
			//Should split on operator => text and text => operator here. Or really, just add operators directly at this point.

		else
			word += char



		if(i == len && word != "")
			query_list += word

	if(query_list.len < 2)
		if(query_list.len > 0)
			usr << "Too few discrete tokens in query \"[query_text]\". Please check your syntax and try again."
		return

	if(!(lowertext(query_list[1]) in list("select", "delete", "update")))
		usr << "Unknown query type: \"[query_list[1]]\" in query \"[query_text]\". Please check your syntax and try again."
		return

	var/list/types = list()

	for(i = 2; i <= query_list.len; i += 2)
		types += query_list[i]

		if(i + 1 >= query_list.len || query_list[i + 1] != ",")
			break

	i++

	var/list/from = list()

	if(i <= query_list.len)
		if(lowertext(query_list[i]) in list("from", "in"))
			for(i++; i <= query_list.len; i += 2)
				from += query_list[i]

				if(i + 1 >= query_list.len || query_list[i + 1] != ",")
					break

			i++

	if(from.len < 1)
		from += "world"

	var/list/set_vars = list()

	if(lowertext(query_list[1]) == "update")
		if(i <= query_list.len && lowertext(query_list[i]) == "set")
			for(i++; i <= query_list.len; i++)
				if(i + 2 <= query_list.len && query_list[i + 1] == "=")
					set_vars += query_list[i]
					set_vars[query_list[i]] = query_list[i + 2]

				else
					usr << "Invalid set parameter in query \"[query_text]\". Please check your syntax and try again."
					return

				i += 3

				if(i >= query_list.len || query_list[i] != ",")
					break

		if(set_vars.len < 1)
			usr << "Invalid or missing set in query \"[query_text]\". Please check your syntax and try again."
			return

		i++

	var/list/where = list()

	if(i <= query_list.len && lowertext(query_list[i]) == "where")
		where = query_list.Copy(i + 1)

	var/list/from_objs = list()
	if("world" in from)
		from_objs += world
	else
		for(var/f in from)
			if(copytext(f, 1, 2) == "'")
				from_objs += locate(copytext(f, 2, length(f)))
			else if(copytext(f, 1, 2) != "/")
				from_objs += locate(f)
			else
				if(text_starts_with(f, "/mob"))
					for(var/mob/m in world)
						if(istype(m, text2path(f)))
							from_objs += m

				else if(text_starts_with(f, "/turf/space"))
					for(var/turf/space/m in world)
						if(istype(m, text2path(f)))
							from_objs += m

				else if(text_starts_with(f, "/turf/simulated"))
					for(var/turf/simulated/m in world)
						if(istype(m, text2path(f)))
							from_objs += m

				else if(text_starts_with(f, "/turf/unsimulated"))
					for(var/turf/unsimulated/m in world)
						if(istype(m, text2path(f)))
							from_objs += m

				else if(text_starts_with(f, "/turf"))
					for(var/turf/m in world)
						if(istype(m, text2path(f)))
							from_objs += m

				else if(text_starts_with(f, "/area"))
					for(var/area/m in world)
						if(istype(m, text2path(f)))
							from_objs += m

				else if(text_starts_with(f, "/obj/item"))
					for(var/obj/item/m in world)
						if(istype(m, text2path(f)))
							from_objs += m

				else if(text_starts_with(f, "/obj/machinery"))
					for(var/obj/machinery/m in world)
						if(istype(m, text2path(f)))
							from_objs += m

				else if(text_starts_with(f, "/obj"))
					for(var/obj/m in world)
						if(istype(m, text2path(f)))
							from_objs += m

				else if(text_starts_with(f, "/atom"))
					for(var/atom/m in world)
						if(istype(m, text2path(f)))
							from_objs += m
/*
				else
					for(var/datum/m in world)
						if(istype(m, text2path(f)))
							from_objs += m
*/

	var/list/objs = list()

	for(var/from_obj in from_objs)
		if("*" in types)
			objs += from_obj:contents
		else
			for(var/f in types)
				if(copytext(f, 1, 2) == "'")
					objs += locate(copytext(f, 2, length(f))) in from_obj
				else if(copytext(f, 1, 2) != "/")
					objs += locate(f) in from_obj
				else
					if(text_starts_with(f, "/mob"))
						for(var/mob/m in from_obj)
							if(istype(m, text2path(f)))
								objs += m

					else if(text_starts_with(f, "/turf/space"))
						for(var/turf/space/m in from_obj)
							if(istype(m, text2path(f)))
								objs += m

					else if(text_starts_with(f, "/turf/simulated"))
						for(var/turf/simulated/m in from_obj)
							if(istype(m, text2path(f)))
								objs += m

					else if(text_starts_with(f, "/turf/unsimulated"))
						for(var/turf/unsimulated/m in from_obj)
							if(istype(m, text2path(f)))
								objs += m

					else if(text_starts_with(f, "/turf"))
						for(var/turf/m in from_obj)
							if(istype(m, text2path(f)))
								objs += m

					else if(text_starts_with(f, "/area"))
						for(var/area/m in from_obj)
							if(istype(m, text2path(f)))
								objs += m

					else if(text_starts_with(f, "/obj/item"))
						for(var/obj/item/m in from_obj)
							if(istype(m, text2path(f)))
								objs += m

					else if(text_starts_with(f, "/obj/machinery"))
						for(var/obj/machinery/m in from_obj)
							if(istype(m, text2path(f)))
								objs += m

					else if(text_starts_with(f, "/obj"))
						for(var/obj/m in from_obj)
							if(istype(m, text2path(f)))
								objs += m

					else if(text_starts_with(f, "/atom"))
						for(var/atom/m in from_obj)
							if(istype(m, text2path(f)))
								objs += m

					else
						for(var/datum/m in from_obj)
							if(istype(m, text2path(f)))
								objs += m


	for(var/datum/t in objs)
		var/currently_false = 0
		for(i = 1, i - 1 < where.len, i++)
			var/v = where[i++]
			var/compare_op = where[i++]
			if(!(compare_op in list("==", "=", "<>", "<", ">", "<=", ">=", "!=")))
				usr << "Unknown comparison operator [compare_op] in where clause following [v] in query \"[query_text]\". Please check your syntax and try again."
				return

			var/j
			for(j = i, j <= where.len, j++)
				if(lowertext(where[j]) in list("and", "or", ";"))
					break

			if(!currently_false)
				var/value = (v in t.vars)? t.vars[v] : null
				var/result = SDQL_evaluate(t, where.Copy(i, j))

				switch(compare_op)
					if("=", "==")
						currently_false = !(value == result)

					if("!=", "<>")
						currently_false = !(value != result)

					if("<")
						currently_false = !(value < result)

					if(">")
						currently_false = !(value > result)

					if("<=")
						currently_false = !(value <= result)

					if(">=")
						currently_false = !(value >= result)


			if(j > where.len || lowertext(where[j]) == ";")
				break
			else if(lowertext(where[j]) == "or")
				if(currently_false)
					currently_false = 0
				else
					break

			i = j + 1

		if(currently_false)
			objs -= t



	usr << "Query: [query_text]"
/*
	for(var/t in types)
		usr << "Type: [t]"

	for(var/t in from)
		usr << "From: [t]"

	for(var/t in set_vars)
		usr << "Set: [t] = [set_vars[t]]"

	if(where.len)
		var/where_str = ""
		for(var/t in where)
			where_str += "[t] "

		usr << "Where: [where_str]"

	usr << "From objects:"
	for(var/datum/t in from_objs)
		usr << t

	usr << "Objects:"
	for(var/datum/t in objs)
		usr << t
*/
	switch(lowertext(query_list[1]))
		if("delete")
			for(var/datum/t in objs)
				del t

		if("update")
			for(var/datum/t in objs)
				for(var/v in set_vars)
					t.vars[v] = SDQL_text2value(t, set_vars[v])

		if("select")
			var/text = ""
			for(var/datum/t in objs)
				//text += "<a href='?src=\ref[t];action=editvars'>[t]</a><br>"
				text += "[t]<br>"
			usr << browse(text, "window=sdql_result")


/proc/SDQL_evaluate(datum/object, list/equation)
	if(equation.len == 1)
		return SDQL_text2value(object, equation[1])
	else
		usr << "Sorry, equations not yet supported :("
		return null


/proc/SDQL_text2value(datum/object, text)
	if(text2num(text) != null)
		return text2num(text)
	else if(text == "null")
		return null
	else if(copytext(text, 1, 2) == "'")
		return copytext(text, 2, length(text))
	else if(copytext(text, 1, 2) == "/")
		return text2path(text)
	else
		return object.vars[text]


/proc/text_starts_with(text, start)
	if(copytext(text, 1, length(start) + 1) == start)
		return 1
	else
		return 0

