ClearAll["Pages`FoodLookupPage`*"];
ClearAll["Pages`FoodLookupPage`*`*"];

BeginPackage["Pages`FoodLookupPage`", {"Utilities`GenerateData`", "Utilities`General`"}];

DeployFoodLookupPage::usage = "";

Begin["`Private`"];

DeployFoodLookupPage[root_, opts: OptionsPattern[]] := CloudDeploy[
	foodLookupForm[root],
	FileNameJoin[{root, "FoodLookup"}],
	opts
];

foodLookupForm[root_CloudObject] := Module[
	{},
	FormPage[
		{
			"CodeType" -> <|
				"Interpreter" -> {"USDA Number" -> "USDANumber", "UPC" -> "UniversalProductCodes", "PLU" -> "PLUCodes"},
				"Control" -> SetterBar,
				"Label" -> "Code Type"
			|>,
			"Code" -> <|
				"Interpreter" -> "String",
				"Label" -> "Code"
			|>
		},
		foodLookupAction[root][#CodeType, #Code]&,
		AppearanceRules -> <|
			"Title" -> "Food Lookup by Code",
			"Description" -> Column[
				{
					"Choose a food code type and then enter the code to discover foods and add them for tracking by clicking on their names.",
					Hyperlink["Return home", FileNameJoin[{root, "Home"}]],
					Row[
						{
							"Look up a food with a",
							Spacer[1],
							NewTabHyperlink["USDA database number", "https://ndb.nal.usda.gov/ndb/search/list"],
							", a", Spacer[1],
							NewTabHyperlink["UPC", "https://en.wikipedia.org/wiki/Universal_Product_Code"],
							", or a", Spacer[1],
							NewTabHyperlink["PLU", "https://en.wikipedia.org/wiki/Price_look-up_code"],
							"."
						}
					],
					AddFoodHelpLinks[root, "FoodLookup"]
				}
			],
			"ItemLayout" -> "Vertical"
		|>
	]
];

foodLookupAction[root_][codeType_, code_] := Module[
	{digitCount, message},
	
	Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
	
	message = None;
	
	If[codeType === "UniversalProductCodes",
		digitCount = StringLength[code];
		Which[
			digitCount =!= 12,
			message = StringTemplate["You entered `` digits, but a valid UPC has 12 digits."][digitCount];,
			
			Not @ ValidGTINQ[code],
			message = "You have entered an invalid UPC. Please check for typos.";
		]
	];
	
	If[message === None,
		FoodServingSizeHyperlinkGrid[root][EntityClass["Food", {codeType -> code}], "ResubmitPage" -> "FoodLookup"],
		message
	]
];


End[];
EndPackage[];