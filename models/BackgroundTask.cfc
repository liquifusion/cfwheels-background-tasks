<cfcomponent extends="models.Model" output="false">
	<cffunction name="init" output="false">
	</cffunction>

	<cffunction name="logError" returntype="boolean" hint="Logs error for failed task. If this attemp exceeds the maximum number of attempts, also records a timestamp in `failedAt`. Returns whether or not logging was successful." output="false">
		<cfargument name="error" required="true" hint="Error to log as JSON.">
		<cfscript>
			this.attempts++;
			this.lastError = SerializeJson(arguments.error);
			this.runAt = DateAdd("n", 5, Now());
			this.lockedAt = "";

			if (this.attempts == application.backgroundTasks.MAX_NUM_ERRORS) {
				this.failedAt = Now();
			}

			return this.save();
		</cfscript>
	</cffunction>
</cfcomponent>
