ClearAll["Pages`RemindersPage`*"];
ClearAll["Pages`RemindersPage`*`*"];

BeginPackage["Pages`RemindersPage`", {"Utilities`GenerateData`", "Utilities`General`"}];

DeployRemindersPage::usage = "";

Begin["`Private`"];

DeployRemindersPage[root_, opts: OptionsPattern[]] := CloudDeploy[
	Delayed[remindersForm[root]],
	FileNameJoin[{root, "Reminders"}],
	opts
];

reminderMealTypes = DeleteCases[$MealTypes, "Snack"];
modifiedHourInterpreterSpec = Prepend[HourInterpreterSpec, "None" -> None];

remindersForm[root_CloudObject] := Module[
	{reminders, notificationTypes},
	
	Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
	
	reminders = Replace[GetConfiguration[root, "Reminders"], Except[_Association] -> <||>];
	
	notificationTypes = {"Email"};
	If[MatchQ[$MobilePhone, _String],
		AppendTo[notificationTypes, "SMS"];
	];
	
	FormFunction[
		With[
			{metaData = Lookup[reminders, #, <||>]},
			# -> CompoundElement[
			{
				"Hour" -> <|
					"Label" -> "Reminder Time",
					(*"Help" -> "Current status: " <> Replace[Lookup[metaData, "Task", "Unknown"], t_TaskObject :> t["TaskStatus"]],*)
					"Interpreter" -> modifiedHourInterpreterSpec,
					"Control" -> PopupMenu,
					"Input" -> Lookup[metaData, "Hour", None]
				|>,
				
				"NotificationTypes" -> <|
					"Label" -> "Notification Types",
					"Interpreter" -> AnySubset[notificationTypes],
					"Control" -> (CheckboxBar[##, Appearance -> "Vertical"] &),
					"Input" -> Intersection[Lookup[metaData, "NotificationTypes", {"Email"}], notificationTypes]
				|>
			}
		]
		]& /@ reminderMealTypes,
		remindersAction[root],
		AppearanceRules -> <|
			"Title" -> "Reminders",
			"Description" -> Column[
				{
					Hyperlink["Return home", FileNameJoin[{root, "Home"}]],
					"Note: Reminder times are only approximate."
				}
			],
			"ItemLayout" -> "Vertical"
		|>
	]
];

remindersAction[root_][results_Association] := Module[
	{oldReminders, newReminders},
	
	Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
	
	(* Remove any old tasks *)
	oldReminders = Replace[GetConfiguration[root, "Reminders"], Except[_Association] -> <||>];
	TaskRemove /@ DeleteMissing[oldReminders[[All, "Task"]]];
	
	(* Determine new task information *)
	newReminders = Select[results, MatchQ[{#Hour, #NotificationTypes}, {_Integer, {__String}}]&];
	
	(* Create new tasks *)
	newReminders = Association @ KeyValueMap[
		Function[{mealType, metaData},
			Rule[
				mealType,
				Append[metaData,
					"Task" -> CloudSubmit @ ScheduledTask[
						With[
							{r = root},
							Get[FileNameJoin[{r, "Utilities", "General.wl"}]];
							Get[FileNameJoin[{r, "Pages", "RemindersPage.wl"}]];
							reminder[r, mealType][metaData["NotificationTypes"]]
						],
						hourToDateSpec[metaData["Hour"]]
					]
				]
			]
		],
		newReminders
	];
	
	(* Update config file *)
	SetConfiguration[root, "Reminders", newReminders];
	
	(* Redirect to the page again *)
	HTTPRedirect[FileNameJoin[{root, "Reminders"}]]
	
];

hourToDateSpec[h_Integer] := DateObject[{_, _, _, h}];

reminder[root_CloudObject, mealType_String][notificationTypes_List] := reminder[root, mealType] /@ notificationTypes;
reminder[root_CloudObject, mealType_String]["Email"] := With[
	{formattedMealType = FromCamelCase @ mealType},
	SendMail[
	<|
		"To" -> $WolframID,
		"Subject" -> "Meal Tracking: Reminder to log " <> formattedMealType,
		"HTMLBody" :> ExportString[
			Grid[
				List /@ {
					"Don't forget to log " <> formattedMealType <> "!",
					Hyperlink @ URLShorten @ Hyperlink@ First @ FileNameJoin[{root, "Home"}]
				}
			],
			"HTMLFragment"
		]
	|>
	]
];

reminder[root_CloudObject, mealType_String]["SMS"] := With[
	{formattedMealType = FromCamelCase @ mealType},
	SendMessage[
		"SMS",
		"Don't forget to log your meals!\n" <> URLShorten[First @ FileNameJoin[{root, "Home"}]]
	]
];


End[];
EndPackage[];