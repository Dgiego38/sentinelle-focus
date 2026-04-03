// ConfigurationView.swift - Correctif syntaxe iOS 17

// ... (Garder le début identique jusqu'au familyActivityPicker)

.familyActivityPicker(isPresented: $showPicker, selection: $selection)
.onChange(of: selection) { oldValue, newValue in // Correction syntaxe iOS 17
    focusManager.saveSelection(newValue)
}
.padding(.bottom, 28)

// ... (Garder les sliders identiques)

// Dans onAppear, assure-toi d'utiliser focusManager
.onAppear {
    loadSettings()
    // On synchronise la sélection locale avec celle du manager
    selection = focusManager.activitySelection
}

// ... (Le reste est bon, voici juste la correction de saveSettings pour être sûr)

private func saveSettings() {
    let defaults = UserDefaults(suiteName: FocusManager.appGroupID)
    defaults?.set(Int(dailyGoalHours * 3600), forKey: FocusManager.goalKey)
    defaults?.set(Int(zenDuration), forKey: "zenDurationMinutes")
    defaults?.set(Int(ultraDuration), forKey: "ultraDurationMinutes")
    defaults?.set(autoShieldEnabled, forKey: "autoShieldEnabled")
    
    // Notification au système que les réglages ont changé
    defaults?.synchronize() 
}