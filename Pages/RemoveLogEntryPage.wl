ClearAll["Pages`RemoveLogEntryPage`*"];
ClearAll["Pages`RemoveLogEntryPage`*`*"];

BeginPackage["Pages`RemoveLogEntryPage`", {"Utilities`GenerateData`", "Utilities`General`", "Utilities`EntityStore`"}];

DeployRemoveLogEntryPage::usage = "";

Begin["`Private`"];

DeployRemoveLogEntryPage[root_, opts : OptionsPattern[]] := CloudDeploy[
	removeLogEntryAPI[root],
	FileNameJoin[{root, "RemoveLogEntry"}],
	opts
];

removeLogEntryAPI[root_CloudObject] := APIFunction[
	{
		"bin" -> "String",
		"uuid" -> "String"
	},
	With[
		{},
		DatabinRemove[#bin, #uuid];
		HTTPRedirect[FileNameJoin[{root, "ViewHistory"}]]
	]&
];

End[];
EndPackage[];