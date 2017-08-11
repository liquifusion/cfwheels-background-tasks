<cfcomponent output="false">
	<cffunction name="init" output="false">
		<cfscript>
			this.version = "1.4.5";
			return this;
		</cfscript>
	</cffunction>

	<cffunction name="scheduleTask" returntype="boolean" hint="Schedules task in background tasks queue. Returns whether or not the task was scheduled successfully." output="false">
		<cfargument name="handler" type="string" required="true" hint="Name of CFC in `tasks` folder (minus the `.cfc` extension).">
		<cfargument name="params" type="numeric" required="false" default="{}" hint="Struct of arguments to pass to the task, serialized as a JSON object string.">
		<cfargument name="priority" type="string" required="false" default="0" hint="Priority. Lower number is higher priority.">
		<cfargument name="runAt" type="date" required="false" default="#Now()#" hint="When to run the task.">
		<cfscript>
			var loc = {};

			loc.task = model("backgroundTask").new(
				handler=arguments.handler,
				params=arguments.params,
				priority=arguments.priority,
				runAt=arguments.runAt
			);

			return loc.task.save();
		</cfscript>
	</cffunction>
</cfcomponent>
