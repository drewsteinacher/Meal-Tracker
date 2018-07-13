ClearAll["MealTrackerApp`*"];
ClearAll["MealTrackerApp`*`*"];


BeginPackage["MealTrackerApp`",
	(Get[#]; #)& /@ {
		"Utilities`General`",
		"Utilities`GenerateData`",
		"Utilities`EntityStore`",
		"Utilities`Suggestion`",
		"Pages`HomePage`",
		"Pages`FoodEntryPage`",
		"Pages`MealEntryPage`",
		"Pages`ServingSizeEntryPage`",
		"Pages`NutritionEntryPage`",
		"Pages`ViewFoodPage`",
		"Pages`ViewMealPage`",
		"Pages`ChooseMealPage`",
		"Pages`ChooseFoodPage`",
		"Pages`ViewHistoryPage`",
		"Pages`RemoveLogEntryPage`",
		"Pages`RemoveEntityPage`",
		"Pages`FoodSearchPage`",
		"Pages`FoodLookupPage`",
		"Pages`ServingSizeMultiplicationPage`",
		"Pages`SettingsPage`",
		"Pages`RemindersPage`",
		"Pages`ScanBarcodePage`",
		"Pages`SuggestionPage`",
		"Plots`RadarPlot`",
		"Plots`NutritionRadarPlot`"
	}
];

DeployMealTrackerApp::usage = "DeployMealTrackerApp[_CloudObject] deploys the meal tracking application in the given CloudObject directory";

Begin["`Private`"];

DeployMealTrackerApp::invalidDirectory = "`` is an invalid directory";
DeployMealTrackerApp::noDatabin = "No history databin has been set. Specify a valid Databin with the \"HistoryDatabin\" option to continue.";
DeployMealTrackerApp::invalidConfiguration = "Failed to read the configuration file in ``";

Options[DeployMealTrackerApp] = {
	"DefaultDirectory" -> Automatic,
	"OverwriteExistingData" -> False,
	"HistoryDatabin" -> Automatic
};
DeployMealTrackerApp[root_CloudObject, OptionsPattern[]] := Module[
	{defaultDirectory, overwriteQ, configuration, historyDatabin, configurationHistoryDatabin},
	
	If[MatchQ[copyDefaultData[root, OptionValue["DefaultDirectory"], TrueQ @ OptionValue["OverwriteExistingData"]], $Failed],
		Return[$Failed];
	];
	
	(* TODO: Validate bin existence *)
	historyDatabin = OptionValue["HistoryDatabin"];
	
	(* Get config *)
	configuration = GetConfiguration[root];
	If[MatchQ[configuration, $Failed],
		Message[DeployMealTrackerApp::invalidConfiguration, root];
		Return[$Failed]
	];
	
	configurationHistoryDatabin = configuration["HistoryDatabin"];
	
	(* Check if valid bin OR Update is necessary *)
	If[Not[MatchQ[configurationHistoryDatabin, _Databin]] || And[configurationHistoryDatabin =!= historyDatabin, MatchQ[historyDatabin, _Databin]] ,
		(* Need a valid bin *)
		(* Check if update possible *)
		If[MatchQ[historyDatabin, _Databin] && configurationHistoryDatabin =!= historyDatabin,
			(* Update *)
			AssociateTo[configuration, "HistoryDatabin" -> historyDatabin];
			SetConfiguration[root, configuration];
			,
			(* Fail *)
			Message[DeployMealTrackerApp::noDatabin];
			Return[$Failed];
		];
	];
	
	deployPackages[root];
	
	deployPages[root]
];

copyDefaultData[root_, Automatic, rest___] := copyDefaultData[root, FileNameJoin[{Directory[], "Default"}], rest];
copyDefaultData[root_, defaultDirectory_String, overwriteQ_] :=
    If[overwriteQ || Not[FileExistsQ[root]],
	    If[FileExistsQ[root],
			DeleteDirectory[root, DeleteContents -> True];
	    ];
	    
	    (* Configuration *)
	    CopyFile[
		    FileNameJoin[{defaultDirectory, "Configuration.m"}],
		    FileNameJoin[{root, "Configuration.m"}]
	    ];
	    
	    updateEntityStore[root, defaultDirectory, "MyFood"];
	    updateEntityStore[root, defaultDirectory, "MyMeal"];
	    
	    True,
	    
	    False
	];
copyDefaultData[defaultDirectory_, ___] := (Message[DeployMealTrackerApp::invalidDirectory, defaultDirectory]; Return[$Failed]);


updateEntityStore[root_CloudObject, defaultDirectory_String, type_String] := Module[
	{latestLocalFile, latestCloudFile, store},
	
	latestLocalFile = Quiet @ Check[TakeLargestBy[FileNames["*.m",{FileNameJoin[{defaultDirectory, type}]}], FileDate, 1], $Failed];
	If[Length[latestLocalFile] == 0, Return[$Failed]];
	
	latestCloudFile = Quiet @ Check[TakeLargestBy[FileNames["*.WXF", {FileNameJoin[{root, type}]}], FileDate, 1], $Failed];
	
	If[Length[latestCloudFile] === 0 || FileDate[First @ latestLocalFile] > FileDate[First @ latestCloudFile],
		store = GenerateEntityStore[root, type];
		If[Not @ MatchQ[store, _EntityStore],
			$Failed,
			UpdateEntityStore[root, type, store]
		]
	]
];

deployPackages[root_] := With[{},
	CopyFile[#, FileNameJoin[{root, #}]]& /@ FileNames["*.wl"];
	Function[{directory},
		CopyFile[#, FileNameJoin[Flatten@{root, FileNameSplit[#]}]]& /@ FileNames[directory <> "/*.wl"];
	] /@ {"Pages", "Utilities", "Plots"};
];

deployPages[root_] := Module[
	{},
	#[root, Permissions -> "Public"]& /@ {
		DeployHomePage,
		DeployFoodEntryPage,
		DeployMealEntryPage,
		DeployServingSizeEntryPage,
		DeployNutritionEntryPage,
		DeployViewFoodPage,
		DeployViewMealPage,
		DeployChooseMealPage,
		DeployChooseFoodPage,
		DeployViewHistoryPage,
		DeployRemoveLogEntryPage,
		DeployFoodSearchPage,
		DeployFoodLookupPage,
		DeployRemoveEntityPage,
		DeployServingSizeMultiplicationPage,
		DeploySettingsPage,
		DeployRemindersPage,
		DeployScanBarcodePage,
		DeploySuggestionPage
	}
];

End[];

EndPackage[];