<cfcomponent output="false">
	<cffunction name="init" output="false">
		<cfargument name="id" type="uuid" required="true">
		<cfargument name="controller" required="true">
		<cfargument name="params" type="struct" required="false" default="#StructNew()#">

		<cfset this.id = arguments.id>
		<cfset this.controller = arguments.controller>
		<cfset variables.params = arguments.params>

		<cfreturn this>
	</cffunction>

	<cffunction name="perform" output="false">
		<cfthrow
			type="BackgroundTasks.AbstractPerformError"
			message="Your task CFC must implement a method named `perform`."
			extendedinfo="The `perform` method can use `this.controller` and `this.params` to do its work."
		>
	</cffunction>
</cfcomponent>
