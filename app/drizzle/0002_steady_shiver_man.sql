CREATE TABLE `prediction_history` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`timestamp` integer NOT NULL,
	`prediction` text NOT NULL,
	`actual` text,
	`confidence` real NOT NULL,
	`probability` real NOT NULL,
	`features` text,
	`correct` integer,
	`created_at` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `prediction_weights` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`name` text NOT NULL,
	`value` real NOT NULL,
	`updated_at` integer NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `prediction_weights_name_unique` ON `prediction_weights` (`name`);