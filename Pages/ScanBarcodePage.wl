ClearAll["Pages`ScanBarcodePage`*"];
ClearAll["Pages`ScanBarcodePage`*`*"];

BeginPackage["Pages`ScanBarcodePage`", {"Utilities`GenerateData`", "Utilities`General`"}];

DeployScanBarcodePage::usage = "";

Begin["`Private`"];

DeployScanBarcodePage[root_, opts: OptionsPattern[]] := CloudDeploy[
	scanBarcodeForm[root],
	FileNameJoin[{root, "ScanBarcode"}],
	opts
];

scanBarcodeForm[root_CloudObject] := Module[
	{},
	FormPage[
		{
			"Image" -> <|
				"Interpreter" -> "Image",
				"AutoSubmitting" -> True
			|>
		},
		scanBarcodeAction[root],
		AppearanceRules -> <|
			"Title" -> "Scan Barcode",
			"Description" -> Column[
				{
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
					AddFoodHelpLinks[root, "ScanBarcode"]
				}
			],
			"ItemLayout" -> "Vertical"
		|>
	]
];

scanBarcodeAction[root_][results_Association] := Module[
	{image, barcode},

	image = Thumbnail[results["Image"], UpTo[500]];
	barcode = BarcodeRecognize[image, "Data", "UPC"];
	
	Get[FileNameJoin[{root, "Utilities", "General.wl"}]];
	
	If[MatchQ[barcode, _String | _Integer],
		FoodServingSizeHyperlinkGrid[root][EntityClass["Food", {"UniversalProductCodes" -> barcode}], "ResubmitPage" -> "ScanBarcode"],
		"Unable to read the barcode. Please try again."
	]
];


End[];
EndPackage[];