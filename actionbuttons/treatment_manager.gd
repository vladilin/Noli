extends Node
class_name TreatmentManager

var treatments = [
	{
		"name": "ABC Resuscitate",
		"description": "Systematic initial assessment and stabilization of Airway, Breathing, and Circulation",
		"application": "Used to identify and manage life-threatening conditions in emergency presentations (e.g., shock, respiratory failure, cardiac emergencies)",
		"minutes": 5
	},
	{
		"name": "Analgesia (Morphine, Fentanyl, Demerol)",
		"description": "Opioid pain relief",
		"application": "Treat severe pain, reduce cardiac preload",
		"minutes": 2
	},
	{
		"name": "Antibiotics (IV broad-spectrum)",
		"description": "Antimicrobial therapy (e.g. pip-tazo, ceftriaxone)",
		"application": "Treat suspected or confirmed infection",
		"minutes": 3
	},
	{
		"name": "Antiemetics",
		"description": "Medications that prevent or relieve nausea and vomiting",
		"application": "For patients with nausea due to GI bleeding, COPD exacerbation, or cardiac-related symptoms",
		"minutes": 2
	},
	{
		"name": "Aspirin (ASA)",
		"description": "Antiplatelet agent",
		"application": "Initial treatment for suspected myocardial infarction",
		"minutes": 1
	},
	{
		"name": "Atropine",
		"description": "Anticholinergic agent",
		"application": "Treat bradycardia",
		"minutes": 1
	},
	{
		"name": "Beta Blockers (e.g. Metoprolol, Labetalol)",
		"description": "Reduce heart rate and blood pressure",
		"application": "ACS, hypertension, aortic dissection",
		"minutes": 2
	},
	{
		"name": "Fluids (IV bolus)",
		"description": "Intravenous fluid resuscitation",
		"application": "Treat hypotension and shock",
		"minutes": 3
	},
	{
		"name": "Heparin",
		"description": "Anticoagulant",
		"application": "Prevent clot propagation in ACS",
		"minutes": 2
	},
	{
		"name": "Magnesium Sulfate",
		"description": "Smooth muscle relaxant for severe airway obstruction",
		"application": "Adjunct treatment in asthma/COPD exacerbation",
		"minutes": 2
	},
	{
		"name": "Nebulised Beta-Agonists (Salbutamol, Atrovent)",
		"description": "Bronchodilator medications delivered via nebulizer",
		"application": "Relieve bronchospasm in obstructive airway disease",
		"minutes": 2
	},
	{
		"name": "NSAID nonsteroidal anti-inflammatory drug",
		"description": "ibuprofen Advil Nurofen Motrin",
		"application": "",
		"minutes": 1
	},
	{
		"name": "NTG (Nitroglycerin)",
		"description": "Vasodilator",
		"application": "Relieve chest pain, reduce BP",
		"minutes": 1
	},
	{
		"name": "Oxygen (Nasal Cannula/NRB/NIV/Intubation)",
		"description": "Via nasal prongs, masks, or ventilators",
		"application": "Treat hypoxia and respiratory distress",
		"minutes": 1
	},
	{
		"name": "Proton Pump Inhibitor (Pantoprazole IV)",
		"description": "Acid suppression therapy",
		"application": "Manage upper GI bleeding",
		"minutes": 2
	},
	{
		"name": "Steroids (IV Methylprednisolone, Prednisone)",
		"description": "Anti-inflammatory medications",
		"application": "Reduce airway inflammation and stabilize patients",
		"minutes": 2
	},
	{
		"name": "Terlipressin",
		"description": "Vasopressor for variceal bleeding",
		"application": "Control portal hypertension in GI bleeds",
		"minutes": 3
	},
	{
		"name": "Thrombolysis (e.g. TNK)",
		"description": "Clot-busting medication",
		"application": "Treat MI when PCI is unavailable",
		"minutes": 5
	}
]
## This signal can be emitted after you load from a CSV in the future,
## so your UI can refresh when treatments update.
signal treatments_loaded

## Optional: function to get a filtered list for search
func search_treatments(query: String) -> Array:
	var matches = []
	var q = query.to_lower()
	for i in treatments.size():
		var t = treatments[i]
		if q in t["name"].to_lower() or q in t["description"].to_lower():
			matches.append(t)
	return matches

## In the future, you'll have a function like this:
## func load_from_csv(csv_string: String):
##     # Parse the CSV and fill self.treatments, then emit treatments_loaded
##     treatments = ...
##     emit_signal("treatments_loaded")


func _on_line_edit_text_changed(new_text: String) -> void:
	var results = search_treatments(new_text)
