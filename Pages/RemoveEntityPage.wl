ClearAll["Pages`RemoveEntityPage`*"];
ClearAll["Pages`RemoveEntityPage`*`*"];

BeginPackage["Pages`RemoveEntityPage`", {"Utilities`GenerateData`", "Utilities`General`", "Utilities`EntityStore`"}];

DeployRemoveEntityPage::usage = "";

Begin["`Private`"];

DeployRemoveEntityPage[root_, opts : OptionsPattern[]] := CloudDeploy[
	removeEntityAPI[root],
	FileNameJoin[{root, "RemoveEntity"}],
	opts
];

removeEntityAPI[root_CloudObject] := APIFunction[
	{
		"type" -> {"MyFood", "MyMeal"},
		"entity" -> "String"
	},
	With[
		{},
		Get[FileNameJoin[{root, "Utilities", "EntityStore.wl"}]];
		LoadEntityStore[root, #type];
		Unset[Entity[#type, #entity]];
		UpdateEntityStore[root, #type];
		
		(* TODO: Move redirects outside of this package? *)
		HTTPRedirect[FileNameJoin[{root, "Home"}]]
	]&
];

End[];
EndPackage[];