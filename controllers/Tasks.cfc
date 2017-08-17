<cfcomponent extends="controllers.Wheels" output="false">
	<cfparam name="application.backgroundTasks.activeTasks" type="array" default="#ArrayNew(1)#">
	<cfparam name="application.backgroundTasks.MAX_LOCK_LENGTH" type="integer" default="300">
	<cfparam name="application.backgroundTasks.MAX_NUM_CONCURRENT_TASKS" type="integer" default="1">
	<cfparam name="application.backgroundTasks.MAX_NUM_ERRORS" type="integer" default="25">

	<cffunction name="update" output="false">
		<cfset var loc = {}>
		<cfset $purgeExpiredActiveTasks()>

		<cflock name="backgroundTasks" type="readonly" timeout="5">
			<cfset loc.unlockedAt = DateAdd("n", application.backgroundTasks.MAX_LOCK_LENGTH * -1, Now())>
			<cfset loc.numActiveTasks = ArrayLen(application.backgroundTasks.activeTasks)>
			<cfset loc.maxConcurrentTasks = application.backgroundTasks.MAX_NUM_CONCURRENT_TASKS>
		</cflock>

		<cfif loc.numActiveTasks gte loc.maxConcurrentTasks>
			<cfset renderNothing()>
			<cfreturn>
		</cfif>

		<cfset task = model("BackgroundTask").findOne(
			where=ArrayToList([
				"(lockedAt IS NULL OR lockedAt < '#loc.unlockedAt#')",
				"runAt <= '#Now()#'",
				"failedAt IS NULL"
			], " AND "),
			order="priority, runAt"
		)>

		<cfif IsObject(task)>
			<cfset taskIdentifier = CreateUuid()>
			<cfset task.update(lockedAt=Now())>

			<cfthread name="processBackgroundTask-#taskIdentifier#" action="run">
				<cfset params = IsJson(task.params) ? DeserializeJSON(task.params) : StructNew()>

				<cflock name="backgroundTasks" timeout="5" type="exclusive">
					<cfscript>
						if (ArrayLen(application.backgroundTasks.activeTasks) < application.backgroundTasks.MAX_NUM_CONCURRENT_TASKS) {
							ArrayAppend(application.backgroundTasks.activeTasks, {
								id=taskIdentifier,
								startedAt=Now()
							});
						}
					</cfscript>
				</cflock>

				<cftry>
					<cfset backgroundTask = CreateObject("component", "tasks.#task.handler#").init(
						id=taskIdentifier,
						controller=this,
						params=params
					)>

					<cfset backgroundTask.perform()>

					<cfcatch type="any">
						<cfset task.logError(cfcatch)>
						<cfset $purgeActiveTask(taskIdentifier)>
						<cfabort>
					</cfcatch>
				</cftry>

				<cfset task.delete()>
				<cfset $purgeActiveTask(taskIdentifier)>
			</cfthread>
		</cfif>

		<cfset renderNothing()>
	</cffunction>

	<cffunction name="$purgeActiveTask" access="private" hint="Purges a given active task from the queue." output="false">
		<cfargument name="id" type="uuid" hint="Task identifier.">

		<cflock name="backgroundTasks" type="exclusive" timeout="5">
			<cfscript>
				for (loc.i = 1; loc.i <= ArrayLen(application.backgroundTasks.activeTasks); loc.i++) {
					if (application.backgroundTasks.activeTasks[loc.i].id == arguments.id) {
						ArrayDeleteAt(application.backgroundTasks.activeTasks, loc.i);
						break;
					}
				}
			</cfscript>
		</cflock>
	</cffunction>

	<cffunction name="$purgeExpiredActiveTasks" access="private" hint="Purges active tasks that have expired." output="false">
		<cfset var loc = {}>
		<cfset loc.currentTime = Now()>

		<cflock name="backgroundTasks" type="exclusive" timeout="5">
			<cfscript>
				for (loc.i = 1; loc.i <= ArrayLen(application.backgroundTasks.activeTasks); loc.i++) {
					if (application.backgroundTasks.activeTasks[loc.i].startedAt <= dateAdd("s", application.backgroundTasks.MAX_NUM_CONCURRENT_TASKS, loc.currentTime)) {
						ArrayDeleteAt(application.backgroundTasks.activeTasks, loc.i);
					}
				}
			</cfscript>
		</cflock>
	</cffunction>
</cfcomponent>
