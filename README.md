# CFWheels Background Tasks

Database-based asynchronous priority queue system for CFWheels apps

If you have intensive data processing or blocking calls to 3rd party APIs, you should consider moving that
functionality into this background queue system. Rather than forcing the user to wait 15 minutes for your
slow script to run, it can be placed in this queue to be processed asynchronously "in the background."

Each background task is represented by a separate CFC in a new `tasks` folder in your CFWheels application.
(See _Usage_ section below.)

If an error occurs while a task is being processed, it will be logged in the database and retried in 10
minutes. This is useful if your application integrates with an unreliable API. (Aren't they all?)

## Installation

First, place the `BackgroundTasks-0.1.1.zip` file from this repository's Releases tab in your application's
`plugins` folder, then reload the app.

Next, there are a few other points of configuration in your database, application, and scheduled tasks.

### Database Setup

If you are running database migrations through CFWheels 2+ or the DBMigrate plugin, copy the file(s) from this
plugin's `db/migrate` folder into your app's `db/migrate/folder`.

If you are not running database migrations, create a table according to the migration file(s) in this plugin's
`db/migrate` folder.

### App Setup

Add a route to your routes file:

```javascript
// ColdRoute or CFWheels 2+ `config/routes.cfm` file:
mapper()
  .get(name="tasks", to="tasks##update")
.end();

// CFWheels 1 `config/routes.cfm` file:
addRoute(name="tasks", controller="tasks", action="update");
```

Create the controller that this route describes at `controllers/Tasks.cfc` with these contents:

```javascript
component extends="plugins.BackgroundTasks.controllers.Tasks" {}
```

Create a model hooking into the plugin's model at `models/BackgroundTask.cfc` with these contents:

```javascript
component extends="plugins.BackgroundTasks.models.BackgroundTask" {}
```

Create a file within your application at `tasks/Base.cfc` with these contents:

```javascript
component extends="plugins.BackgroundTasks.Task" {}
```

All of your background tasks will extend this new `tasks.Base` class. You can add functionality shared across
multiple tasks in here if you'd like, kind of like what you'd do in `controllers/Controller.cfc` and
`models/Model.cfc`.

### Scheduled Task Setup

In production-like environments, set up a scheduled task or CRON job to run `/tasks` at whatever interval that
you prefer. (I recommend every 10 seconds if the user will need to wait in some way for this processing to
complete.)

Every time the `/tasks` URL is hit, the next available highest-priority task will be run.

## Usage

Using the plugin is fairly straightforward. You create a CFC containing the logic for your background task
and then schedule it within your application using the `scheduleTask` method.

### Creating the Task

Create a new CFC in the `tasks` folder of your application, extending either your own `Base.cfc` or
`plugins.BackgroundTasks.Task`. Within the CFC, implement a method named `perform`:

```javascript
// tasks/SomeExpensiveApiTask.cfc
component extends="Base" {
  /**
   * This is the "entry point" for processing this background task.
   */
  function perform() {
    // All functionality available within a normal CFWheels controller is available from the
    // `this.controller` property.
    //
    // You also have the opportunity to pass in a struct of `params` when you schedule this task.
    local.widget = this.controller.model("widget").findByKey(params.id);

    // This is just custom logic below. It can be whatever you need.
    local.myApi = CreateObject("component", "lib.SomeApiWrapper").init(application.SOME_API_KEY);
    local.myApi.someExpensiveMethod(title=local.widget.title, price=local.widget.price);
  }
}
```

You can break up your functionality using any features that a CFC can provide.

### Scheduling the Task

From within your application, you can schedule this task whenever it needs to be run:

```javascript
scheduleTask(handler="SomeExpensiveApiTask", params=SerializeJson({ id=widget.key() }));
```

Depending on your requirements, you should call `scheduleTask` from within your controller or even in a
model method or callback.

#### `scheduleTask` Signature

Only `handler` is required. It can also include dot notation relative from the `tasks` folder if you want to
place your tasks into deeper subfolders.

You'll often want to provide some state into the task via the `params` argument, which takes a stringified
JSON object containing params to use within the task.

```javascript
/**
 * Schedules task in background tasks queue. Returns whether or not the task was scheduled successfully.
 *
 * @handler Name of CFC in `tasks` folder (minus the `.cfc` extension).
 * @params Struct of arguments to pass to the task, serialized as a JSON object string.
 * @priority Priority. Lower number is higher priority.
 * @runAt When to run the task.
 */
boolean function scheduleTask(
  required string handler,
  string params = "{}",
  numeric priority = 0,
  date runAt = Now()
)
```

## Configuration

I recommend tweaking these settings in `config/settings.cfm` if you need to.

### `application.backgroundTasks.MAX_LOCK_LENGTH`

`[integer]` default `300`

Tasks are locked while being processed. This sets the number of seconds that should pass before a task
is considered "unlocked" and can be tried again.

### `application.backgroundTasks.MAX_NUM_CONCURRENT_TASKS`

`[integer]` default `1`

Number of tasks that can be run concurrently. Be careful about not setting this past the number of
threads that your CFML engine can process. (Hint: CF Standard limits this.)

The default value of `1` is safest as only one task can be processed at once.

### `application.backgroundTasks.MAX_NUM_ERRORS`

`[integer]` default `25`

Maximum number of times that a task can error out before the queue considers it "failed" and stops
trying to run it. (These particular tasks will be left behind in your database so you can investigate
them.)

## Building the plugin release

Follow these steps:

1.  Update `build.sh` to have the correct version number for the release.
2.  Run `sh build.sh`

The zip file should appear containing a releaseable CFWheels plugin named `BackgroundTasks-[VERSION].zip`.

## License

MIT License

Copyright (c) 2017 Liquifusion Studios
