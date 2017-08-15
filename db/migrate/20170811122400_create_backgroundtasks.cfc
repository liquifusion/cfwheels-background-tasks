<cfcomponent extends="plugins.dbmigrate.Migration" output="false">
	<cffunction name="up" output="false">
		<cfscript>
			t = createTable(name="backgroundtasks");
			t.integer(columnNames="priority,attempts", null=false, default=0);
			t.text(columnNames="handler", null=false);
			t.text("params,lasterror");
			t.timestamp(columnNames="runat", null=false);
			t.timestamp("lockedat,failedat");
			t.timestamp("createdat,updatedat", null=false);
			t.create();
		</cfscript>
	</cffunction>

	<cffunction name="down" output="false">
		<cfset dropTable("backgroundtasks")>
	</cffunction>
</cfcomponent>
