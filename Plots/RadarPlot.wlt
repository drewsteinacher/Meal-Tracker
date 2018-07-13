BeginTestSection["RadarPlot"];

VerificationTest[
	Get["Plots/RadarPlot.wl"],
	Null,
	TestID -> "Get-Package"
];

VerificationTest[
	RadarPlot[<| "A" -> 10, "B" -> 40, "C" -> 90 |>],
	Rotate[_Graphics, _],
	SameTest -> MatchQ,
	TestID -> "Simple-Input-3"
];

VerificationTest[
	RadarPlot[<| "A" -> 10 |>],
	$Failed,
	{RadarPlot::notenough},
	TestID -> "Not-Enough-Data-1"
];

VerificationTest[
	RadarPlot[<| "A" -> 10, "B" -> 40 |>],
	$Failed,
	{RadarPlot::notenough},
	TestID -> "Not-Enough-Data-2"
];

VerificationTest[
	RadarPlot[<||>],
	$Failed,
	{RadarPlot::notenough},
	TestID -> "Not-Enough-Data-0"
];

VerificationTest[
	RadarPlot[1234],
	$Failed,
	{RadarPlot::invalid},
	TestID -> "Invalid-Syntax"
];

VerificationTest[
	RadarPlot[<| "A" -> 12, "B" -> 34, "C" -> "String" |>],
	$Failed,
	{RadarPlot::invalid},
	TestID -> "Invalid-Syntax-Association-Values"
];

EndTestSection[];
